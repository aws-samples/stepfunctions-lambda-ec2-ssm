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
import time
import boto3
import os
 
ssm_obj = boto3.client('ssm',region_name=os.environ['AWS_REGION'])
 
def lambda_handler(event, context):
    input = json.loads(event['body'])
    instance_id = input['instance_id']
    script_cmd = os.environ['script_cmd']
    script_bucket_uri = os.environ['script_bucket_uri']
    cloudwatch_log_group = os.environ['cloud_watch_log_group']
    output_bucket_name = os.environ['cmd_output_bucket_name']
    output_bucket_prefix = os.environ['cmd_output_bucket_prefix']
    print(instance_id)
   
    max_time = 600
    start_time = 0
    ssm_instance = False
    while start_time <= max_time:
        # Check whether the instance is seen by SSM
        instance_list = ssm_obj.describe_instance_information()
        print(instance_list)
        for instance in instance_list['InstanceInformationList']:
            print("Instance Id in SSM:%s" %instance['InstanceId'])
            if instance['InstanceId'] == instance_id:
                print("Instance seen by SSM")
                ssm_instance=True
                break
        if ssm_instance:
            break
        else:
            # Wait for a min before checking again.
            time.sleep(60)
            start_time += 60
   
    # RUN SSM
    if ssm_instance:
        ssm_response = ssm_obj.send_command(
            InstanceIds=[instance_id], 
            DocumentName='AWS-RunRemoteScript',
            TimeoutSeconds=300,
            Parameters={"sourceType": ["S3"], "sourceInfo": ["{\"path\": \"%s\"}" %script_bucket_uri], "commandLine": [script_cmd]},
            OutputS3BucketName=output_bucket_name,
            OutputS3KeyPrefix=output_bucket_prefix,
            CloudWatchOutputConfig={'CloudWatchLogGroupName': cloudwatch_log_group,'CloudWatchOutputEnabled': True}
            )        
        print(ssm_response)
        command_id = ssm_response['Command']['CommandId']
        print(command_id)
       
        return {
            'statusCode': 200,
            'body': json.dumps({'command_id': command_id, 'instance_id': instance_id})
        }
    else:
        return {
            'statusCode': 400,
            'body': "The instance %s is not yet part of SSM" %instance_id
        }
 