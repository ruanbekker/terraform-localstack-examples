import json

def lambda_handler(event, context):
    if event['path'] == '/message':
        payload = json.loads(event['body'])
    else:
        payload = 'welcome'
    return {
        'statusCode': 200,
        'body': payload
    }
