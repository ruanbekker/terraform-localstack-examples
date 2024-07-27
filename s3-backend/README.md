# Terraform S3 Backend

S3 Backend for State and DynamoDB Table for State Locking.

## Deploy Infra

Run localstack:

```bash
$ pushd ../
$ make up
$ popd
```

Deploy the S3 Bucket and DynamoDB Table:

```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "terraform-state"
dynamodb_table_name = "terraform-state-lock"s
```

## List Resources

Using the aws cli, list the s3 buckets:

```
$ aws  --endpoint-url="http://localhost:4566" --region eu-west-1 s3 ls /

2022-02-19 17:58:47 terraform-state
```

Then list the DynamoDB Tables:

```
$ aws --endpoint-url="http://localhost:4566" --region eu-west-1 dynamodb list-tables
{
    "TableNames": [
        "terraform-state-lock"
    ]
}
```

## Chicken and the Egg Problem

You will notice that our state resides locally, as we have not defined a state backend and therefore terraform defaults to local storage:

```
$ ls | grep state
terraform.tfstate
```

Since we now have infrastructure for our state, we can migrate the local storage state to our remote state on s3, we can do that by adding the backend to the `main.tf` (a full example of the main.tf can be found in `example/main.tf`):

```
...

terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "terraform-state/terraform.tfstate"
    region                      = "eu-west-1"
    endpoint                    = "http://localhost:4566"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
    dynamodb_table              = "terraform-state-lock"
    dynamodb_endpoint           = "http://localhost:4566"
    encrypt                     = true
  }
}

...
```

Then we need to reinitialize to migrate our local storate to s3:

```
$ terraform init

Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v4.2.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

As we can see our state has been migrated:

```
$ aws --endpoint-url="http://localhost:4566" --region eu-west-1 s3 ls s3://terraform-state/terraform-state/
2022-02-19 18:11:16       5635 terraform.tfstate
```

We can then remove the local state:

```
$ rm -rf terraform.tfstate*
```

And verify by doing a plan:

```
$ terraform plan
aws_s3_bucket.state: Refreshing state... [id=terraform-state]
aws_dynamodb_table.state_lock: Refreshing state... [id=terraform-state-lock]
aws_s3_bucket_public_access_block.state: Refreshing state... [id=terraform-state]
aws_s3_bucket_server_side_encryption_configuration.sse: Refreshing state... [id=terraform-state]

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your configuration and the remote system(s). As a result, there are no actions to take.
```

## Using S3 Backend

For any infrustructure's state to be stored on S3, you will need the following:

```
terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "terraform-state/terraform.tfstate"
    region                      = "eu-west-1"
    endpoint                    = "http://localhost:4566"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
    dynamodb_table              = "terraform-state-lock"
    dynamodb_endpoint           = "http://localhost:4566"
    encrypt                     = true
  }
}
```

But remember to seperate the infra with the `key` on S3 of choice, but that is up to you how you would like to use it.
