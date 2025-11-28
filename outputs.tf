output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnet_ids
}

# Web Tier Outputs
output "web_public_ip" {
  value = var.deploy_web ? module.web[0].web_instance_public_ip : ""
  description = "Public IP address of the web server"
}

output "web_url" {
  value = var.deploy_web ? "http://${module.web[0].web_instance_public_ip}" : ""
  description = "URL to access the web application"
}

# Monitoring Outputs
output "monitoring_public_ip" {
  value = var.deploy_monitoring ? module.monitoring[0].monitoring_instance_public_ip : ""
  description = "Public IP address of the monitoring server"
}

output "monitoring_dashboard_url" {
  value = var.deploy_monitoring ? module.monitoring[0].monitoring_dashboard_url : ""
  description = "URL to access the monitoring dashboard"
}

output "grafana_dashboard_url" {
  value = var.deploy_monitoring ? module.monitoring[0].grafana_dashboard_url : ""
  description = "URL to access the Grafana monitoring dashboard (admin/grafana123)"
}

# Database Outputs
output "aurora_cluster_endpoint" {
  value = var.deploy_database ? module.db[0].cluster_endpoint : ""
  description = "Aurora RDS cluster endpoint"
}

output "database_name" {
  value = "capstonedb"
  description = "Database name"
}