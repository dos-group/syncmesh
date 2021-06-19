#!/bin/bash

pwd

echo "Hello from the Setup script!"

# Installf faasd 
# https://github.com/openfaas/faasd#deploy-faasd
git clone https://github.com/openfaas/faasd --depth=1
cd faasd

sudo ./hack/install.sh

sleep 10

sudo cat /var/lib/faasd/secrets/basic-auth-password | faas-cli login -s

# Install Some Demo Functions
faas-cli deploy -f https://raw.githubusercontent.com/openfaas/faas/master/stack.yml


sudo ctr image pull docker.io/bitnami/mongodb:latest
sudo ctr container create docker.io/bitnami/mongodb:latest monogdb


