locals {
  lambda_zip  = "${path.module}/lambda/echo.zip"
  lambda_name = "echo"
}


resource "aws_lambda_function" "main" {
  filename         = local.lambda_zip
  source_code_hash = filebase64sha256(local.lambda_zip)
  function_name    = "${var.prefix}-${local.lambda_name}"
  role             = aws_iam_role.main.arn
  handler          = "index.echo"
  runtime          = var.lambda_runtime
  timeout          = 30
  architectures    = [var.lambda_architecture]

  environment {
    variables = {
      LOG_LEVEL = var.log_level
      LOG_TYPE  = var.log_type
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = var.logging_retention_in_days
  tags              = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "main" {
  name               = "${var.prefix}-${local.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "logging" {
  name = "${var.prefix}-lambda-logging-policy"
  role = aws_iam_role.main.name
  policy = templatefile("${path.module}/policies/lambda-cloudwatch.json", {
    log_group_arn = aws_cloudwatch_log_group.main.arn
  })
}
