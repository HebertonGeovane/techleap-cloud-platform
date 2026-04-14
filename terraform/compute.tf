resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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


resource "aws_lb" "main_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
}


resource "aws_lb_target_group" "app_tg" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}


resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.project_name}-backend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path = "/metrics" 
    port = "3000"
  }
}



resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}


resource "aws_lb_listener" "api_3000" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}


resource "aws_ecs_cluster" "main_cluster" {
  name = "${var.project_name}-cluster"
}


resource "aws_ecs_task_definition" "app_task" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:latest"
      cpu       = 128
      memory    = 256
      portMappings = [{ containerPort = 80, hostPort = 80 }]
      environment = [
        { name = "BACKEND_URL", value = "http://${aws_lb.main_alb.dns_name}:3000" }
      ]
    },
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend.repository_url}:latest"
      cpu       = 128
      memory    = 256
      portMappings = [{ containerPort = 3000, hostPort = 3000 }]
      environment = [
        { name = "DB_HOST", value = aws_db_instance.rds_master.address },
        { name = "DB_USER", value = "techuser" },
        { name = "DB_PASSWORD", value = var.db_password },
        { name = "DB_NAME", value = "techleapdb" }
      ]
    }
  ])
}


resource "aws_ecs_service" "main_service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 2 
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "frontend"
    container_port   = 80
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 3000
  }
}

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.project_name}-tasks-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb_sg.id] 
  }
  
  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}