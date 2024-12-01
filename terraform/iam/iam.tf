# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.stack_name}_lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    project = var.stack_name
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.stack_name}_lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          "arn:aws:iam::${var.account_id}:role/${var.stack_name}_ecs_execution_role",
          "arn:aws:iam::${var.account_id}:role/${var.stack_name}_ecs_task_role"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "${var.stack_name}_lambda_policy_attachment"
  roles      = [aws_iam_role.lambda_execution_role.name]
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# ECS Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.stack_name}_ecs_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    project = var.stack_name
  }
}

resource "aws_iam_policy" "ecs_execution_policy" {
  name = "${var.stack_name}_ecs_execution_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          data.terraform_remote_state.s3_ecr.outputs.ecr_repo_arn,
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/ecs/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${data.terraform_remote_state.s3_ecr.outputs.s3_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_execution_policy_attachment" {
  name       = "${var.stack_name}_ecs_execution_policy_attachment"
  roles      = [aws_iam_role.ecs_execution_role.name]
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.stack_name}_ecs_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    project = var.stack_name
  }
}

resource "aws_iam_policy" "ecs_task_policy" {
  name = "${var.stack_name}_ecs_task_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${data.terraform_remote_state.s3_ecr.outputs.s3_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_policy_attachment" {
  name       = "${var.stack_name}_ecs_task_policy_attachment"
  roles      = [aws_iam_role.ecs_task_role.name]
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# GitHub Actions Role
resource "aws_iam_role" "github_actions_role" {
  name = "${var.stack_name}_github_actions_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com" }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_repo_name}:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    project = var.stack_name
  }
}

resource "aws_iam_policy" "github_actions_policy" {
  name = "${var.stack_name}_github_actions_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction"
        ]
        Resource = "arn:aws:lambda:${var.region}:${var.account_id}:function:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = data.terraform_remote_state.s3_ecr.outputs.ecr_repo_arn
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${data.terraform_remote_state.s3_ecr.outputs.s3_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "github_actions_policy_attachment" {
  name       = "${var.stack_name}_github_actions_policy_attachment"
  roles      = [aws_iam_role.github_actions_role.name]
  policy_arn = aws_iam_policy.github_actions_policy.arn
}
