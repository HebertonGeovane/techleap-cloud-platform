variable "region" {
  default = "us-east-1"
}

variable "aws_account_id" {
  description = "ID da conta AWS para trava de segurança"
  type        = string
}

variable "project_name" {
  default = "techleap"
}

variable "db_password" {
  description = "Senha do RDS (será passada via Github Secrets)"
  sensitive   = true
}