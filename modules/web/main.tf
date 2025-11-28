data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "elb_sg" {
  name        = "${var.project_name}-elb-sg"
  description = "Allow public HTTP/HTTPS to Classic Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Allow HTTP from ELB to instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    security_groups          = [aws_security_group.elb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Classic Load Balancer (ELB)
resource "aws_elb" "web_elb" {
  name            = "${var.project_name}-elb"
  subnets         = var.public_subnets
  security_groups = [aws_security_group.elb_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "${var.project_name}-elb"
  }
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  iam_instance_profile { name = var.iam_instance_profile }
  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -e
    
    # Install LAMP stack (skip yum update for faster boot)
    amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
    yum install -y httpd mariadb php-mysqlnd
    
    # Start Apache with retry logic
    systemctl start httpd
    systemctl enable httpd
    sleep 5
    systemctl restart httpd
    
    # Create car dealership website
    cat > /var/www/html/index.php <<'PHP'
<?php
// Database connection variables - will be populated by Terraform
$db_host = '${var.db_endpoint}';
$db_name = 'lifesci';
$db_user = 'dbadmin';
$db_pass = '${var.db_password}';

// Try to connect to database and initialize tables
$conn = null;
$cars = [];
try {
    $conn = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Create cars table if it doesn't exist
    $createTable = "
    CREATE TABLE IF NOT EXISTS cars (
        id INT AUTO_INCREMENT PRIMARY KEY,
        make VARCHAR(50) NOT NULL,
        model VARCHAR(50) NOT NULL,
        year INT NOT NULL,
        price DECIMAL(10,2) NOT NULL,
        engine VARCHAR(100),
        horsepower INT,
        features TEXT,
        emoji VARCHAR(10),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
    $conn->exec($createTable);
    
    // Insert sample cars if table is empty
    $count = $conn->query("SELECT COUNT(*) FROM cars")->fetchColumn();
    if ($count == 0) {
        $sampleCars = [
            ['Tesla', 'Model S', 2024, 94990, 'Electric Motor', 1020, 'Full Self-Driving, 405 miles range', '🏎️'],
            ['BMW', 'X5 M', 2024, 108900, 'Twin-Turbo V8', 617, 'All-Wheel Drive, Sport Package', '🚙'],
            ['Audi', 'A8 L', 2024, 87400, 'TFSI V6', 335, 'Quattro AWD, Advanced Driver Assistance', '🚗'],
            ['Porsche', '911 Turbo', 2024, 128700, 'Twin-Turbo Flat-6', 473, 'Sport Chrono Package, PDK', '🏁'],
            ['Mercedes', 'G63 AMG', 2024, 139900, 'AMG V8 Biturbo', 577, '3 Differential Locks, Off-Road Package', '🚐'],
            ['Lexus', 'LS 500', 2024, 76900, 'V6 Twin-Turbo', 416, 'Ultra-Luxury Interior, Safety System+ 2.5', '🎯']
        ];
        
        $stmt = $conn->prepare("INSERT INTO cars (make, model, year, price, engine, horsepower, features, emoji) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        foreach ($sampleCars as $car) {
            $stmt->execute($car);
        }
    }
    
    // Fetch cars from database
    $stmt = $conn->query("SELECT * FROM cars ORDER BY price DESC");
    $cars = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $db_status = "Connected - " . count($cars) . " cars in inventory";
    
} catch(PDOException $e) {
    $db_status = "Connection failed: " . $e->getMessage();
    // Fallback cars if DB connection fails
    $cars = [
        ['make' => 'Tesla', 'model' => 'Model S', 'year' => 2024, 'price' => 94990, 'engine' => 'Electric Motor', 'horsepower' => 1020, 'features' => 'Full Self-Driving, 405 miles range', 'emoji' => '🏎️'],
        ['make' => 'BMW', 'model' => 'X5 M', 'year' => 2024, 'price' => 108900, 'engine' => 'Twin-Turbo V8', 'horsepower' => 617, 'features' => 'All-Wheel Drive, Sport Package', 'emoji' => '🚙']
    ];
}

// Get instance metadata
$instance_id = @file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
$az = @file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone');
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AutoMax - Premier Car Dealership</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            line-height: 1.6; 
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: #333;
            min-height: 100vh;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        header { 
            background: rgba(255,255,255,0.95); 
            backdrop-filter: blur(10px);
            padding: 20px 0; 
            margin-bottom: 30px; 
            border-radius: 15px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        .header-content { 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
            padding: 0 30px;
        }
        .logo { 
            font-size: 2.5em; 
            font-weight: bold; 
            background: linear-gradient(45deg, #ff6b6b, #4ecdc4);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .nav { display: flex; gap: 30px; }
        .nav a { 
            text-decoration: none; 
            color: #333; 
            font-weight: 600;
            padding: 10px 20px;
            border-radius: 25px;
            transition: all 0.3s ease;
        }
        .nav a:hover { 
            background: #4ecdc4; 
            color: white;
            transform: translateY(-2px);
        }
        .hero { 
            background: rgba(255,255,255,0.95);
            padding: 50px; 
            text-align: center; 
            margin-bottom: 40px;
            border-radius: 20px;
            box-shadow: 0 12px 40px rgba(0,0,0,0.15);
        }
        .hero h1 { 
            font-size: 3em; 
            margin-bottom: 20px;
            background: linear-gradient(45deg, #ff6b6b, #4ecdc4);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .hero p { font-size: 1.3em; color: #666; margin-bottom: 30px; }
        .cta-button { 
            display: inline-block; 
            padding: 15px 40px; 
            background: linear-gradient(45deg, #ff6b6b, #4ecdc4);
            color: white; 
            text-decoration: none; 
            border-radius: 50px;
            font-weight: bold;
            font-size: 1.1em;
            transition: all 0.3s ease;
            box-shadow: 0 8px 25px rgba(0,0,0,0.2);
        }
        .cta-button:hover { 
            transform: translateY(-3px);
            box-shadow: 0 12px 35px rgba(0,0,0,0.3);
        }
        .cars-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); 
            gap: 30px; 
            margin-bottom: 40px;
        }
        .car-card { 
            background: rgba(255,255,255,0.95);
            border-radius: 20px; 
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
        }
        .car-card:hover { 
            transform: translateY(-10px);
            box-shadow: 0 20px 50px rgba(0,0,0,0.2);
        }
        .car-image { 
            height: 220px; 
            background: linear-gradient(45deg, #ff9a9e, #fecfef);
            display: flex; 
            align-items: center; 
            justify-content: center;
            font-size: 4em;
            color: rgba(255,255,255,0.8);
        }
        .car-info { padding: 25px; }
        .car-info h3 { 
            font-size: 1.5em; 
            margin-bottom: 10px;
            color: #333;
        }
        .car-info p { 
            color: #666; 
            margin-bottom: 8px;
            font-size: 1.1em;
        }
        .price { 
            font-size: 1.4em; 
            font-weight: bold; 
            color: #4ecdc4; 
            margin-top: 15px;
        }
        .system-info { 
            background: rgba(255,255,255,0.95);
            padding: 25px; 
            border-radius: 15px;
            margin-top: 30px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.1);
        }
        .system-info h3 { 
            color: #333; 
            margin-bottom: 15px;
            font-size: 1.3em;
        }
        .info-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 15px;
        }
        .info-item { 
            background: #f8f9fa; 
            padding: 15px; 
            border-radius: 10px;
            border-left: 4px solid #4ecdc4;
        }
        .status-connected { color: #28a745; font-weight: bold; }
        .status-error { color: #dc3545; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="header-content">
                <div class="logo">🚗 AutoMax</div>
                <nav class="nav">
                    <a href="#inventory">Inventory</a>
                    <a href="#financing">Financing</a>
                    <a href="#service">Service</a>
                    <a href="#about">About</a>
                    <a href="#contact">Contact</a>
                </nav>
            </div>
        </header>

        <section class="hero">
            <h1>Find Your Dream Car Today</h1>
            <p>Premium vehicles, unbeatable prices, and exceptional service</p>
            <a href="#inventory" class="cta-button">Browse Our Inventory</a>
        </section>

        <section id="inventory" class="cars-grid">
            <?php foreach ($cars as $car): ?>
            <div class="car-card">
                <div class="car-image"><?php echo htmlspecialchars($car['emoji'] ?? '🚗'); ?></div>
                <div class="car-info">
                    <h3><?php echo htmlspecialchars($car['year']) . ' ' . htmlspecialchars($car['make']) . ' ' . htmlspecialchars($car['model']); ?></h3>
                    <p>⚡ <?php echo htmlspecialchars($car['engine'] ?? 'Engine'); ?> • 🎯 <?php echo htmlspecialchars($car['horsepower'] ?? 'N/A'); ?> HP</p>
                    <p>🛡️ <?php echo htmlspecialchars($car['features'] ?? 'Premium Features'); ?></p>
                    <div class="price">$<?php echo number_format($car['price'], 0); ?></div>
                </div>
            </div>
            <?php endforeach; ?>
            
            <?php if (empty($cars)): ?>
            <div class="car-card">
                <div class="car-image">🔧</div>
                <div class="car-info">
                    <h3>Loading Inventory...</h3>
                    <p>Please check back soon for our latest vehicles</p>
                    <div class="price">Database Initializing</div>
                </div>
            </div>
            <?php endif; ?>
        </section>

        <div class="system-info">
            <h3>🔧 System Infrastructure Status</h3>
            <div class="info-grid">
                <div class="info-item">
                    <strong>Database Status:</strong><br>
                    <span class="<?php echo strpos($db_status, 'Connected') !== false ? 'status-connected' : 'status-error'; ?>">
                        <?php echo htmlspecialchars($db_status); ?>
                    </span>
                </div>
                <div class="info-item">
                    <strong>Web Server:</strong><br>
                    <span class="status-connected">Apache HTTP Server</span>
                </div>
                <div class="info-item">
                    <strong>Instance ID:</strong><br>
                    <?php echo htmlspecialchars($instance_id ?: 'N/A'); ?>
                </div>
                <div class="info-item">
                    <strong>Availability Zone:</strong><br>
                    <?php echo htmlspecialchars($az ?: 'N/A'); ?>
                </div>
                <div class="info-item">
                    <strong>Load Balancer:</strong><br>
                    <span class="status-connected">AWS Application Load Balancer</span>
                </div>
                <div class="info-item">
                    <strong>Auto Scaling:</strong><br>
                    <span class="status-connected">Active (1 instance)</span>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
PHP
    
    # Set proper permissions
    chown -R apache:apache /var/www/html
    chmod -R 755 /var/www/html
    
    # Configure PHP
    echo "date.timezone = UTC" >> /etc/php.ini
    
    # Restart Apache
    systemctl restart httpd
EOT
  )
  network_interfaces {
    device_index                = 0
    security_groups             = [aws_security_group.instance_sg.id]
    associate_public_ip_address = true
  }
  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.project_name}-web" }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                      = "${var.project_name}-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.min_size
  vpc_zone_identifier       = var.public_subnets
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }
  load_balancers            = [aws_elb.web_elb.name]
  health_check_type         = "ELB"
  health_check_grace_period = 600  # 10 minutes for user data to complete (yum update + LAMP install)
  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }
}

output "elb_dns" { value = aws_elb.web_elb.dns_name }
output "web_sg_id" { value = aws_security_group.instance_sg.id }
output "elb_sg_id" { value = aws_security_group.elb_sg.id }
