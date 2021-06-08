# Syncmesh

## Prerequisites

- minikube
- kubectl
- helm

## Scripts

- `minikube_node_setup.sh`: sets up an openfaas instance in the minikube cluster and also mongodb in the same namespace
- `get_openfaas_password.sh`: fetches saves, and outputs the openfaas gateway password

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
