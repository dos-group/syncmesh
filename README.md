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

Terrafom credentials roles:

- roles/resources.editor
- roles/storage.admin
- roles/bigquery.admin
- roles/logging.configWriter on the logsink's project, folder, or organization (to create the logsink)
- roles/resourcemanager.projectIamAdmin on the destination project (to grant write permissions for logsink service account)
- roles/serviceusage.serviceUsageAdmin on

```terraform
# Initialize
terraform init
# Create a project and your credentials:
# https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build#set-up-gcp
terraform plan --out tfplan
terraform apply tfplan

# Find one of the IPs and connect to the instance:
ssh -L 8080:ip:8080 username@ip

# See Startup Script Log
sudo journalctl -u google-startup-scripts.service -t | grep startup-script

# Destroy
terraform destroy
```

## Working on Nodes

```bash
# Find out the password or login
sudo cat /var/lib/faasd/secrets/basic-auth-password
sudo cat /var/lib/faasd/secrets/basic-auth-password | faas-cli login -s

# get logs to
sudo journalctl -f | grep mongo


```

## How to use

to perform a query on the deployed function, you need to send a JSON request.

```

A query fetching a document with a specific ID:

```
{
"query": "{sensor(_id: \"60e0615f39dc2d7833bdb9c9\"){temperature}}",
"database": "demo",
"collection": "sensors",
"request_type": "collect"
}
```

An example query for a specific time range:

```
{
"query": "{sensors(limit: 10, start_time: \"2017-06-26T00:00:00Z\", end_time: \"2017-07-01T00:00:00Z\"){temperature humidity timestamp}}",
"database": "demo",
"collection": "sensors",
"request_type": "collect"
}
```

While sensor2 in that instance might have come from one of the other specified external nodes, thanks to "collect" as a request type.

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

## Good Reads

https://willschenk.com/articles/2021/setting_up_services_with_faasd/
