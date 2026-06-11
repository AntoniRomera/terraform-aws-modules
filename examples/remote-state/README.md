# Remote state example (S3 + DynamoDB lock)

Demonstrates storing Terraform state in an **S3 bucket** with a **DynamoDB
lock table**. Because the backend resources can't be created in the same state
that uses them, this is a two-step flow:

```
bootstrap/  (local state)  -->  creates S3 bucket + DynamoDB table
   |
   v
.  (this dir, S3 backend)  -->  uses them to store its state
```

## Step 1 — bootstrap the backend

```bash
cd bootstrap
terraform init
terraform apply \
  -var="bucket_name=my-unique-tfstate-bucket" \
  -var="lock_table_name=my-tfstate-lock" \
  -var="region=eu-west-1"

# Note the outputs:
terraform output
```

Bucket names are globally unique — pick your own. State for the bootstrap stack
itself lives locally (chicken-and-egg), so keep `bootstrap/terraform.tfstate`
safe or import it later.

## Step 2 — use the backend

`backend.tf` contains placeholder names. Supply the real ones at init time so
nothing real is committed:

```bash
cd ..
terraform init \
  -backend-config="bucket=my-unique-tfstate-bucket" \
  -backend-config="dynamodb_table=my-tfstate-lock" \
  -backend-config="key=remote-state-example/terraform.tfstate" \
  -backend-config="region=eu-west-1"

terraform apply
```

State now lives in S3 and concurrent runs are locked via DynamoDB.

## Cleanup

```bash
terraform destroy                 # this stack
cd bootstrap && terraform destroy # the backend (empty the bucket first)
```
