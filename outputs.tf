output "alb_dns_name" {
  description = "The public URL to access the load balancer"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "The database connection endpoint"
  value       = aws_db_instance.main.endpoint
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}