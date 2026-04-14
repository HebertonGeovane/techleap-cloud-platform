provider "aws" {
  region = var.region
  allowed_account_ids = [var.aws_account_id]
}

terraform {
  backend "s3" {
    bucket         = "techleap-terraform-state-heberton"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state-heberton"
  lifecycle {
    prevent_destroy = true
  }
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
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24","10.0.3.0/24", "10.0.4.0/24"] 
  public_subnets  = ["10.0.101.0/24","10.0.102.0/24"] 

  enable_nat_gateway = true 
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "techleap-bastion-key-tf"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWcOdlsEIPRSUQmvg/7uJEIDfdRxBxLhNvTxUN+ajenBA46VmiKJnv66uV/o0SjZzdGgxFF48tmqsvbSyajzexSPKmXBTfi5/rLsLCZZxJ4K43zhkmN/xB1oRQr26Uc1R6+hWN18BikVgu8nJ1n0gubJ+8f5nX0bbEXkdf19N1AbrgYNbn3GxA9RyQImeorI/xfGIJXuoYpo4dTdDgj3xyaEE9LRRpWyNVNIACAv+xVZlOw9G22ugk+/iABfXDcFs02IYm9+ezs0w2KokErkCGHR1OQsgx6x2NIopfz978ayywM/BMRRxr1v8iocAzNe9LwPtowHyF4p7tKtktSTYF"
}

resource "aws_instance" "bastion" {
  ami           = "ami-0c7217cdde317cfec" 
  instance_type = "t3.nano"               
  
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = aws_key_pair.bastion_key.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
  vpc_id      = module.vpc.vpc_id

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
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group-manual"
  
  subnet_ids = [module.vpc.private_subnets[2], module.vpc.private_subnets[3]]

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
  publicly_accessible    = false
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

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"] # Em produção usaríamos seu IP real, mas aqui libera geral
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

