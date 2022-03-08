# kinesis-lambda-dynamodb

Kinesis, Lambda and DynamoDB Terraform Localstack Example

## Architectural Diagram

<img width="1505" alt="image" src="https://user-images.githubusercontent.com/567298/154531600-3b7f9d32-1f0b-452b-8670-f2f9c11423e7.png">

1. AWS CLI to do a `PutRecord` with the data value "pizza" base64 encoded
2. The Kinesis Stream has a Event Trigger to Invoke the Lambda Function
3. The Lambda Function receives the data in the event body and writes to DynamoDB
4. AWS CLI to do a `Scan` on DynamoDB to preview the data in the table

## Requirements

1. AWS CLI
2. Python and Pip
3. Terraform
4. Docker Compose

## Usage

Boot localstack:

```bash
$ docker-compose up -d
```

Create the deployment package for Lambda:

```bash
$ ./zip.sh
```

Provision Infrastructure:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

To use the awscli we need to use `--endpoint-url http://localhost:4566`, but I will alias it to `awslocal` for simplicity:

```bash
$ alias awslocal="aws --endpoint-url http://localhost:4566 --region eu-west-1"
```

Now we should be able to list our resources:

```bash
$ awslocal dynamodb list-tables
{
    "TableNames": [
        "orders"
    ]
}
```

Put a record to the Kinesis Stream:

```bash
$ awslocal kinesis put-record --stream-name orders_processor --partition-key 123 --data $(echo -n "pizza" | base64)
{
    "ShardId": "shardId-000000000000",
    "SequenceNumber": "49626853442679825006635798069828080735600763790688256002"
}
```

View the logs from localstack:

```bash
$ docker logs -f localstack

> START RequestId: 29eceff2-c4c1-17d0-a874-27f0dd913a86 Version: $LATEST
> EventID: shardId-000000000000:49626853442679825006635798069828080735600763790688256002, HashKey: 76379068825600, Data: pizza
> DynamoDB RequestID: 974099a3-2f49-4f0f-b7e4-2c53b07db028
> END RequestId: 29eceff2-c4c1-17d0-a874-27f0dd913a86
> REPORT RequestId: 29eceff2-c4c1-17d0-a874-27f0dd913a86	Init Duration: 221.72 ms	Duration: 34.28 ms	Billed Duration: 100 ms	Memory Size: 1536 MB	Max Memory Used: 40 MB
```

Scan the DynamoDB Table:

```bash
$ awslocal dynamodb scan --table-name orders
{
    "Items": [
        {
            "EventID": {
                "S": "shardId-000000000000:49626853442679825006635798069828080735600763790688256002"
            },
            "OrderData": {
                "S": "pizza"
            },
            "OrderID": {
                "S": "76379068825600"
            },
            "Timestamp": {
                "S": "2022-02-17T16:29:36"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 1,
    "ConsumedCapacity": null
}
```

GetItem using DynamoDB:

```bash
$ awslocal dynamodb get-item --table-name orders --key '{"OrderID": {"S": "76379068825600"}}'
{
    "Item": {
        "EventID": {
            "S": "shardId-000000000000:49626853442679825006635798069828080735600763790688256002"
        },
        "OrderData": {
            "S": "pizza"
        },
        "OrderID": {
            "S": "76379068825600"
        },
        "Timestamp": {
            "S": "2022-02-17T16:29:36"
        }
    }
}
```

## Code Structure

```bash
.
├── LICENSE
├── NOTES.md
├── README.md
├── docker-compose.yml                 - Localstack
├── iac
│   └── main.tf                        - AWS Infrastructure via Terraform
├── lambda
│   └── order-processor                - Lambda Function Folder
│       ├── deployment_package.zip     - Location where the zip.sh will package the lambda and dependencies for Terraform
│       ├── deps                       - Lambda is using Python Runtime and the packaging will reference the requirements.txt
│       │   └── requirements.txt
│       ├── packages                   - The requirement packages will be installed to this directory by the zip.sh
│       ├── src
│           └── lambda_function.py     - Lambda Function Source Code
├── put_record.py                      - Python Equivalent of doing a PutRecord to Kinesis
└── zip.sh                             - Script that will loop through each function folder, zip the deployment package
```
