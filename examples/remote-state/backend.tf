###############################################################################
# Remote state backend: S3 for state, DynamoDB for locking.
#
# The bucket and lock table must already exist — create them with the
# ./bootstrap configuration first (it cannot live in this same state).
#
# Values below are PLACEHOLDERS. Override at init time with -backend-config so
# you don't commit real names:
#
#   terraform init \
#     -backend-config="bucket=my-tfstate-bucket" \
#     -backend-config="dynamodb_table=my-tfstate-lock" \
#     -backend-config="key=full-stack/terraform.tfstate" \
#     -backend-config="region=eu-west-1"
###############################################################################

terraform {
  backend "s3" {
    bucket         = "REPLACE_ME_tfstate_bucket"
    key            = "remote-state-example/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "REPLACE_ME_tfstate_lock"
    encrypt        = true
  }
}
