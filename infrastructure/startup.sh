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



# Install Mongo

# maybe via container
sudo ctr image pull docker.io/bitnami/mongodb:latest
sudo ctr container create docker.io/bitnami/mongodb:latest monogdb


# or directly https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl daemon-reload
sudo systemctl start mongod
sudo systemctl status mongod
sudo systemctl enable mongod
