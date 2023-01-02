locals {
  aws_region = "eu-west-1"
  prefix     = "npalm-github"
}

resource "aws_cloudwatch_event_bus" "messenger" {
  name = "${local.prefix}-messages"
}

resource "aws_cloudwatch_event_archive" "messenger" {
  name             = "${local.prefix}-events-archive"
  event_source_arn = aws_cloudwatch_event_bus.messenger.arn
}

resource "random_id" "random" {
  byte_length = 20
}

module "ssm" {
  source      = "./ssm"
  path_prefix = "/${local.prefix}/messenger"
  github_app = {
    webhook_secret = random_id.random.hex
  }
}

module "webhook" {
  source = "./webhook"

  prefix = local.prefix
  event_bus = {
    name = aws_cloudwatch_event_bus.messenger.name
    arn  = aws_cloudwatch_event_bus.messenger.arn
  }
  github_app_parameters = {
    webhook_secret = module.ssm.parameters.github_app_webhook_secret
  }
}

module "echo" {
  source = "./echo"

  prefix = local.prefix
}

module "event_rule_target_lambda" {
  source = "./event_rule_target_lambda"

  target = {
    arn  = module.echo.lambda.arn
    name = module.echo.lambda.function_name
  }
  event_bus_name = aws_cloudwatch_event_bus.messenger.name
  event_rule = {
    arn  = aws_cloudwatch_event_rule.all.arn
    name = aws_cloudwatch_event_rule.all.name
  }

}


resource "aws_cloudwatch_event_rule" "all" {
  name           = "${local.prefix}-github-events-all"
  description    = "Caputure all GitHub events"
  event_bus_name = aws_cloudwatch_event_bus.messenger.name
  event_pattern  = <<EOF
{
  "source": [{
    "prefix": "github"
  }]
}
EOF
}

resource "aws_cloudwatch_log_group" "all" {
  name              = "/aws/events/${local.prefix}/messenger"
  retention_in_days = 7
}

module "event_rule_target_log_group" {
  source = "./event_rule_target_log_group"

  target = {
    arn  = aws_cloudwatch_log_group.all.arn
    name = "/aws/events/${local.prefix}/messenger"
  }
  event_bus_name = aws_cloudwatch_event_bus.messenger.name
  event_rule = {
    arn  = aws_cloudwatch_event_rule.all.arn
    name = aws_cloudwatch_event_rule.all.name
  }
}


module "event_rule_target_firehose_s3_stream" {
  source = "./event_rule_target_firehose_s3_stream"

  target = {
    arn  = aws_kinesis_firehose_delivery_stream.extended_s3_stream.arn
    name = aws_kinesis_firehose_delivery_stream.extended_s3_stream.name
  }
  event_bus_name = aws_cloudwatch_event_bus.messenger.name
  event_rule = {
    arn  = aws_cloudwatch_event_rule.all.arn
    name = aws_cloudwatch_event_rule.all.name
  }
}


