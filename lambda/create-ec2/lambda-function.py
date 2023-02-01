# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
import json
import boto3
import os
import time
 
#BOTO3 CLIENTS
ec2_client = boto3.client("ec2", region_name=os.environ['AWS_REGION'])
 
def create_instance():
    instances = ec2_client.run_instances(
        ImageId=os.environ['ami'],
        MinCount=1,
        MaxCount=1,
        SecurityGroupIds=[os.environ['security_group']],
        InstanceType=os.environ['instance_type'],
        SubnetId=os.environ['subnet_id'],
        IamInstanceProfile={'Name': 'ssm-ec2-instance-role'}
        )
    instance_id = instances["Instances"][0]["InstanceId"]
   
    max_time = 600 # 10min
    start_time = 0
    health_check = False
   
    while start_time <= max_time:
        response = ec2_client.describe_instance_status(InstanceIds=[instance_id])
        for instance in response['InstanceStatuses']:
            print("EC2 System status:%s" %instance['SystemStatus']['Status'])
            if instance['SystemStatus']['Status'] == 'initializing':
                continue
            elif instance['SystemStatus']['Status'] == 'ok':
                health_check = True
 
                break
        print("Health Check:%s" %health_check)
        if health_check:
            break
        else:
            # wait for a min for next iteration
            time.sleep(60)
            start_time += 60 
            continue
   
    if not health_check:
        return {
            'statusCode': 400,
            'body': "The Instance %s health check failed" %instances["Instances"][0]["InstanceId"]
        }
   
    return instances["Instances"][0]["InstanceId"]
   

def lambda_handler(event, context):
   try:
        instanceId = create_instance()   
        return {
            'statusCode': 200,
            'body': json.dumps({'instance_id': instanceId})
        }
   except Exception as e:
        return {
            'statusCode': 400,
            'body': 'Creation of EC2 instance failed:%s' %e
        }
   
 
 