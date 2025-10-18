# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "demo-ecs-cluster"
}

# Latest ECS-optimized AL2 AMI
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# Security groups
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB ingress"
  vpc_id      = aws_vpc.main.id
  ingress { from_port=80 to_port=80 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  egress  { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "ECS host"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "From ALB"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

# Launch template for ECS host
data "cloudinit_config" "ecs_user_data" {
  gzip          = false
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = <<-EOF
      #cloud-config
      write_files:
        - path: /etc/ecs/ecs.config
          permissions: "0644"
          owner: root
          content: |
            ECS_CLUSTER=${aws_ecs_cluster.this.name}
            ECS_LOGLEVEL=info
    EOF
  }
}
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.instance_type
  iam_instance_profile { name = aws_iam_instance_profile.ecs_instance.name }
  user_data = data.cloudinit_config.ecs_user_data.rendered
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.project_name}-ecs-host" }
  }
}

# AutoScaling Group (capacity = 1)
resource "aws_autoscaling_group" "ecs" {
  name                      = "${var.project_name}-asg"
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  vpc_zone_identifier       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  health_check_type         = "EC2"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  lifecycle { ignore_changes = [desired_capacity] }
}

# Target Group for instances
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# ECS service + initial task definition
resource "aws_ecs_task_definition" "app" {
  family                   = "demo-web-td"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "demo-web",
      image     = "public.ecr.aws/nginx/nginx:alpine",
      essential = true,
      portMappings = [{ containerPort = 3000, hostPort = 0, protocol = "tcp" }],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      },
      healthCheck = {
        retries     = 3,
        command     = ["CMD-SHELL","curl -sf http://localhost:3000/health || exit 1"],
        timeout     = 5,
        interval    = 30,
        startPeriod = 10
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "demo-web-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "demo-web"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200
}
