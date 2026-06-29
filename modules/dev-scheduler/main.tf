# =============================================================================
# dev-scheduler — stop RDS + scale ECS to 0 off-hours to cut dev cost.
#
# A Lambda (tag-driven) is invoked by two EventBridge schedules: one to stop
# (evening) and one to start (morning), on weekdays. Resources opt in via a tag
# (default AutoStop=true). Multi-AZ RDS is skipped (AWS can't stop it).
#
# Typical saving: ~50-65% of a dev environment's compute/db cost.
# =============================================================================

data "aws_caller_identity" "current" {}

# ── Lambda package ────────────────────────────────────────────────────────────
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/.build/dev-scheduler.zip"
}

# ── IAM for the Lambda ────────────────────────────────────────────────────────
resource "aws_iam_role" "lambda" {
  name = "${var.name}-dev-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "lambda" {
  name = "${var.name}-dev-scheduler"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Sid      = "DiscoverByTag"
        Effect   = "Allow"
        Action   = ["tag:GetResources"]
        Resource = "*"
      },
      {
        Sid      = "RdsStartStop"
        Effect   = "Allow"
        Action   = ["rds:DescribeDBInstances", "rds:StopDBInstance", "rds:StartDBInstance"]
        Resource = "*"
      },
      {
        Sid    = "EcsScale"
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices", "ecs:UpdateService",
          "ecs:ListTagsForResource", "ecs:TagResource",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.name}-dev-scheduler"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.13"
  handler          = "lambda.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 120

  environment {
    variables = {
      TAG_KEY   = var.tag_key
      TAG_VALUE = var.tag_value
    }
  }

  tags = var.tags
}

# ── EventBridge Scheduler: role to invoke Lambda ──────────────────────────────
resource "aws_iam_role" "scheduler" {
  name = "${var.name}-dev-scheduler-invoke"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "scheduler" {
  name = "${var.name}-dev-scheduler-invoke"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = aws_lambda_function.this.arn
    }]
  })
}

# ── Stop + start schedules ────────────────────────────────────────────────────
resource "aws_scheduler_schedule" "stop" {
  name = "${var.name}-dev-stop"

  flexible_time_window { mode = "OFF" }
  schedule_expression          = var.stop_cron
  schedule_expression_timezone = var.timezone

  target {
    arn      = aws_lambda_function.this.arn
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ action = "stop" })
  }
}

resource "aws_scheduler_schedule" "start" {
  name = "${var.name}-dev-start"

  flexible_time_window { mode = "OFF" }
  schedule_expression          = var.start_cron
  schedule_expression_timezone = var.timezone

  target {
    arn      = aws_lambda_function.this.arn
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ action = "start" })
  }
}
