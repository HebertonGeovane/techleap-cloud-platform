provider "aws" {
  region = var.region
  allowed_account_ids = [var.aws_account_id]
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state-heberton"
}

resource "aws_ecr_repository" "frontend" {
  name = "${var.project_name}-frontend"
  force_delete = true
}

resource "aws_ecr_repository" "backend" {
  name = "${var.project_name}-backend"
  force_delete = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "${var.project_name}-vpc"
  cidr   = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"] # Para o RDS
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"] # Para o Load Balancer

  enable_nat_gateway = true 
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group-manual"
  # Aqui usamos as subnets privadas que você viu no seu Resource Map
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "techleap-rds-subnet-group"
  }
}

resource "aws_db_instance" "rds_master" {
  identifier           = "${var.project_name}-db"
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "techleapdb"
  username             = "techuser"
  password             = var.db_password
  multi_az             = true 
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
  backup_retention_period = 0
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.ecs_tasks_sg.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

