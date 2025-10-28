############################################
# VPC + Networking
############################################

resource "aws_vpc" "clif_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "clif-vpc"
  }
}

resource "aws_internet_gateway" "clif_igw" {
  vpc_id = aws_vpc.clif_vpc.id

  tags = {
    Name = "clif-igw"
  }
}

# Public Subnet A
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.clif_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "clif-public-a"
  }
}

# Public Subnet B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.clif_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "clif-public-b"
  }
}

# Route table for public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.clif_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clif_igw.id
  }

  tags = {
    Name = "clif-public-rt"
  }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

############################################
# Security Groups
############################################

# ALB security group: allow HTTP from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "clif-alb-sg"
  description = "Allow inbound HTTP from the world"
  vpc_id      = aws_vpc.clif_vpc.id

  ingress {
    description = "Allow HTTP from anyone"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "clif-alb-sg"
  }
}

# App/task security group: only allow traffic from ALB on port 3000
resource "aws_security_group" "app_sg" {
  name        = "clif-app-sg"
  description = "Allow ALB to reach ECS tasks on 3000"
  vpc_id      = aws_vpc.clif_vpc.id

  ingress {
    description     = "From ALB only on port 3000"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "clif-app-sg"
  }
}

############################################
# Load Balancer + Target Group + Listener
############################################

resource "aws_lb" "clif_alb" {
  name               = "clif-fargate-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "clif-fargate-alb"
  }
}

resource "aws_lb_target_group" "clif_tg" {
  name        = "clif-fargate-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.clif_vpc.id

  health_check {
    path                = "/"
    port                = "3000"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }

  tags = {
    Name = "clif-fargate-tg"
  }
}

resource "aws_lb_listener" "clif_http_listener" {
  load_balancer_arn = aws_lb.clif_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clif_tg.arn
  }
}

############################################
# IAM Role for ECS Task Execution
############################################

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "clif-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach ECR + CloudWatch access for ECS tasks
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

############################################
# ECS Cluster
############################################

resource "aws_ecs_cluster" "clif_cluster" {
  name = "clif-fargate-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = {
    Name = "clif-fargate-cluster"
  }
}

############################################
# ECS Task Definition (your container)
############################################

resource "aws_ecs_task_definition" "clif_task" {
  family                   = "clif-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::007998028600:role/clif-ecs-task-execution-role-local"
  #task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "clif-app"
      image     = "007998028600.dkr.ecr.us-east-1.amazonaws.com/clif-fargate-app:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
    }
  ])
}

############################################
# ECS Service (keeps task running + hooks to ALB)
############################################

resource "aws_ecs_service" "clif_service" {
  name            = "clif-service"
  cluster         = aws_ecs_cluster.clif_cluster.id
  task_definition = aws_ecs_task_definition.clif_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.clif_tg.arn
    container_name   = "clif-app"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.clif_http_listener
  ]

  tags = {
    Name = "clif-service"
  }
}

############################################
# Outputs
############################################

output "alb_dns_name" {
  description = "Public DNS of the ALB (open this in your browser)"
  value       = aws_lb.clif_alb.dns_name
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.clif_cluster.name
}

output "ecr_repo_url" {
  description = "ECR repo URL for container image"
  value       = "007998082600.dkr.ecr.us-east-1.amazonaws.com/clif-fargate-app:latest"
}

output "app_security_group_id" {
  description = "Security group that ECS tasks will run in"
  value       = aws_security_group.app_sg.id
}

output "public_subnet_ids" {
  description = "Public subnets for Fargate"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.clif_vpc.id
}
