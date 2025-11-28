output "web_instance_public_ip" {
  value = aws_instance.web.public_ip
  description = "Public IP address of the web server"
}

output "web_sg_id" {
  value = aws_security_group.web_sg.id
  description = "Security group ID for web tier"
}