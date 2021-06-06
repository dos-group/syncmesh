# Syncmesh

## Infrastructure

Provision the test ressources via these commands:

```terraform
# Initialize
terraform init
# Create a project and your credentials:
# https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build#set-up-gcp
terraform plan --out tfplan
terraform apply tfplan

# Destroy
terraform destroy
```
