
# S3 Bucket Localstack Terraform Example

Run localstack:

```
$ docker-compose up -d
```

Deploy Infrastructure

```
$ terraform init 
$ terraform plan
$ terraform apply -auto-approve
```

List Buckets:

```
$ aws --endpoint-url http://localhost:4566 --region eu-west-1 s3 ls /
```
