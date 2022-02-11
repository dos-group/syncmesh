# Syncmesh

<img src="https://github.com/DSPJ2021/syncmesh/raw/main/images/syncmesh_logo.png" align="middle"
width="200" hspace="10" vspace="10">

Distributed data storage, querying and coordination system, based on OpenFaaS and MongoDB.

## About

This is a project by students of the Technical University of Berlin, completed as part of the Distributed Systems
course. Syncmesh tackles the topics of Distributed Storage, Function-as-a-Service, and Edge Computing. The goal was to
evaluate the performance of a custom solution against traditional centralized and distributed storage use cases. Read
more about it in our [Syncmesh Wiki](https://github.com/DSPJ2021/syncmesh/wiki). You can find more information from our analysis in
the [Benchmark Data Repository](https://github.com/DSPJ2021/benchmark-data) or in
the [Github Actions](https://github.com/dos-group/syncmesh/actions).

## Prerequisites

General/Recommended:

- [go](https://golang.org/doc/install)
- [openfaas CLI](https://docs.openfaas.com/cli/install/)

For local deployment:

- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/)
- [arkade](https://github.com/alexellis/arkade#get-arkade)

For remote deployment:

- [terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Cloud SDK](https://cloud.google.com/sdk/docs/install)

## How to use & Setup

This README only provides a short overview of the project and some tools/scripts.
For an extensive documentation on Syncmesh, read the wiki: [Syncmesh Wiki](https://github.com/DSPJ2021/syncmesh/wiki) or have a look into the README of the folders.

To just run a Benchmark follow this short guide:

1. Fork this Repository
2. Provide `GCE_CREDENTIALS` with the base64 of `credentials.json` as [seen here](https://github.com/DSPJ2021/syncmesh/wiki/Cloud-infrastructure-setup/) (also change the project-id).
3. Run [any of the actions](https://github.com/dos-group/syncmesh/actions) labeled "Benchmark".

### Repository Structure

- [`functions`](/functions) contains the syncmesh function with all relevant functionality and deployment .yml files
- [`infrastructure`](/infrastructure) contains all terraform cloud infrastructure setup and test scripts, as well as configurations for the different scenarios
- [`mongo_event_listener`](/mongo_event_listener) contains the event listener that accompanies the MongoDB for event-driven infrastructure. It can be either launched as a standalone script or inside a docker container
- [`evaluation`](/evaluation) includes evaluation jupyter notebooks with relevant graphs and performance comparisons
- [`local_setup_scripts`](/local_setup_scripts) contains scripts for local setup and deployment
  - `minikube_node_setup.sh`: sets up an openfaas instance in the minikube cluster and also mongodb in the same namespace
  - `get_openfaas_password.sh`: fetches saves, and outputs the openfaas gateway password
  - `functions_deployer.sh`: deploys functions

### Openfaas - Working on Nodes

```bash
# Find out the password or login
sudo cat /var/lib/faasd/secrets/basic-auth-password
sudo cat /var/lib/faasd/secrets/basic-auth-password | faas-cli login -s

# get logs
sudo journalctl -f | grep mongo
```

## Libraries, frameworks and packages used

- [OpenFaaS](https://github.com/openfaas)
- [Graphql-Go](https://github.com/graphql-go/graphql)
- [MongoDB](https://www.mongodb.com/)
- [MongoDB Go Driver](https://pkg.go.dev/go.mongodb.org/mongo-driver#section-readme)
- [Go Haversine](https://github.com/umahmood/haversine)
- [Testify](https://github.com/stretchr/testify)

Infrastructure:

- Docker
- faasd
- Terraform
- Kubernetes
- Google Cloud

## Good Reads

https://willschenk.com/articles/2021/setting_up_services_with_faasd/
