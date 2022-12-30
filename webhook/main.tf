locals {
  webhook_endpoint = "webhook"
  role_path        = var.role_path == null ? "/${var.prefix}/" : var.role_path
  lambda_zip       = var.lambda_zip == null ? "${path.module}/lambda/webhook.zip" : var.lambda_zip
}

resource "aws_lambda_function_url" "webhook" {
  depends_on = [aws_lambda_function.webhook]

  function_name = aws_lambda_function.webhook.function_name
  #qualifier          = "${var.prefix}-github-webhook"
  authorization_type = "NONE"

}

resource "aws_lambda_function" "webhook" {
  s3_bucket         = var.lambda_s3_bucket != null ? var.lambda_s3_bucket : null
  s3_key            = var.webhook_lambda_s3_key != null ? var.webhook_lambda_s3_key : null
  s3_object_version = var.webhook_lambda_s3_object_version != null ? var.webhook_lambda_s3_object_version : null
  filename          = var.lambda_s3_bucket == null ? local.lambda_zip : null
  source_code_hash  = var.lambda_s3_bucket == null ? filebase64sha256(local.lambda_zip) : null
  function_name     = "${var.prefix}-github-webhook"
  role              = aws_iam_role.webhook_lambda.arn
  handler           = "index.githubWebhook"
  runtime           = var.lambda_runtime
  timeout           = var.lambda_timeout
  architectures     = [var.lambda_architecture]

  environment {
    variables = {
      EVENT_BUS_NAME                      = var.event_bus.name
      EVENT_SOURCE                        = "github.com"
      LOG_LEVEL                           = var.log_level
      LOG_TYPE                            = var.log_type
      PARAMETER_GITHUB_APP_WEBHOOK_SECRET = var.github_app_parameters.webhook_secret.name
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "webhook" {
  name              = "/aws/lambda/${aws_lambda_function.webhook.function_name}"
  retention_in_days = var.logging_retention_in_days
  kms_key_id        = var.logging_kms_key_id
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

resource "aws_iam_role" "webhook_lambda" {
  name                 = "${var.prefix}-github-webhook-lambda-role"
  assume_role_policy   = data.aws_iam_policy_document.lambda_assume_role_policy.json
  path                 = local.role_path
  permissions_boundary = var.role_permissions_boundary
  tags                 = var.tags
}

resource "aws_iam_role_policy" "webhook_logging" {
  name = "${var.prefix}-lambda-logging-policy"
  role = aws_iam_role.webhook_lambda.name
  policy = templatefile("${path.module}/policies/lambda-cloudwatch.json", {
    log_group_arn = aws_cloudwatch_log_group.webhook.arn
  })
}

resource "aws_iam_role_policy" "webhook_ssm" {
  name = "${var.prefix}-lambda-webhook-ssm-policy"
  role = aws_iam_role.webhook_lambda.name

  policy = templatefile("${path.module}/policies/lambda-ssm.json", {
    github_app_webhook_secret_arn = var.github_app_parameters.webhook_secret.arn,
    kms_key_arn                   = var.kms_key_arn != null ? var.kms_key_arn : ""
  })
}

resource "aws_iam_role_policy" "publish" {
  name = "${var.prefix}-lambda-webhook-publish-policy"
  role = aws_iam_role.webhook_lambda.name

  policy = templatefile("${path.module}/policies/lambda-publish-policy.json", {
    resource_arns = jsonencode("${var.event_bus.arn}")
  })
}
