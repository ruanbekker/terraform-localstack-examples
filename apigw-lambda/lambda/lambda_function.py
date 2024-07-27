import os
import uuid
import json
import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

dynamodb = boto3.client('dynamodb', endpoint_url='http://localstack:4566')

def lambda_handler(event, context):
    logger.debug("Event: %s", json.dumps(event))
    table_name = os.environ['DYNAMODB_TABLE_NAME']
    response = None

    try:
        if event['httpMethod'] == 'POST' and event['path'] == '/message':
            # Access payload
            payload = json.loads(event['body'])
            logger.debug("Payload: %s", payload)
            item_id = str(uuid.uuid4())
            message = payload.get('key', 'default_message')
            
            # Write item to table
            dynamodb.put_item(
                TableName=table_name,
                Item={
                    'ItemID': {'S': item_id},
                    'message': {'S': message}
                }
            )
            response = {
                'item_id': item_id,
                'message': message
            }
        elif event['httpMethod'] == 'GET' and event['path'] == '/message':
            result = dynamodb.scan(TableName=table_name)
            items = result.get('Items', [])
            response = [
                {
                    'item_id': item['ItemID']['S'],
                    'message': item['message']['S']
                } for item in items
            ]
        elif event['httpMethod'] == 'GET' and event['pathParameters'] and 'item_id' in event['pathParameters']:
            item_id = event['pathParameters']['item_id']
            
            # Get item from table
            result = dynamodb.get_item(
                TableName=table_name,
                Key={
                    'ItemID': {'S': item_id}
                }
            )
            if 'Item' in result:
                response = {
                    'item_id': item_id,
                    'message': result['Item']['message']['S']
                }
            else:
                response = {
                    'error': 'Item not found'
                }
        elif event['httpMethod'] == 'DELETE' and event['pathParameters'] and 'item_id' in event['pathParameters']:
            item_id = event['pathParameters']['item_id']
            
            # Delete item from table
            dynamodb.delete_item(
                TableName=table_name,
                Key={
                    'ItemID': {'S': item_id}
                }
            )
            response = {
                'message': f'Item with id {item_id} deleted'
            }
        elif event['httpMethod'] == 'PUT' and event['pathParameters'] and 'item_id' in event['pathParameters']:
            item_id = event['pathParameters']['item_id']
            payload = json.loads(event['body'])
            logger.debug("Payload: %s", payload)
            message = payload.get('key', 'default_message')
            
            # Update item in table
            dynamodb.update_item(
                TableName=table_name,
                Key={
                    'ItemID': {'S': item_id}
                },
                UpdateExpression="set message = :m",
                ExpressionAttributeValues={
                    ':m': {'S': message}
                },
                ReturnValues="UPDATED_NEW"
            )
            response = {
                'message': f'Item with id {item_id} updated to {message}'
            }
        else:
            response = {
                'message': 'Invalid request'
            }

        return {
            'isBase64Encoded': False,
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps(response)
        }
    except Exception as e:
        logger.error("Error: %s", str(e))
        return {
            'isBase64Encoded': False,
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }

