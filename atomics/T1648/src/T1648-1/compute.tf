data "archive_file" "lambda_code" {
  type                    = "zip"
  source_content          = <<EOF
def lambda_handler(event, context):
    return "This is a benign lambda function"
EOF
  source_content_filename = "lambda.py"
  output_path             = "${path.module}/lambda_code.zip"
}

resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda_code.output_path
  function_name    = "T1648-1"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_code.output_base64sha256
  timeout          = 30
}
