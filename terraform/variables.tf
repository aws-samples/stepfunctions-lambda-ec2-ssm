variable "aws_region" {
  type = string
  description = "Specified AWS Region"
  default = "us-west-1"
}

variable "aws_credential_profile" {
  type = string
  description = "AWS Profile With Admin Access"
  default = "default"
}

variable "ec2_ami" {
  type = string
  description = "Windows Server AMI for EC2"
  default = "ami-0253a8101a3b88872"
}

variable "ec2_instance_type" {
  type = string
  description = "Instance type for EC2"
  default = "t2.micro"
}

variable "ec2_subnet_id" {
  type = string
  description = "Subnet for EC2"
  default = "subnet-xxxxxxxxx"
}

variable "ec2_security_group" {
  type = list
  description = "Security Group for EC2"
  default = ["sg-xxxxxxxxxx"]
}

variable "ssm_script_cmd" {
  type = string
  description = "Powershell script to be executed in SSM Run Command"
  default = "sample4.ps1"
}


variable "ssm_script_bucket_uri" {
  type = string
  description = "S3 Bucket HTTP Uri which holds the Powershell script to be executed in SSM Run Command"
  default = "https://sfn-lambda-ec2-ssm-script.s3.us-west-1.amazonaws.com/"
}


variable "ssm_cloud_watch_log_group" {
  type = string
  description = "Cloud Watch Log Group"
  default = "sfn-lambda-ec2-ssm"
}


variable "ssm_cmd_output_bucket_name" {
  type = string
  description = "S3 Bucket name to store the SSM Run Command execution output"
  default = "sfn-lambda-ec2-ssm-results"
}


variable "ssm_cmd_output_bucket_prefix" {
  type = string
  description =  "S3 Bucket Prefix to store the SSM Run Command execution output"
  default = "sfn-lambda-ec2-ssm"
}
