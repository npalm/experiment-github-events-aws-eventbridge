resource "random_uuid" "firehose_stream" {}

resource "aws_s3_bucket" "firehose_stream" {
  bucket        = "${local.prefix}-${random_uuid.firehose_stream.result}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "firehose_stream" {
  bucket = aws_s3_bucket.firehose_stream.id
  acl    = "private"
}

data "aws_iam_policy_document" "firehose_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "${local.prefix}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role_policy.json
}

resource "aws_iam_role_policy" "firehose_s3" {
  name = "${local.prefix}-s3"
  role = aws_iam_role.firehose_role.name
  policy = templatefile("${path.module}/policies/firehose-s3.json", {
    s3_bucket_arn = aws_s3_bucket.firehose_stream.arn
  })
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "${local.prefix}-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.firehose_stream.arn
  }
}
