output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnet_ids
}

output "monitoring_instance_public_ip" {
  value = module.monitoring.monitoring_instance_public_ip
  description = "Public IP address of the monitoring server"
}

output "monitoring_dashboard_url" {
  value = module.monitoring.monitoring_dashboard_url
  description = "URL to access the monitoring dashboard"
}

output "grafana_dashboard_url" {
  value = module.monitoring.grafana_dashboard_url
  description = "URL to access the Grafana monitoring dashboard (admin/grafana123)"
}

output "aurora_cluster_endpoint" {
  value = module.db.cluster_endpoint
  description = "Aurora RDS cluster endpoint"
}

output "database_name" {
  value = "capstonedb"
  description = "Database name"
}