# Syncmesh

## Prerequisites

- minikube
- kubectl
- helm
- terraform

## Scripts

- `minikube_node_setup.sh`: sets up an openfaas instance in the minikube cluster and also mongodb in the same namespace
- `get_openfaas_password.sh`: fetches saves, and outputs the openfaas gateway password
- `functions_deployer.sh`: deploys functions

## Forwarding

Either use [kube-forwarder](https://www.electronjs.org/apps/kube-forwarder) or do:

`kubectl port-forward svc/gateway -n openfaas 8080:8080`

## Infrastructure

To set up the credentials [follow this guide](https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build#set-up-gcp), but additionally grant the folllowing roles:

- roles/resources.editor
- roles/storage.admin
- roles/bigquery.admin
- roles/logging.configWriter on the logsink's project, folder, or organization (to create the logsink)
- roles/resourcemanager.projectIamAdmin on the destination project (to grant write permissions for logsink service
  account)
- roles/serviceusage.serviceUsageAdmin on

Provision the test ressources via these commands:

```terraform
# Initialize
terraform init
terraform plan --out tfplan
terraform apply tfplan

terraform apply --var-file=experiment-3-syncmesh.tfvars

# Find one of the IPs and connect to the instance:
ssh -L 8080:ip:8080 username@ip

# Follow Startup Script Log
sudo journalctl -u google-startup-scripts.service -f | grep startup-script
# See Startup Script Log
sudo journalctl -u google-startup-scripts.service | grep startup-script

# Destroy
terraform destroy
```

# Experiments

Run the terraform the Terraform script for either `baseline`, `syncmesh` or `advanced-mongo` scenario:

```bash
terraform apply -var-file ./experiment-3-baseline.tfvars
```

Get the data after each run by running the `Main` and `monitoring` notebook.

```bash
jupyter nbconvert --execute --to notebook --inplace --allow-errors --ExecutePreprocessor.timeout=-1 Main.ipynb  --output Test_main.ipynb
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
  "database": "syncmesh",
  "collection": "sensor_data",
  "request_type": "collect"
}
```

An example query for a specific time range:

```json
{
  "query": "{sensors(limit: 10, start_time: \"2017-06-26T00:00:00Z\", end_time: \"2017-07-01T00:00:00Z\"){temperature humidity timestamp}}",
  "database": "syncmesh",
  "collection": "sensor_data",
  "request_type": "collect"
}
```

A new aggregation query:

```json
{
  "query": "{sensorsAggregate(start_time: \"2017-06-26T00:00:00Z\", end_time: \"2017-07-01T00:00:00Z\"){average_humidity average_pressure average_temperature}}",
  "database": "syncmesh",
  "collection": "sensor_data",
  "request_type": "aggregate"
}
```

A query for collection with external nodes

```json
{
  "query": "{sensors(limit: 1, start_time: \"2017-06-26T00:00:00Z\", end_time: \"2017-08-01T00:00:00Z\"){temperature humidity timestamp}}",
  "database": "syncmesh",
  "collection": "sensor_data",
  "request_type": "collect",
  "external_nodes": ["http://some.random.ip:8080/function/syncmesh-fn"]
}
```

### Querying with variables

You can also use variables instead of writing everything into the query. An advantage of doing this is you have shorter
lines in the request, you also don't need to escape strings. An example for querying a document with an ID:

```json
{
  "query": "query sensor($id: ID!){sensor(_id: $id){temperature}}",
  "database": "syncmesh",
  "variables": {
    "id": "60e9a27ec17cbf8c64ee8796"
  },
  "collection": "sensor_data",
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
  "database": "syncmesh",
  "collection": "sensor_data"
}
```

An update operation:

```json
{
  "query": "mutation{update(_id: \"1\", sensor: {pressure: 1, temperature: 2, humidity: 23, lat: 23.123, lon: 23.232, timestamp: \"2017-06-26T00:00:00Z\"}){temperature}}",
  "database": "syncmesh",
  "collection": "sensor_data"
}
```

Deleting entries for a specific time range:

```json
{
  "query": "mutation{deleteInTimeRange(start_time: \"2017-06-26T00:00:00Z\", end_time: \"2017-07-02T00:00:00Z\")}",
  "database": "syncmesh",
  "collection": "sensor_data"
}
```

The general request has the following parameters:

- "query": Contains the GraphQL query
- "database": Specifies the mongoDB database to query on
- "collection": Specifies the mongoDB collection to query on
- "request_type": Specifies the SyncMesh request type. Currently, "aggregate" and "collect" are supported.
- "external_nodes": list of all addressable external SyncMesh nodes for data collection/aggregation
- "use_meta_data": boolean whether the stored syncmesh metadata of external nodes should be used for collection/aggregation.
  See "Syncmesh meta" for more info.

### Syncmesh meta

Syncmesh meta is a database which stores metadata regarding nearby nodes.
This data can be used to query nodes without specifying external IPs, and later aggregation with geofencing will be possible.
There are three types of requests for the function to manipulate and query this database: "get", "update" and "delete".

#### Updating or creating new node entries

If you do not specify the ID or it is false in the "update request", a new node will be created:

```json
{
  "meta_type": "update",
  "node": { "address": "http://some.ip.here", "lat": 43, "lon": 43 }
}
```

if you want to update instead of creating, specify the ID:

```json
{
  "meta_type": "update",
  "id": "document_id_here",
  "node": { "address": "http://some.ip.here", "lat": 123 }
}
```

Deleting works by just specifying the ID:

```json
{
  "meta_type": "delete",
  "id": "document_id_here"
}
```

You can also fetch the array of all saved nodes with a simple `{"meta_type": "get"}`.

## Libraries, frameworks and packages used

- [OpenFaaS](https://github.com/openfaas)
- [Graphql-Go](https://github.com/graphql-go/graphql)
- [MongoDB](https://www.mongodb.com/)
- [MongoDB Go Driver](https://pkg.go.dev/go.mongodb.org/mongo-driver#section-readme)
- [Go Haversine](https://github.com/umahmood/haversine)
- [Testify](https://github.com/stretchr/testify)

## Good Reads

https://willschenk.com/articles/2021/setting_up_services_with_faasd/
