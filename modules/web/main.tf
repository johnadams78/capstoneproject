data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow public HTTP/HTTPS to ALB"
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
  description = "Allow HTTP from ALB to instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    security_groups          = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
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
    yum update -y
    amazon-linux-extras install -y nginx1
  cat > /usr/share/nginx/html/index.html <<HTML
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>Life Science & Space Explorer</title>
      <style>
        body { margin:0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Fira Sans", "Droid Sans", "Helvetica Neue", Arial, sans-serif; background: radial-gradient(1200px 600px at 50% -200px,#081022,#000); color:#e6edf3; }
        header { padding:32px 20px; text-align:center; }
        h1 { margin:0 0 8px; font-weight:700; letter-spacing:.5px; }
        p.lead { margin:0; opacity:.8 }
        .grid { display:grid; gap:16px; grid-template-columns: repeat(auto-fit,minmax(260px,1fr)); padding:20px; max-width:1100px; margin:0 auto; }
        .card { background: rgba(255,255,255,.04); border: 1px solid rgba(255,255,255,.08); border-radius:12px; padding:18px; box-shadow: 0 8px 24px rgba(0,0,0,.35); }
        .card h3 { margin:0 0 8px; }
        .pill { display:inline-block; padding:2px 10px; border-radius:999px; font-size:12px; background:#0e6efd22; border:1px solid #0e6efd66; color:#8ecbff }
        footer { text-align:center; padding:24px; opacity:.65; font-size:14px }
        a { color:#8ecbff; text-decoration:none }
        a:hover { text-decoration:underline }
      </style>
    </head>
    <body>
      <header>
        <h1>Life Science & Space Explorer</h1>
        <p class="lead">Deployed automatically via Terraform on AWS (ALB + Auto Scaling EC2).</p>
        <span class="pill">Tier: Web</span>
      </header>
      <section class="grid">
        <div class="card">
          <h3>Genomics</h3>
          <p>Understand how variations in DNA influence traits and disease. From sequencing to variant calling and annotation pipelines.</p>
        </div>
        <div class="card">
          <h3>Proteomics</h3>
          <p>Explore the structure and function of proteins using mass spectrometry, structural biology, and bioinformatics.</p>
        </div>
        <div class="card">
          <h3>Space Weather</h3>
          <p>Solar flares and coronal mass ejections can disrupt communications on Earth. Monitor KP-index and geomagnetic storms.</p>
        </div>
        <div class="card">
          <h3>Astrobiology</h3>
          <p>Study the potential for life beyond Earth: habitability, biosignatures, and extremophiles in analog environments.</p>
        </div>
      </section>
      <footer>
        <span>Instance: $(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)</span>
        &nbsp;•&nbsp;
        <span>AZ: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null)</span>
      </footer>
    </body>
    </html>
  HTML
    systemctl enable --now nginx
  EOT)
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
  target_group_arns = [aws_lb_target_group.tg.arn]
  health_check_type = "ELB"
  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }
}

output "alb_dns" { value = aws_lb.alb.dns_name }
output "web_sg_id" { value = aws_security_group.instance_sg.id }
output "alb_sg_id" { value = aws_security_group.alb_sg.id }
