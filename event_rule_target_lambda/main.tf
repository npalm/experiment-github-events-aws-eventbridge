resource "aws_cloudwatch_event_target" "main" {
  rule           = var.event_rule.name
  arn            = var.target.arn
  event_bus_name = var.event_bus_name
}

resource "aws_lambda_permission" "main" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.target.name
  principal     = "events.amazonaws.com"
  source_arn    = var.event_rule.arn
}
