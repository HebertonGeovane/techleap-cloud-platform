output "alb_dns" {
  value       = aws_lb.main_alb.dns_name
  description = "Acesse seu site através deste link"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID da VPC atual para conferência"
}

output "rds_endpoint" {
  value       = aws_db_instance.rds_master.address
  description = "Host do banco de dados para o DBeaver"
}