# Application Load Balancer
# VIOLATION: Pattern 17 - No HTTPS listener
resource "aws_lb" "main" {
  name               = "${var.environment}-medvault-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = var.private_subnets

  enable_deletion_protection = false
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-medvault-alb"
    }
  )
}

# ALB Listener (HTTP only - VIOLATION: Pattern 17)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTPS Listener (commented out - would be the fix)
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = "arn:aws:acm:..."
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }
# }

# Target group for ALB
resource "aws_lb_target_group" "app" {
  name        = "${var.environment}-medvault-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-medvault-tg"
    }
  )
}

# ECR Repositories
# VIOLATION: Pattern 24 - ECR scan disabled
resource "aws_ecr_repository" "app" {
  for_each = toset([
    "patient-api",
    "phi-processor",
    "notification-service",
    "audit-logger"
  ])

  name                 = "${var.environment}/medvault-${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false # VIOLATION: Pattern 24
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-medvault-${each.value}"
    }
  )
}

# ECR lifecycle policy (example)
resource "aws_ecr_lifecycle_policy" "app" {
  for_each           = aws_ecr_repository.app
  repository         = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lambda Functions
# VIOLATION: Pattern 25 - Lambda functions without VPC configuration
resource "aws_lambda_function" "data_processor" {
  count            = 1
  filename         = "lambda_placeholder.zip" # Placeholder - actual code would be packaged
  function_name    = "${var.environment}-data-processor"
  role             = data.aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 256

  # VIOLATION: Pattern 25 - no VPC configuration
  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = "INFO"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-data-processor"
    }
  )

  depends_on = [data.aws_iam_role.lambda_execution]
}

# Optional: Lambda with VPC (when enabled)
resource "aws_lambda_function" "notification_sender" {
  count            = var.enable_lambda_vpc ? 1 : 0
  filename         = "lambda_placeholder.zip"
  function_name    = "${var.environment}-notification-sender"
  role             = data.aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 128

  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [data.aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-notification-sender"
    }
  )

  depends_on = [data.aws_iam_role.lambda_execution]
}

# Lambda with VPC but also without VPC (testing mixed scenario)
resource "aws_lambda_function" "audit_logger" {
  count            = 1
  filename         = "lambda_placeholder.zip"
  function_name    = "${var.environment}-audit-logger"
  role             = data.aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  timeout          = 45
  memory_size      = 256

  # VIOLATION: Pattern 25 - no VPC, another violation
  environment {
    variables = {
      ENVIRONMENT = var.environment
      DEBUG       = "false"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-audit-logger"
    }
  )

  depends_on = [data.aws_iam_role.lambda_execution]
}

# Lambda for report generation
resource "aws_lambda_function" "report_generator" {
  count            = 1
  filename         = "lambda_placeholder.zip"
  function_name    = "${var.environment}-report-generator"
  role             = data.aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 300
  memory_size      = 512
  ephemeral_storage {
    size = 10240
  }

  # VIOLATION: Pattern 25 - another without VPC
  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-report-generator"
    }
  )

  depends_on = [data.aws_iam_role.lambda_execution]
}

# CloudWatch Log Group for ALB access logs
resource "aws_cloudwatch_log_group" "alb_logs" {
  name              = "/aws/alb/${var.environment}-medvault"
  retention_in_days = 7

  tags = var.tags
}

# S3 bucket for ALB access logs (if we want S3 logging instead of CloudWatch)
resource "aws_s3_bucket" "alb_logs" {
  bucket = "medvault-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-alb-logs"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data sources
data "aws_iam_role" "lambda_execution" {
  name = "${var.environment}-lambda-execution-role-*"
}

data "aws_security_group" "alb" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-alb-sg"]
  }
}

data "aws_security_group" "lambda" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-lambda-sg"]
  }
}

data "aws_caller_identity" "current" {}
