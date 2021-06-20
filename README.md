# Syncmesh

## Prerequisites

- minikube
- kubectl
- helm

## Scripts

- `minikube_node_setup.sh`: sets up an openfaas instance in the minikube cluster and also mongodb in the same namespace
- `get_openfaas_password.sh`: fetches saves, and outputs the openfaas gateway password
- `functions_deployer.sh`: deploys functions

## Forwarding

Either use [kube-forwarder](https://www.electronjs.org/apps/kube-forwarder) or do:

`kubectl port-forward svc/gateway -n openfaas 8080:8080`

## Infrastructure

Provision the test ressources via these commands:

```terraform
# Initialize
terraform init
# Create a project and your credentials:
# https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build#set-up-gcp
terraform plan --out tfplan
terraform apply tfplan

# Find one of the IPs and connect to the instance:
ssh -L 8080:ip:8080 username@ip

# Find out the password
sudo cat /var/lib/faasd/secrets/basic-auth-password

# Destroy
terraform destroy
```

## How to use
to perform a query on the deployed function, you need to send a JSON request of a type similar to this:
```
{
"query": "{getAllUsers{name}}",
"database": "demo",
"collection": "users"
"request_type": "aggregate"
"external_nodes": ["some_ip_1", "some_ip_2", "some_ip_3"]
}
```
It has the following parameters:
- "query": Contains the GraphQL query
- "database": Specifies the mongoDB database to query on
- "collection": Specifies the mongoDB collection to query on
- "request_type": Specifies the SyncMesh request type. Currently, "aggregate" and "collect" are supported.
- "external": list of all addressable external SyncMesh nodes for data collection/aggregation

## Libraries and packages used
- OpenFaaS
- Graphql-Go
- MongoDB
- Go Mongo Driver
