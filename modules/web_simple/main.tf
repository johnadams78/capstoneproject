data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "web_sg" {
  name   = "capstone-web-sg"
  vpc_id = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "capstone-web-sg"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = true
  
  user_data = base64encode(<<-EOF
#!/bin/bash
yum update -y && yum install -y httpd php php-mysqlnd mysql
systemctl start httpd && systemctl enable httpd
DB_EP="${var.db_endpoint}"
DB_NM="${var.db_name}"
DB_US="${var.db_username}"
DB_PW="${var.db_password}"
echo "Waiting for RDS..." && for i in {1..60};do mysqladmin ping -h "$DB_EP" -u "$DB_US" -p"$DB_PW" --silent 2>/dev/null && break || sleep 10;done
echo "${filebase64("${path.module}/gen_index.b64")}" | base64 -d | base64 -d > /var/www/html/index.php
sed -i "s/__DB_EP__/$DB_EP/g;s/__DB_NM__/$DB_NM/g;s/__DB_US__/$DB_US/g;s/__DB_PW__/$DB_PW/g" /var/www/html/index.php
cat>/var/www/html/health.php<<'HP'
<?php header('Content-Type:application/json');$h='__DB_EP__';$n='__DB_NM__';$u='__DB_US__';$p='__DB_PW__';try{$d=new PDO("mysql:host=$h;dbname=$n",$u,$p);$s='connected';$c=$d->query("SELECT COUNT(*) FROM cars")->fetchColumn();}catch(PDOException $e){$s='disconnected';$c=0;}echo json_encode(['status'=>'healthy','database'=>['type'=>'Aurora MySQL','status'=>$s,'endpoint'=>$h,'cars_count'=>$c]]);?>
HP
sed -i "s/__DB_EP__/$DB_EP/g;s/__DB_NM__/$DB_NM/g;s/__DB_US__/$DB_US/g;s/__DB_PW__/$DB_PW/g" /var/www/html/health.php
chown -R apache:apache /var/www/html && systemctl restart httpd
echo "Car Dealer with Aurora RDS deployed!"
EOF
  )
  
  tags = {
    Name = "capstone-web-server"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
