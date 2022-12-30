resource "aws_cloudwatch_event_target" "main" {
  rule           = var.event_rule.name
  arn            = var.target.arn
  event_bus_name = var.event_bus_name
  role_arn       = aws_iam_role.event_rule_firehose_role.arn
}

data "aws_iam_policy_document" "event_rule_firehose_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "event_rule_firehose_role" {
  name               = var.target.name
  assume_role_policy = data.aws_iam_policy_document.event_rule_firehose_role.json
}

resource "aws_iam_role_policy" "event_rule_firehose_role" {
  name = "target-event-rule-firehose"
  role = aws_iam_role.event_rule_firehose_role.name
  policy = templatefile("${path.module}/policies/firehose-stream.json", {
    firehose_stream_arn = var.target.arn
  })
}
