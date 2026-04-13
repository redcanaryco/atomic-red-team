resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/T1648-1"
  retention_in_days = 1
}
