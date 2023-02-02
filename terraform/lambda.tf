// Create archives for AWS Lambda functions which will be used for Step Function

data "archive_file" "archive-create-ec2" {
  type        = "zip"
  output_path = "../lambda/create-ec2/archive.zip"
  source_file = "../lambda/create-ec2/lambda-function.py"
}

data "archive_file" "archive-delete-ec2" {
  type        = "zip"
  output_path = "../lambda/delete-ec2/archive.zip"
  source_file = "../lambda/delete-ec2/lambda-function.py"
}

data "archive_file" "archive-get-ssm-run-status" {
  type        = "zip"
  output_path = "../lambda/get-ssm-run-status/archive.zip"
  source_file = "../lambda/get-ssm-run-status/lambda-function.py"
}

data "archive_file" "archive-ssm-runcmd" {
  type        = "zip"
  output_path = "../lambda/ssm-runcmd/archive.zip"
  source_file = "../lambda/ssm-runcmd/lambda-function.py"
}

// Create IAM Instance Profile Role
resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = "ssm-ec2-instance-role"
  role = "${aws_iam_role.iam_instance_profile_for_ec2.name}"
}

resource "aws_iam_role" "iam_instance_profile_for_ec2" {
  name = "ssm-ec2-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com","lambda.amazonaws.com","ssm.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm-managed-instance" {
  role       = aws_iam_role.iam_instance_profile_for_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2-s3-access" {
  role       = aws_iam_role.iam_instance_profile_for_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

// Create IAM role for AWS Lambda

resource "aws_iam_role" "iam_for_lambda" {
  name = "stepFunctionLambdaRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ec2_iampass_policy" {
  name = "ec2_iampass_policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["iam:PassRole"],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_for_lambda_ec2" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
resource "aws_iam_role_policy_attachment" "iam_for_lambda_ssm" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "iam_for_lambda_s3" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "iam_for_ec2_creation" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.ec2_iampass_policy.arn}"
}

// Create AWS Lambda functions

resource "aws_lambda_function" "create-ec2" {
  filename         = "../lambda/create-ec2/archive.zip"
  function_name    = "sfn-create-ec2"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "lambda-function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      instance_type = "${var.ec2_instance_type}",
      subnet_id = "${var.ec2_subnet_id}"
      security_group = var.ec2_security_group[0],
      ami = "${var.ec2_ami}"
    }
  }
}

resource "aws_lambda_function" "delete-ec2" {
  filename         = "../lambda/delete-ec2/archive.zip"
  function_name    = "sfn-delete-ec2"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "lambda-function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 900
}

resource "aws_lambda_function" "get-ssm-run-status" {
  filename         = "../lambda/get-ssm-run-status/archive.zip"
  function_name    = "sfn-get-ssm-run-status"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "lambda-function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 900
}

resource "aws_lambda_function" "ssm-runcmd" {
  filename         = "../lambda/ssm-runcmd/archive.zip"
  function_name    = "sfn-ssm-runcmd"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "lambda-function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 900
  environment {
    variables = {
      script_cmd = "${var.ssm_script_cmd}",
      script_bucket_uri = "${var.ssm_script_bucket_uri}"
      cloud_watch_log_group = "${var.ssm_cloud_watch_log_group}"
      cmd_output_bucket_name = "${var.ssm_cmd_output_bucket_name}"
      cmd_output_bucket_prefix = "${var.ssm_cmd_output_bucket_prefix}"
    }
  }
}

