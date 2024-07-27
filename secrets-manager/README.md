# secretsmanager-example

Example of using Terraform with Localstack to provision a SecretsManager resource.

## Usage

Deploy localstack:

```bash
pushd ../
make up
popd
```

Deploy the secret:

```bash
terraform init
terraform apply -auto-aprove
```

View the secret:

```bash
aws --endpoint-url=http://localhost:4566 secretsmanager get-secret-value --secret-id example-secret --region eu-west-1
{
    "ARN": "arn:aws:secretsmanager:eu-west-1:000000000000:secret:example-secret-sDfusx",
    "Name": "example-secret",
    "VersionId": "terraform-20240727131112322900000002",
    "SecretString": "5DPEo*mtHaLPnaNZ",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": 1722085872.0
}
```
