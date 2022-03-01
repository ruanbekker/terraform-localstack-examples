import json
import boto3
from datetime import datetime as dt
#from decimal import Decimal

def parse_event(payload):
    for record in payload['Records']:
        body = json.loads(record['body'])
        bucket = body['Records'][0]['s3']['bucket']['name']
        key = body['Records'][0]['s3']['object']['key']

    s3 = boto3.client(
        's3', 
        endpoint_url='http://localstack:4566', 
        aws_access_key_id = 'localstack', 
        aws_secret_access_key = 'localstack'
    )
    response = s3.get_object(Bucket=bucket, Key=key)
    object_content = json.loads(response['Body'].read().decode('utf-8'))

    return object_content

def write_to_dynamodb(object_content):
    ddb = boto3.client(
        'dynamodb', 
        endpoint_url='http://localstack:4566', 
        aws_access_key_id = 'localstack', 
        aws_secret_access_key = 'localstack'
    )
    response = ddb.put_item(
        TableName='orders-table',
        Item={
            'OrderID': {'S': object_content['order_id']},
            'OrderValue': {'S': str(object_content['order_value'])},
            'Timestamp': {'S': dt.now().strftime("%Y-%m-%dT%H:%M:%S")}
        }
    )
    return response

def lambda_handler(event, context):
    object_data = parse_event(event)
    response = write_to_dynamodb(object_data)
    return {
        'statusCode': 200,
        'body': response
    }