# Syncmesh

<img src="/images/syncmesh_logo.png" align="left"
width="200" hspace="10" vspace="10">

Distributed storage querying and coordination system, based on OpenFaaS.  

## About

This is a project by students of the Technical University of Berlin on Distributed Systems.
Syncmesh tackles the topics of Distributed Storage, Function-as-a-Service, and Edge Computing.
[Read our paper here](https://github.com/DSPJ2021/paper).

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

To set up the
credentials [follow this guide](https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build#set-up-gcp),
but additionally grant the following roles:

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

For using Syncmesh, read the wiki: [Syncmesh Wiki](https://github.com/DSPJ2021/syncmesh/wiki)

## Libraries, frameworks and packages used

- [OpenFaaS](https://github.com/openfaas)
- [Graphql-Go](https://github.com/graphql-go/graphql)
- [MongoDB](https://www.mongodb.com/)
- [MongoDB Go Driver](https://pkg.go.dev/go.mongodb.org/mongo-driver#section-readme)
- [Go Haversine](https://github.com/umahmood/haversine)
- [Testify](https://github.com/stretchr/testify)

## Good Reads

https://willschenk.com/articles/2021/setting_up_services_with_faasd/
