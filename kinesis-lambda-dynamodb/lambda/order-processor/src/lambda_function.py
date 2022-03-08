import boto3
from base64 import b64decode
from datetime import datetime as dt

ddb = boto3.Session(region_name='eu-west-1').client(
    'dynamodb',
    aws_access_key_id='localstack',
    aws_secret_access_key='localstack',
    endpoint_url='http://localstack:4566'
)

def decode_base64(string_to_decode):
    #if type(string_to_decode) is not bytes:
    #    string_to_decode = string_to_decode.encode('utf-8')
    response = b64decode(string_to_decode).decode('utf-8')
    return response

def write_to_dynamodb(hashkey, event_id, value):
    response = ddb.put_item(
        TableName='orders',
        Item={
            'OrderID': {'S': hashkey},
            'EventID': {'S': event_id},
            'OrderData': {'S': value},
            'Timestamp': {'S': dt.now().strftime("%Y-%m-%dT%H:%M:%S")}
        }
    )
    return response

def lambda_handler(event, request):
    for record in event['Records']:
        event_id = record['eventID']
        hashkey = event_id[-15:-1]
        value = decode_base64(record['kinesis']['data'])
        item = write_to_dynamodb(hashkey, event_id, value)
        print('EventID: {}, HashKey: {}, Data: {}'.format(event_id, hashkey, value))
        print('DynamoDB RequestID: {}'.format(item['ResponseMetadata']['RequestId']))
    #print(event)
    return event
