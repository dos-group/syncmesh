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
- roles/resourcemanager.projectIamAdmin on the destination project (to grant write permissions for logsink service
  account)
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
sudo journalctl -u google-startup-scripts.service -f | grep startup-script

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

### Queries

A query fetching a document with a specific ID:

```json
{
  "query": "{sensor(_id: \"60e0615f39dc2d7833bdb9c9\"){temperature}}",
  "database": "demo",
  "collection": "sensors",
  "request_type": "collect"
}
```

An example query for a specific time range (start_time and end_time are required):

```json
{
  "query": "{sensors(limit: 10, start_time: \"2017-06-26T00:00:00Z\", end_time: \"2017-07-01T00:00:00Z\"){temperature humidity timestamp}}",
  "database": "demo",
  "collection": "sensors",
  "request_type": "collect"
}
```

A query for collection with external nodes

```json
{
  "query": "{sensors(limit: 1, start_time: \"2017-06-26T00:00:00Z\", end_time: \"2017-08-01T00:00:00Z\"){temperature humidity timestamp}}",
  "database": "syncmesh",
  "collection": "sensor_data",
  "request_type": "collect",
  "external_nodes": [
    "http://some.random.ip:8080/function/syncmesh-fn"
  ]
}
```

### Querying with variables

You can also use variables instead of writing everything into the query. An advantage of doing this is you have shorter
lines in the request, you also don't need to escape strings. An example for querying a document with an ID:

```json
{
  "query": "query sensor($id: ID!){sensor(_id: $id){temperature}}",
  "database": "demo",
  "variables": {
    "id": "60e9a27ec17cbf8c64ee8796"
  },
  "collection": "sensors",
  "request_type": "collect"
}
```

### Mutations

Mutations are also possible with GraphQL + Syncmesh. Here's how you delete an entry:

```json
{
  "query": "mutation{deleteSensor(_id: \"60e0666c6f1faa4d3821e3a0\"){temperature}}",
  "database": "syncmesh",
  "collection": "sensor_data"
}
```

You can also insert your own data like this:

```json
{
  "query": "mutation{addSensors(sensors: [{pressure: 1, temperature: 2, humidity: 23, lat: 23.123, lon: 23.232, timestamp: \"2017-06-26T00:00:00Z\"}])}",
  "database": "demo",
  "collection": "sensors"
}
```

The general request has the following parameters:

- "query": Contains the GraphQL query
- "database": Specifies the mongoDB database to query on
- "collection": Specifies the mongoDB collection to query on
- "request_type": Specifies the SyncMesh request type. Currently, "aggregate" and "collect" are supported.
- "external_nodes": list of all addressable external SyncMesh nodes for data collection/aggregation

## Libraries and packages used

- OpenFaaS
- Graphql-Go
- MongoDB
- Go Mongo Driver

## Good Reads

https://willschenk.com/articles/2021/setting_up_services_with_faasd/
