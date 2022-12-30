resource "aws_cloudwatch_event_target" "main" {
  rule           = var.event_rule.name
  arn            = var.target.arn
  event_bus_name = var.event_bus_name
}

data "aws_iam_policy_document" "main" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${var.target.arn}:*"
    ]

    principals {
      identifiers = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
      type        = "Service"
    }

    condition {
      test     = "ArnEquals"
      values   = [var.event_rule.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "main" {
  policy_document = data.aws_iam_policy_document.main.json
  policy_name     = replace(var.target.name, "/", "-")
}
