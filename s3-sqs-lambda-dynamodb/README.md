# s3-sqs-lambda-dynamodb

## About

Components:
- S3 Bucket
- SQS Queue
- Lambda Function
- DynamoDB Table

1. When a json object arrives on s3 a notification is triggered to send it to sqs
2. The lambda function is triggered when a item is added to SQS and consumes the data
3. The lambda function reads the data in the json object key and writes it to DynamoDB


## Walkthrough

Lambda Event from SQS:

```
localstack    | > START RequestId: ead233f7-12f8-15f3-c5c4-061388ed806c Version: $LATEST
localstack    | > {'Records': [{'body': '{"Records": [{"eventVersion": "2.1", "eventSource": "aws:s3", "awsRegion": "eu-west-1", "eventTime": "2022-03-01T22:02:31.030Z", "eventName": "ObjectCreated:Put", "userIdentity": {"principalId": "AIDAJDPLRKLG7UEXAMPLE"}, "requestParameters": {"sourceIPAddress": "127.0.0.1"}, "responseElements": {"x-amz-request-id": "19108f27", "x-amz-id-2": "eftixk72aD6Ap51TnqcoF8eFidJG9Z/2"}, "s3": {"s3SchemaVersion": "1.0", "configurationId": "testConfigRule", "bucket": {"name": "my-bucket-000000000000", "ownerIdentity": {"principalId": "A3NL1KOZZKExample"}, "arn": "arn:aws:s3:::my-bucket-000000000000"}, "object": {"key": "orders/2022/03/01/file.json", "size": 51, "eTag": "\\"d9010ae140b4fd2d75578c7210449f27\\"", "versionId": null, "sequencer": "0055AED6DCD90281E5"}}}]}', 'receiptHandle': 'vadmxpgzrigofwxnfskctmaivdwgqgnifywarqatzntnbjvkcsmenveddffplqyeayewuvdfkyvplzpudognwwztucpruexwqqwiddbjurgdffdneawpxqxswyitwbrghnuxrhhpqkbemggjelzlldupirdevifjmfbvkqhioefbkrtuztmqatqvm', 'md5OfBody': '6d064eca382e1deff9230c604baad820', 'eventSourceARN': 'arn:aws:sqs:eu-west-1:000000000000:orders-queue', 'eventSource': 'aws:sqs', 'awsRegion': 'eu-west-1', 'messageId': '6162988a-3a8b-e587-fdcd-68903f98a845', 'attributes': {}, 'messageAttributes': {}, 'md5OfMessageAttributes': None, 'sqs': True}]}
localstack    | > END RequestId: ead233f7-12f8-15f3-c5c4-061388ed806c
localstack    | > REPORT RequestId: ead233f7-12f8-15f3-c5c4-061388ed806c        Init Duration: 107.05 ms        Duration: 14.63 ms        Billed Duration: 100 ms Memory Size: 1536 MB    Max Memory Used: 24 MB
```

Deploy Infra:

```bash
$ pushd ../
$ make up
$ popd
$ terraform apply -auto-approveaws_lambda_function.order_processor: Refreshing state... [id=order-processor]

Apply complete! Resources: 1 added, 1 changed, 1 destroyed.

Outputs:

dynamodb_table = "orders-table"
lambda_function = "order-processor"
s3_bucket = "my-bucket-000000000000"
sqs_queue = "orders-queue"
```

Create `file.json`:

```json
{"order_id": "20220301_001", "order_value": 12.30}
```

Put to S3:

```bash
$ aws --profile localstack --endpoint-url http://localhost:4566 s3 cp file.json s3://my-bucket-000000000000/orders/2022/03/01/file.json
upload: ./file.json to s3://my-bucket-000000000000/orders/2022/03/01/file.json
```

View logs:

```bash
$ docker-compose -f logs
...
localstack    | 2022-03-01T22:56:06:DEBUG:localstack.services.awslambda.lambda_executors: Lambda arn:aws:lambda:eu-west-1:000000000000:function:order-processor result / log output:
localstack    | {"statusCode":200,"body":{"ConsumedCapacity":{"TableName":"orders-table","CapacityUnits":1.0},"ResponseMetadata":{"RequestId":"ced062ff-8163-482f-ba03-0431c17e3522","HTTPStatusCode":200,"HTTPHeaders":{"content-type":"application/x-amz-json-1.0","content-length":"69","connection":"close","x-amz-crc32":"3899374354","x-amzn-requestid":"ced062ff-8163-482f-ba03-0431c17e3522","access-control-allow-origin":"*","access-control-allow-methods":"HEAD,GET,PUT,POST,DELETE,OPTIONS,PATCH","access-control-allow-headers":"authorization,content-type,content-length,content-md5,cache-control,x-amz-content-sha256,x-amz-date,x-amz-security-token,x-amz-user-agent,x-amz-target,x-amz-acl,x-amz-version-id,x-localstack-target,x-amz-tagging,amz-sdk-invocation-id,amz-sdk-request","access-control-expose-headers":"x-amz-version-id","date":"Tue, 01 Mar 2022 22:56:06 GMT","server":"hypercorn-h11"},"RetryAttempts":0}}}
localstack    | > START RequestId: cbb481eb-963f-1e4b-9cac-4ecad11b853b Version: $LATEST
localstack    | > END RequestId: cbb481eb-963f-1e4b-9cac-4ecad11b853b
localstack    | > REPORT RequestId: cbb481eb-963f-1e4b-9cac-4ecad11b853b        Init Duration: 428.72 ms        Duration: 237.41 ms       Billed Duration: 300 ms Memory Size: 1536 MB    Max Memory Used: 40 MB
```

View DynamoDB Table:

```bash
$ aws --profile localstack --endpoint-url http://localhost:4566 dynamodb scan --table-name orders-table
{
    "Items": [
        {
            "OrderID": {
                "S": "20220301_001"
            },
            "Timestamp": {
                "S": "2022-03-01T22:56:17"
            },
            "OrderValue": {
                "S": "12.3"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 1,
    "ConsumedCapacity": null
}
```
