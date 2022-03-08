#!/usr/bin/env python3

import boto3

kinesis = boto3.Session(region_name='eu-west-1').client('kinesis', aws_access_key_id='localstack', aws_secret_access_key='localstack', endpoint_url='http://localhost:4566')
response = kinesis.put_record(StreamName='orders_processor', Data=b'chips', PartitionKey='1')
print(response)
