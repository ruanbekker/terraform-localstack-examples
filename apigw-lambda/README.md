# API Gateway and Lambda

## Localstack

Boot localstack:

```
$ docker-compose up -d
```

## Usage

Deploy the infrastructure on localstack with terraform:

```
$ terraform init
$ terraform plan
$ terraform apply

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

apigw_id = "fwwksnj2b9"
apigw_message_path = "/message"
apigw_root_path = "/{proxy+}"
message_invoke_url = "http://localhost:4566/restapis/fwwksnj2b9/dev/_user_request_/message"
root_invoke_url = "http://localhost:4566/restapis/fwwksnj2b9/dev/_user_request_/{proxy+}"
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

```
$ curl -XGET http://localhost:4566/restapis/fwwksnj2b9/dev/_user_request_/list
welcome
```

Make a POST request against API GW:

```
$ curl -XPOST http://localhost:4566/restapis/fwwksnj2b9/dev/_user_request_/message -d '{"foo": "bar"}'
{"foo": "bar"}
```
