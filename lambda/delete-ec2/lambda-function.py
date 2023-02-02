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
 
def delete_instance(instance_id):
    result = "Instance not terminated"
    print("Terminating the instance...")
    response = ec2_client.terminate_instances(
        InstanceIds=[instance_id]
        )
    print(response)
    if 'TerminatingInstances' in response:
        result = f"Instance {instance_id} is getting terminated"
    return result
   

def lambda_handler(event, context):
   try:
        input = json.loads(event['body'])
        instance_id = input['instance_id']
        print(f"Instance Id for deletion {instance_id}")
        response = delete_instance(instance_id)
        print(f"Response from deletion of instance {response}") 
        return {
            'statusCode': 200,
            'body': json.dumps({'message': response})
        }
   except Exception as e:
        return {
            'statusCode': 400,
            'body': 'Deletion of EC2 instance failed:%s' %e
        }
   
 
 