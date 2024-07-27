# API Gateway and Lambda

## Localstack

Boot localstack:

```bash
pushd ../
docker-compose up -d # or `make up`
popd
```

## Usage

Deploy the infrastructure on localstack with terraform:

```bash
terraform init
terraform apply -auto-approve
```

You should see something like this:

```
Apply complete! Resources: 23 added, 0 changed, 0 destroyed.

Outputs:

apigw_id = "vi0bygtqxi"
apigw_message_path = "/message"
message_invoke_url = "http://localhost:4566/restapis/vi0bygtqxi/dev/_user_request_/message"
```

The basic lambda logic:

```python
def lambda_handler(event, context):
    if event['path'] == '/message':
        payload = json.loads(event['body'])
    else:
        payload = 'welcome'
    return {
        'statusCode': 200,
        'body': payload
    }
```

Make a GET request against API GW:

```bash
curl -H 'Content-Type: application/json' -XGET "http://localhost:4566/restapis/vi0bygtqxi/dev/_user_request_/message"
[]
```

Make a POST request against API GW:

```bash
curl -H 'Content-Type: application/json' -XPOST "http://localhost:4566/restapis/vi0bygtqxi/dev/_user_request_/message" -d '{"key": "some value"}'
{"item_id": "8e24a1b6-3bd9-4306-b22a-86dc26f86bb3", "message": "some value"}
```

Make a GET to retrieve information about the item:

```bash
curl -H 'Content-Type: application/json' -XGET "http://localhost:4566/restapis/vi0bygtqxi/dev/_user_request_/message/8e24a1b6-3bd9-4306-b22a-86dc26f86bb3"
{"item_id": "8e24a1b6-3bd9-4306-b22a-86dc26f86bb3", "message": "some value"}
```

Make a PUT request to update the content in DynamoDB:

```bash
curl -H 'Content-Type: application/json' -XPUT "http://localhost:4566/restapis/vi0bygtqxi/dev/_user_request_/message/8e24a1b6-3bd9-4306-b22a-86dc26f86bb3" -d '{"key": "new value"}'
{"message": "Item with id 8e24a1b6-3bd9-4306-b22a-86dc26f86bb3 updated to new value"}
```

Make a DELETE request to remove the item from DynamoDB:

```bash
curl -H 'Content-Type: application/json' -XDELETE "http://localhost:4566/restapis/vi0bygtqxi/dev/_user_request_/message/8e24a1b6-3bd9-4306-b22a-86dc26f86bb3"
{"message": "Item with id 8e24a1b6-3bd9-4306-b22a-86dc26f86bb3 deleted"}
```

To destroy the infrastructure:

```bash
terraform destroy
```
