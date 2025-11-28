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

# Install LAMP stack
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
yum install -y httpd mariadb php-mysqlnd

# Start Apache
systemctl start httpd
systemctl enable httpd

# Create simple test page first to pass health checks
echo "<html><body><h1>AutoMax Car Dealership</h1><p>Loading...</p></body></html>" > /var/www/html/index.html

# Create car dealership website with 20 cars and filters
cat > /var/www/html/index.php <<'PHPCODE'
<?php
// 20 Cars Inventory with Categories
$cars = [
    // Luxury Sedans
    ['make' => 'Mercedes-Benz', 'model' => 'S-Class', 'year' => 2024, 'price' => 114000, 'category' => 'Luxury', 'type' => 'Sedan', 'engine' => 'Twin-Turbo V8', 'horsepower' => 496, 'mpg' => 24, 'color' => 'Black', 'image' => 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=400', 'features' => 'Burmester Audio, Night Vision, Executive Rear Seats'],
    ['make' => 'BMW', 'model' => '7 Series', 'year' => 2024, 'price' => 95000, 'category' => 'Luxury', 'type' => 'Sedan', 'engine' => 'Twin-Turbo I6', 'horsepower' => 375, 'mpg' => 26, 'color' => 'White', 'image' => 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=400', 'features' => 'Gesture Control, Sky Lounge, Massage Seats'],
    ['make' => 'Audi', 'model' => 'A8 L', 'year' => 2024, 'price' => 87400, 'category' => 'Luxury', 'type' => 'Sedan', 'engine' => 'TFSI V6', 'horsepower' => 335, 'mpg' => 25, 'color' => 'Silver', 'image' => 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=400', 'features' => 'Quattro AWD, Matrix LED, Predictive Suspension'],
    ['make' => 'Lexus', 'model' => 'LS 500', 'year' => 2024, 'price' => 76900, 'category' => 'Luxury', 'type' => 'Sedan', 'engine' => 'Twin-Turbo V6', 'horsepower' => 416, 'mpg' => 23, 'color' => 'Blue', 'image' => 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=400', 'features' => 'Mark Levinson Audio, Kiriko Glass, Safety System+'],
    // Sports Cars
    ['make' => 'Porsche', 'model' => '911 Turbo S', 'year' => 2024, 'price' => 218000, 'category' => 'Sports', 'type' => 'Coupe', 'engine' => 'Twin-Turbo Flat-6', 'horsepower' => 640, 'mpg' => 18, 'color' => 'Red', 'image' => 'https://images.unsplash.com/photo-1614162692292-7ac56d7f373e?w=400', 'features' => 'Sport Chrono, PCCB Brakes, Launch Control'],
    ['make' => 'Ferrari', 'model' => 'Roma', 'year' => 2024, 'price' => 245000, 'category' => 'Sports', 'type' => 'Coupe', 'engine' => 'Twin-Turbo V8', 'horsepower' => 612, 'mpg' => 16, 'color' => 'Red', 'image' => 'https://images.unsplash.com/photo-1592198084033-aade902d1aae?w=400', 'features' => 'Manettino Dial, Ferrari Dynamic Enhancer, Carbon Seats'],
    ['make' => 'Lamborghini', 'model' => 'Huracan EVO', 'year' => 2024, 'price' => 268000, 'category' => 'Sports', 'type' => 'Coupe', 'engine' => 'V10', 'horsepower' => 631, 'mpg' => 14, 'color' => 'Yellow', 'image' => 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=400', 'features' => 'LDVI System, ALA 2.0, Forged Composites'],
    ['make' => 'McLaren', 'model' => '720S', 'year' => 2024, 'price' => 299000, 'category' => 'Sports', 'type' => 'Coupe', 'engine' => 'Twin-Turbo V8', 'horsepower' => 710, 'mpg' => 18, 'color' => 'Orange', 'image' => 'https://images.unsplash.com/photo-1621135802920-133df287f89c?w=400', 'features' => 'Proactive Chassis, Variable Drift Control, Folding Display'],
    // Electric Vehicles
    ['make' => 'Tesla', 'model' => 'Model S Plaid', 'year' => 2024, 'price' => 108990, 'category' => 'Electric', 'type' => 'Sedan', 'engine' => 'Tri Motor Electric', 'horsepower' => 1020, 'mpg' => 120, 'color' => 'White', 'image' => 'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=400', 'features' => 'Autopilot, 396mi Range, 0-60 in 1.99s'],
    ['make' => 'Porsche', 'model' => 'Taycan Turbo S', 'year' => 2024, 'price' => 187400, 'category' => 'Electric', 'type' => 'Sedan', 'engine' => 'Dual Motor Electric', 'horsepower' => 750, 'mpg' => 95, 'color' => 'Gray', 'image' => 'https://images.unsplash.com/photo-1619767886558-efdc259cde1a?w=400', 'features' => '800V Architecture, Launch Control, Matrix LED'],
    ['make' => 'Lucid', 'model' => 'Air Dream', 'year' => 2024, 'price' => 169000, 'category' => 'Electric', 'type' => 'Sedan', 'engine' => 'Dual Motor Electric', 'horsepower' => 1111, 'mpg' => 131, 'color' => 'Green', 'image' => 'https://images.unsplash.com/photo-1625231334168-21ede8182504?w=400', 'features' => '520mi Range, DreamDrive Pro, Glass Canopy'],
    ['make' => 'Rivian', 'model' => 'R1S', 'year' => 2024, 'price' => 84500, 'category' => 'Electric', 'type' => 'SUV', 'engine' => 'Quad Motor Electric', 'horsepower' => 835, 'mpg' => 95, 'color' => 'Blue', 'image' => 'https://images.unsplash.com/photo-1632245889029-e406faaa34cd?w=400', 'features' => 'Tank Turn, Camp Mode, Adventure Gear'],
    // SUVs
    ['make' => 'Range Rover', 'model' => 'Autobiography', 'year' => 2024, 'price' => 185000, 'category' => 'Luxury', 'type' => 'SUV', 'engine' => 'Twin-Turbo V8', 'horsepower' => 523, 'mpg' => 19, 'color' => 'Black', 'image' => 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=400', 'features' => 'Executive Class Seats, Meridian Signature, Pixel LED'],
    ['make' => 'Mercedes-Benz', 'model' => 'G63 AMG', 'year' => 2024, 'price' => 179000, 'category' => 'Luxury', 'type' => 'SUV', 'engine' => 'AMG V8 Biturbo', 'horsepower' => 577, 'mpg' => 15, 'color' => 'White', 'image' => 'https://images.unsplash.com/photo-1520031441872-265e4ff70366?w=400', 'features' => '3 Differential Locks, AMG Performance, Off-Road Package'],
    ['make' => 'BMW', 'model' => 'X7 M60i', 'year' => 2024, 'price' => 112000, 'category' => 'Luxury', 'type' => 'SUV', 'engine' => 'Twin-Turbo V8', 'horsepower' => 523, 'mpg' => 20, 'color' => 'Gray', 'image' => 'https://images.unsplash.com/photo-1556189250-72ba954cfc2b?w=400', 'features' => 'Sky Lounge, Bowers Wilkins, Executive Lounge'],
    ['make' => 'Cadillac', 'model' => 'Escalade V', 'year' => 2024, 'price' => 152000, 'category' => 'Luxury', 'type' => 'SUV', 'engine' => 'Supercharged V8', 'horsepower' => 682, 'mpg' => 14, 'color' => 'Black', 'image' => 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=400', 'features' => 'AKG Studio, Super Cruise, 38" OLED Display'],
    // Performance
    ['make' => 'Aston Martin', 'model' => 'DB12', 'year' => 2024, 'price' => 245000, 'category' => 'Sports', 'type' => 'Coupe', 'engine' => 'Twin-Turbo V8', 'horsepower' => 671, 'mpg' => 20, 'color' => 'Silver', 'image' => 'https://images.unsplash.com/photo-1596994836684-d9ea87408f7e?w=400', 'features' => 'Bowers Wilkins, Sport Plus Mode, Carbon Ceramic'],
    ['make' => 'Bentley', 'model' => 'Continental GT', 'year' => 2024, 'price' => 235000, 'category' => 'Luxury', 'type' => 'Coupe', 'engine' => 'Twin-Turbo W12', 'horsepower' => 650, 'mpg' => 17, 'color' => 'Green', 'image' => 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=400', 'features' => 'Naim Audio, Rotating Display, Diamond Knurling'],
    ['make' => 'Maserati', 'model' => 'MC20', 'year' => 2024, 'price' => 215000, 'category' => 'Sports', 'type' => 'Coupe', 'engine' => 'Twin-Turbo V6 Nettuno', 'horsepower' => 621, 'mpg' => 18, 'color' => 'Blue', 'image' => 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=400', 'features' => 'F1 Technology, Butterfly Doors, Carbon Monocoque'],
    ['make' => 'Rolls-Royce', 'model' => 'Ghost', 'year' => 2024, 'price' => 340000, 'category' => 'Luxury', 'type' => 'Sedan', 'engine' => 'Twin-Turbo V12', 'horsepower' => 563, 'mpg' => 14, 'color' => 'Black', 'image' => 'https://images.unsplash.com/photo-1631295868223-63265b40d9e4?w=400', 'features' => 'Starlight Headliner, Planar Suspension, Bespoke Audio']
];

// Get filter values
$filterMake = $_GET['make'] ?? '';
$filterType = $_GET['type'] ?? '';
$filterCategory = $_GET['category'] ?? '';
$filterMinPrice = $_GET['min_price'] ?? '';
$filterMaxPrice = $_GET['max_price'] ?? '';
$sortBy = $_GET['sort'] ?? 'price_desc';

// Get unique values for filters
$makes = array_unique(array_column($cars, 'make'));
$types = array_unique(array_column($cars, 'type'));
$categories = array_unique(array_column($cars, 'category'));
sort($makes);
sort($types);
sort($categories);

// Apply filters
$filteredCars = array_filter($cars, function($car) use ($filterMake, $filterType, $filterCategory, $filterMinPrice, $filterMaxPrice) {
    if ($filterMake && $car['make'] !== $filterMake) return false;
    if ($filterType && $car['type'] !== $filterType) return false;
    if ($filterCategory && $car['category'] !== $filterCategory) return false;
    if ($filterMinPrice && $car['price'] < (int)$filterMinPrice) return false;
    if ($filterMaxPrice && $car['price'] > (int)$filterMaxPrice) return false;
    return true;
});

// Apply sorting
usort($filteredCars, function($a, $b) use ($sortBy) {
    switch($sortBy) {
        case 'price_asc': return $a['price'] - $b['price'];
        case 'price_desc': return $b['price'] - $a['price'];
        case 'hp_desc': return $b['horsepower'] - $a['horsepower'];
        case 'name_asc': return strcmp($a['make'], $b['make']);
        default: return $b['price'] - $a['price'];
    }
});

$instance_id = @file_get_contents('http://169.254.169.254/latest/meta-data/instance-id') ?: 'N/A';
$az = @file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone') ?: 'N/A';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AutoMax Premier - Luxury Car Dealership</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', system-ui, sans-serif; background: linear-gradient(135deg, #0f0c29, #302b63, #24243e); color: #fff; min-height: 100vh; }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        header { background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); padding: 20px 40px; border-radius: 15px; margin-bottom: 30px; display: flex; justify-content: space-between; align-items: center; }
        .logo { font-size: 2em; font-weight: bold; background: linear-gradient(45deg, #f093fb, #f5576c); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        .nav { display: flex; gap: 25px; }
        .nav a { color: #fff; text-decoration: none; padding: 10px 20px; border-radius: 25px; transition: all 0.3s; }
        .nav a:hover { background: rgba(255,255,255,0.2); }
        .hero { text-align: center; padding: 40px; margin-bottom: 30px; }
        .hero h1 { font-size: 3em; margin-bottom: 10px; background: linear-gradient(45deg, #f093fb, #f5576c, #ffd700); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        .hero p { font-size: 1.3em; color: #aaa; }
        .filters { background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); padding: 25px; border-radius: 15px; margin-bottom: 30px; }
        .filters h3 { margin-bottom: 15px; color: #f5576c; }
        .filter-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; }
        .filter-group { display: flex; flex-direction: column; gap: 5px; }
        .filter-group label { font-size: 0.9em; color: #aaa; }
        .filter-group select, .filter-group input { padding: 10px; border-radius: 8px; border: 1px solid rgba(255,255,255,0.2); background: rgba(255,255,255,0.1); color: #fff; }
        .filter-group select option { background: #302b63; color: #fff; }
        .filter-btn { background: linear-gradient(45deg, #f093fb, #f5576c); color: #fff; border: none; padding: 12px 30px; border-radius: 25px; cursor: pointer; font-weight: bold; transition: transform 0.3s; }
        .filter-btn:hover { transform: scale(1.05); }
        .results-info { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding: 15px; background: rgba(255,255,255,0.05); border-radius: 10px; }
        .cars-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 25px; }
        .car-card { background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); border-radius: 20px; overflow: hidden; transition: all 0.3s; border: 1px solid rgba(255,255,255,0.1); }
        .car-card:hover { transform: translateY(-10px); box-shadow: 0 20px 40px rgba(0,0,0,0.3); border-color: #f5576c; }
        .car-image { height: 200px; background-size: cover; background-position: center; position: relative; }
        .car-image img { width: 100%; height: 100%; object-fit: cover; }
        .car-badge { position: absolute; top: 15px; right: 15px; background: linear-gradient(45deg, #f093fb, #f5576c); padding: 5px 15px; border-radius: 20px; font-size: 0.8em; font-weight: bold; }
        .car-info { padding: 20px; }
        .car-info h3 { font-size: 1.3em; margin-bottom: 8px; }
        .car-specs { display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; margin: 15px 0; font-size: 0.9em; color: #aaa; }
        .car-specs span { display: flex; align-items: center; gap: 5px; }
        .car-price { font-size: 1.5em; font-weight: bold; color: #f5576c; }
        .car-features { font-size: 0.85em; color: #888; margin-top: 10px; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.1); }
        .view-btn { display: block; width: 100%; padding: 12px; background: linear-gradient(45deg, #f093fb, #f5576c); border: none; border-radius: 10px; color: #fff; font-weight: bold; cursor: pointer; margin-top: 15px; transition: opacity 0.3s; }
        .view-btn:hover { opacity: 0.9; }
        .footer { margin-top: 40px; padding: 30px; background: rgba(255,255,255,0.05); border-radius: 15px; text-align: center; }
        .footer-info { display: flex; justify-content: center; gap: 40px; flex-wrap: wrap; margin-top: 15px; font-size: 0.9em; color: #888; }
        .footer-info span { display: flex; align-items: center; gap: 8px; }
        .status-ok { color: #4ade80; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="logo">🚗 AutoMax Premier</div>
            <nav class="nav">
                <a href="#inventory">Inventory</a>
                <a href="#financing">Financing</a>
                <a href="#service">Service</a>
                <a href="#contact">Contact</a>
            </nav>
        </header>

        <section class="hero">
            <h1>Luxury & Performance Vehicles</h1>
            <p>Discover our collection of <?php echo count($cars); ?> premium automobiles</p>
        </section>

        <section class="filters">
            <h3>🔍 Filter Vehicles</h3>
            <form method="GET" action="">
                <div class="filter-grid">
                    <div class="filter-group">
                        <label>Make</label>
                        <select name="make">
                            <option value="">All Makes</option>
                            <?php foreach($makes as $make): ?>
                            <option value="<?php echo $make; ?>" <?php echo $filterMake === $make ? 'selected' : ''; ?>><?php echo $make; ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label>Category</label>
                        <select name="category">
                            <option value="">All Categories</option>
                            <?php foreach($categories as $cat): ?>
                            <option value="<?php echo $cat; ?>" <?php echo $filterCategory === $cat ? 'selected' : ''; ?>><?php echo $cat; ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label>Type</label>
                        <select name="type">
                            <option value="">All Types</option>
                            <?php foreach($types as $type): ?>
                            <option value="<?php echo $type; ?>" <?php echo $filterType === $type ? 'selected' : ''; ?>><?php echo $type; ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label>Min Price ($)</label>
                        <input type="number" name="min_price" placeholder="0" value="<?php echo $filterMinPrice; ?>">
                    </div>
                    <div class="filter-group">
                        <label>Max Price ($)</label>
                        <input type="number" name="max_price" placeholder="500000" value="<?php echo $filterMaxPrice; ?>">
                    </div>
                    <div class="filter-group">
                        <label>Sort By</label>
                        <select name="sort">
                            <option value="price_desc" <?php echo $sortBy === 'price_desc' ? 'selected' : ''; ?>>Price: High to Low</option>
                            <option value="price_asc" <?php echo $sortBy === 'price_asc' ? 'selected' : ''; ?>>Price: Low to High</option>
                            <option value="hp_desc" <?php echo $sortBy === 'hp_desc' ? 'selected' : ''; ?>>Horsepower: High to Low</option>
                            <option value="name_asc" <?php echo $sortBy === 'name_asc' ? 'selected' : ''; ?>>Name: A to Z</option>
                        </select>
                    </div>
                    <div class="filter-group" style="justify-content: flex-end;">
                        <button type="submit" class="filter-btn">Apply Filters</button>
                    </div>
                </div>
            </form>
        </section>

        <div class="results-info">
            <span>Showing <?php echo count($filteredCars); ?> of <?php echo count($cars); ?> vehicles</span>
            <a href="?" style="color: #f5576c; text-decoration: none;">Clear Filters</a>
        </div>

        <section id="inventory" class="cars-grid">
            <?php foreach ($filteredCars as $car): ?>
            <div class="car-card">
                <div class="car-image">
                    <img src="<?php echo $car['image']; ?>" alt="<?php echo $car['make'] . ' ' . $car['model']; ?>" onerror="this.parentElement.innerHTML='<div style=\'height:100%;display:flex;align-items:center;justify-content:center;font-size:4em;background:linear-gradient(45deg,#f093fb,#f5576c)\'>🚗</div>'">
                    <span class="car-badge"><?php echo $car['category']; ?></span>
                </div>
                <div class="car-info">
                    <h3><?php echo $car['year'] . ' ' . $car['make'] . ' ' . $car['model']; ?></h3>
                    <div class="car-specs">
                        <span>⚡ <?php echo $car['horsepower']; ?> HP</span>
                        <span>⛽ <?php echo $car['mpg']; ?> MPG</span>
                        <span>🔧 <?php echo $car['engine']; ?></span>
                        <span>🎨 <?php echo $car['color']; ?></span>
                    </div>
                    <div class="car-price">$<?php echo number_format($car['price']); ?></div>
                    <div class="car-features">✨ <?php echo $car['features']; ?></div>
                    <button class="view-btn">View Details</button>
                </div>
            </div>
            <?php endforeach; ?>
        </section>

        <footer class="footer">
            <h3>🔧 Infrastructure Status</h3>
            <div class="footer-info">
                <span class="status-ok">✅ Web Server: Apache</span>
                <span class="status-ok">✅ Instance: <?php echo $instance_id; ?></span>
                <span class="status-ok">✅ Zone: <?php echo $az; ?></span>
                <span class="status-ok">✅ Load Balancer: Active</span>
                <span class="status-ok">✅ Cars in DB: <?php echo count($cars); ?></span>
            </div>
        </footer>
    </div>
</body>
</html>
PHPCODE

# Set permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

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
