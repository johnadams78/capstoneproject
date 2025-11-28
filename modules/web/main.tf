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
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
yum install -y httpd mariadb php-mysqlnd
systemctl start httpd
systemctl enable httpd
echo "<html><body><h1>Capstone Project</h1><p>Loading...</p></body></html>" > /var/www/html/index.html

cat > /var/www/html/index.php <<'PHP'
<?php
$cars=[['Mercedes-Benz','S-Class',2024,114000,'Luxury','Sedan','V8',496,'Black'],['BMW','7 Series',2024,95000,'Luxury','Sedan','I6',375,'White'],['Audi','A8 L',2024,87400,'Luxury','Sedan','V6',335,'Silver'],['Lexus','LS 500',2024,76900,'Luxury','Sedan','V6',416,'Blue'],['Porsche','911 Turbo S',2024,218000,'Sports','Coupe','Flat-6',640,'Red'],['Ferrari','Roma',2024,245000,'Sports','Coupe','V8',612,'Red'],['Lamborghini','Huracan',2024,268000,'Sports','Coupe','V10',631,'Yellow'],['McLaren','720S',2024,299000,'Sports','Coupe','V8',710,'Orange'],['Tesla','Model S Plaid',2024,108990,'Electric','Sedan','Tri-Motor',1020,'White'],['Porsche','Taycan Turbo',2024,187400,'Electric','Sedan','Dual-Motor',750,'Gray'],['Lucid','Air Dream',2024,169000,'Electric','Sedan','Dual-Motor',1111,'Green'],['Rivian','R1S',2024,84500,'Electric','SUV','Quad-Motor',835,'Blue'],['Range Rover','Autobiography',2024,185000,'Luxury','SUV','V8',523,'Black'],['Mercedes-Benz','G63 AMG',2024,179000,'Luxury','SUV','V8',577,'White'],['BMW','X7 M60i',2024,112000,'Luxury','SUV','V8',523,'Gray'],['Cadillac','Escalade V',2024,152000,'Luxury','SUV','V8',682,'Black'],['Aston Martin','DB12',2024,245000,'Sports','Coupe','V8',671,'Silver'],['Bentley','Continental GT',2024,235000,'Luxury','Coupe','W12',650,'Green'],['Maserati','MC20',2024,215000,'Sports','Coupe','V6',621,'Blue'],['Rolls-Royce','Ghost',2024,340000,'Luxury','Sedan','V12',563,'Black']];
$makes=array_unique(array_column($cars,0));$types=array_unique(array_column($cars,5));$cats=array_unique(array_column($cars,4));sort($makes);sort($types);sort($cats);
$fm=$_GET['make']??'';$ft=$_GET['type']??'';$fc=$_GET['category']??'';$pmin=(int)($_GET['min_price']??0);$pmax=(int)($_GET['max_price']??999999);$sort=$_GET['sort']??'price_desc';
$filtered=array_filter($cars,fn($c)=>(!$fm||$c[0]==$fm)&&(!$ft||$c[5]==$ft)&&(!$fc||$c[4]==$fc)&&$c[3]>=$pmin&&$c[3]<=$pmax);
usort($filtered,fn($a,$b)=>match($sort){'price_asc'=>$a[3]-$b[3],'hp_desc'=>$b[7]-$a[7],'name_asc'=>strcmp($a[0],$b[0]),default=>$b[3]-$a[3]});
$id=@file_get_contents('http://169.254.169.254/latest/meta-data/instance-id')?:'N/A';$az=@file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone')?:'N/A';
?><!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Capstone Project - Car Dealership</title>
<style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:system-ui;background:linear-gradient(135deg,#0f0c29,#302b63,#24243e);color:#fff;min-height:100vh}.c{max-width:1400px;margin:0 auto;padding:20px}header{background:rgba(255,255,255,.1);backdrop-filter:blur(10px);padding:20px 40px;border-radius:15px;margin-bottom:30px}.logo{font-size:2em;font-weight:bold;background:linear-gradient(45deg,#f093fb,#f5576c);-webkit-background-clip:text;-webkit-text-fill-color:transparent}.hero{text-align:center;padding:40px;margin-bottom:30px}.hero h1{font-size:2.5em;background:linear-gradient(45deg,#f093fb,#f5576c,#ffd700);-webkit-background-clip:text;-webkit-text-fill-color:transparent}.hero p{color:#aaa;margin-top:10px}.filters{background:rgba(255,255,255,.1);padding:25px;border-radius:15px;margin-bottom:30px}.filters h3{margin-bottom:15px;color:#f5576c}.fg{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:15px}.fg select,.fg input{padding:10px;border-radius:8px;border:1px solid rgba(255,255,255,.2);background:rgba(255,255,255,.1);color:#fff}.fg select option{background:#302b63}.btn{background:linear-gradient(45deg,#f093fb,#f5576c);color:#fff;border:none;padding:12px 25px;border-radius:25px;cursor:pointer;font-weight:bold}.cars{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:25px}.card{background:rgba(255,255,255,.1);border-radius:20px;overflow:hidden;transition:.3s;border:1px solid rgba(255,255,255,.1)}.card:hover{transform:translateY(-10px);box-shadow:0 20px 40px rgba(0,0,0,.3);border-color:#f5576c}.img{height:180px;background:linear-gradient(45deg,#f093fb,#f5576c);display:flex;align-items:center;justify-content:center;font-size:4em;position:relative}.badge{position:absolute;top:15px;right:15px;background:linear-gradient(45deg,#f093fb,#f5576c);padding:5px 15px;border-radius:20px;font-size:.8em}.info{padding:20px}.info h3{font-size:1.2em;margin-bottom:8px}.specs{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:15px 0;font-size:.9em;color:#aaa}.price{font-size:1.5em;font-weight:bold;color:#f5576c}.view{display:block;width:100%;padding:12px;background:linear-gradient(45deg,#f093fb,#f5576c);border:none;border-radius:10px;color:#fff;font-weight:bold;cursor:pointer;margin-top:15px}.footer{margin-top:40px;padding:30px;background:rgba(255,255,255,.05);border-radius:15px;text-align:center}.fi{display:flex;justify-content:center;gap:30px;flex-wrap:wrap;margin-top:15px;font-size:.9em;color:#888}.ok{color:#4ade80}.ri{display:flex;justify-content:space-between;margin-bottom:20px;padding:15px;background:rgba(255,255,255,.05);border-radius:10px}</style></head>
<body><div class="c"><header><div class="logo">🚗 Capstone Project</div></header>
<div class="hero"><h1>Luxury & Performance Vehicles</h1><p>Discover <?=count($cars)?> premium automobiles</p></div>
<div class="filters"><h3>🔍 Filter Vehicles</h3><form method="GET"><div class="fg">
<select name="make"><option value="">All Makes</option><?php foreach($makes as $m):?><option value="<?=$m?>"<?=$fm==$m?' selected':''?>><?=$m?></option><?php endforeach;?></select>
<select name="category"><option value="">All Categories</option><?php foreach($cats as $c):?><option value="<?=$c?>"<?=$fc==$c?' selected':''?>><?=$c?></option><?php endforeach;?></select>
<select name="type"><option value="">All Types</option><?php foreach($types as $t):?><option value="<?=$t?>"<?=$ft==$t?' selected':''?>><?=$t?></option><?php endforeach;?></select>
<input type="number" name="min_price" placeholder="Min $" value="<?=$pmin?$pmin:''?>">
<input type="number" name="max_price" placeholder="Max $" value="<?=$pmax<999999?$pmax:''?>">
<select name="sort"><option value="price_desc"<?=$sort=='price_desc'?' selected':''?>>Price ↓</option><option value="price_asc"<?=$sort=='price_asc'?' selected':''?>>Price ↑</option><option value="hp_desc"<?=$sort=='hp_desc'?' selected':''?>>HP ↓</option><option value="name_asc"<?=$sort=='name_asc'?' selected':''?>>Name A-Z</option></select>
<button type="submit" class="btn">Apply</button></div></form></div>
<div class="ri"><span>Showing <?=count($filtered)?> of <?=count($cars)?></span><a href="?" style="color:#f5576c;text-decoration:none">Clear Filters</a></div>
<div class="cars"><?php foreach($filtered as $c):?><div class="card"><div class="img">🚗<span class="badge"><?=$c[4]?></span></div><div class="info"><h3><?=$c[2]?> <?=$c[0]?> <?=$c[1]?></h3><div class="specs"><span>⚡ <?=$c[7]?> HP</span><span>🔧 <?=$c[6]?></span><span>🎨 <?=$c[8]?></span><span>📦 <?=$c[5]?></span></div><div class="price">$<?=number_format($c[3])?></div><button class="view">View Details</button></div></div><?php endforeach;?></div>
<footer class="footer"><h3>🔧 Infrastructure Status</h3><div class="fi"><span class="ok">✅ Instance: <?=$id?></span><span class="ok">✅ Zone: <?=$az?></span><span class="ok">✅ Cars: <?=count($cars)?></span></div></footer></div></body></html>
PHP
chown -R apache:apache /var/www/html && chmod -R 755 /var/www/html && systemctl restart httpd
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
  health_check_grace_period = 600
  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }
}

output "elb_dns" { value = aws_elb.web_elb.dns_name }
output "web_sg_id" { value = aws_security_group.instance_sg.id }
output "elb_sg_id" { value = aws_security_group.elb_sg.id }
