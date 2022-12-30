# GitHub events -> AWS EventBridge

Experiment to deliver GitHub events (webhook) to AWS EventBridge and route them to several targets.

## Targets

- CloudWatch LogGruops
- Lambda
- S3 via Firehose delivery stream

## Usages

### Tools

- Docker or Node to build the Lambda's
- Terraform for deployment

### Setup

1. Inspect the code, which is always wise to do.
2. Build the Lambda's (`./build.sh`) or run per Lambda (`yarn run dist`.)
3. Update the locals in `main.tf`
4. Run `terraform apply`
5. Define a webhook for example via an App in GitHub. 

### Cleanup

Just run `terraform destroy` and remove the webhook / App.
