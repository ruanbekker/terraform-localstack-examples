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
```

Make a GET request against API GW:

```
$ curl http://localhost:4566/restapis/yk7pecb78d/dev/_user_request_/test        
Hello World!%                                                                        
```
