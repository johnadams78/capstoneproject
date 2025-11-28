output "monitoring_instance_public_ip" {
  value = aws_instance.monitoring.public_ip
  description = "Public IP address of the monitoring server"
}

output "monitoring_dashboard_url" {
  value = "http://${aws_instance.monitoring.public_ip}"
  description = "URL to access the monitoring dashboard"
}

output "grafana_dashboard_url" {
  value = "http://${aws_instance.monitoring.public_ip}:3000"
  description = "URL to access the Grafana monitoring dashboard"
}