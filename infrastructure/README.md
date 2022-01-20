# Infrastructure

Please make sure all the prerequisites are met before proceeding.

A detailed tutorial for the cloud infrastructure setup is
provided [in the wiki](https://github.com/DSPJ2021/syncmesh/wiki/Cloud-infrastructure-setup).

To set up the
credentials [follow this guide](https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build#set-up-gcp),
but additionally grant the following roles:

- roles/resources.editor
- roles/storage.admin
- roles/bigquery.admin
- roles/logging.configWriter on the logsink's project, folder, or organization
- roles/resourcemanager.projectIamAdmin on the destination project
- roles/serviceusage.serviceUsageAdmin on

A short overview of the commands to set up the infrastructure and configure resources:

```terraform
# Initialize
terraform init
terraform plan --out tfplan
terraform apply tfplan

terraform apply --var-file = experiment-3-syncmesh.tfvars

# Find one of the IPs and connect to the instance:
ssh -o StrictHostKeyChecking=no -L 8080 :ip : 8080 username@ip

# Follow Startup Script Log
sudo journalctl -u google-startup-scripts.service -f | grep startup-script
# See Startup Script Log
sudo journalctl -u google-startup-scripts.service | cut -d "]" -f2- | grep startup-script

# Start test manually
SLEEP_TIME=2 PRE_TIME=0 REPETITIONS=10 bash test.sh

gcloud auth activate-service-account terraform@dspj-315716.iam.gserviceaccount.com --key-file = "credentials.json"
gcloud config set project dspj-315716
gcloud compute instances get-serial-port-output  experiment-baseline-with-latency-3-test-orchestrator
# For Better display on smaller screens use
gcloud compute instances get-serial-port-output  experiment-distributed-gundb-with-latency-3-test-orchestrator | cut -d "]" -f2- | grep startup-script

# Destroy
terraform destroy
```

# Experiments

Run the terraform the Terraform script for either `baseline`, `syncmesh` or `advanced-mongo` scenario:

```bash
terraform apply -var-file ./experiment-3-baseline.tfvars
```
