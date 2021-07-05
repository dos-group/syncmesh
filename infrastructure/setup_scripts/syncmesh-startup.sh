#!/bin/bash

pwd

echo "Hello from the Setup script!"

# Installf faasd 
# https://github.com/openfaas/faasd#deploy-faasd
git clone https://github.com/openfaas/faasd --depth=1
cd faasd

sudo ./hack/install.sh

# Add Mongo to faasd installation
sudo mkdir -p /var/lib/faasd/mongo_data
sudo chown -R 1000:1000 /var/lib/faasd/mongo_data

cat << EOF >> /var/lib/faasd/docker-compose.yaml
  redis:
    image: docker.io/bitnami/mongodb:latest
    volumes:
      # we assume cwd == /var/lib/faasd
      - type: bind
        source: ./mongo_data
        target: /bitnami/mongodb
    cap_add:
      - CAP_NET_RAW
    user: "1000"
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    ports:
      - "10.62.0.1:27017:27017"
EOF

sudo systemctl daemon-reload
sudo systemctl restart faasd

# Install Mongo CLI
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# Install Python for data distribution
sudo apt-get install -y python3.6

# Get Data
wget https://github.com/DSPJ2021/syncmesh/raw/baseline/baseline/2017-07_bme280sof.csv.zip


sleep 30
# Login
sudo cat /var/lib/faasd/secrets/basic-auth-password | faas-cli login -s

mkdir /syncmesh
cd /syncmesh && git clone https://github.com/DSPJ2021/syncmesh.git . 
cd /syncmesh/functions && faas template pull && faas-cli template store pull golang-http && faas-cli template store pull golang-middleware && faas deploy -f syncmesh-fn.yml

#  Install Some Demo Functions
faas-cli deploy -f https://raw.githubusercontent.com/openfaas/faas/master/stack.yml