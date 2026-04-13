output "alb_dns" {
  value = aws_lb.main_alb.dns_name
  description = "Acesse seu site através deste link"
}

output "rds_endpoint" {
  value = aws_db_instance.rds_master.address
  description = "Endpoint do banco de dados para conferência"
}