# Create IAM role for AWS Step Function
resource "aws_iam_role" "iam_for_sfn" {
  name = "stepFunctionExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

// Attach policy to IAM Role for Step Function
resource "aws_iam_role_policy_attachment" "iam_for_sfn_ec2" {
  role       = "${aws_iam_role.iam_for_sfn.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
resource "aws_iam_role_policy_attachment" "iam_for_sfn_ssm" {
  role       = "${aws_iam_role.iam_for_sfn.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}
resource "aws_iam_role_policy_attachment" "iam_for_sfn_lambda" {
  role       = "${aws_iam_role.iam_for_sfn.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

// Create state machine for step function
resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "ec2-ssm-state-machine-workflow"
  role_arn = "${aws_iam_role.iam_for_sfn.arn}"

  definition = <<EOF
{
    "Comment": "Creation of EC2",
    "StartAt": "Create EC2",
    "States": {
      "Create EC2": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "OutputPath": "$.Payload",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "${aws_lambda_function.create-ec2.arn}"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "Next": "SSM Run Command"
      },
      "SSM Run Command": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "OutputPath": "$.Payload",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "${aws_lambda_function.ssm-runcmd.arn}"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "Next": "Wait"
      },
      "Wait": {
        "Type": "Wait",
        "Seconds": 30,
        "Next": "Get RunCommand Status"
      },
      "Get RunCommand Status": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "OutputPath": "$.Payload",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "${aws_lambda_function.get-ssm-run-status.arn}"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "Next": "Check RunCommand Status"
      },
      "Check RunCommand Status": {
        "Type": "Choice",
        "Choices": [
          {
            "Variable": "$.status",
            "StringMatches": "Success",
            "Next": "Success"
          },
          {
            "Or": [
              {
                "Variable": "$.status",
                "StringMatches": "InProgress"
              },
              {
                "Variable": "$.status",
                "StringMatches": "Delayed"
              },
              {
                "Variable": "$.status",
                "StringMatches": "Pending"
              },
              {
                "Variable": "$.status",
                "StringMatches": "Incomplete"
              }
            ],
            "Next": "Wait"
          },
          {
            "Variable": "$.status",
            "StringMatches": "Failed",
            "Next": "Fail"
          }
        ]
      },
      "Success": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "OutputPath": "$.Payload",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "${aws_lambda_function.delete-ec2.arn}"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "End": true
      },
      "Fail": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "OutputPath": "$.Payload",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "${aws_lambda_function.delete-ec2.arn}"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "End": true
      }
    }
  }
EOF

  depends_on = [aws_lambda_function.create-ec2,aws_lambda_function.get-ssm-run-status,aws_lambda_function.ssm-runcmd,aws_lambda_function.delete-ec2]

}

