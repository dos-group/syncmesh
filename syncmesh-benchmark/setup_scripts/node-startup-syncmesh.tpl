#!/bin/bash
MONGO_VERSION=${mongo_version}
FAASD_VERSION=${faasd_version}

pwd

echo "Hello from the Setup script!"
while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
  echo "waiting for other package installs to complete..."
  sleep 1
done
# Install Monitoring Agent
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh && sudo bash add-monitoring-agent-repo.sh --also-install && sudo service stackdriver-agent start

# Installf faasd 
# https://github.com/openfaas/faasd#deploy-faasd
git clone https://github.com/openfaas/faasd --depth=1
cd faasd
git fetch --tags
git checkout tags/$FAASD_VERSION

sudo ./hack/install.sh

# Add Mongo to faasd installation
sudo mkdir -p /var/lib/faasd/mongo_data
sudo chown -R 1000:1000 /var/lib/faasd/mongo_data
# TODO(dh): fine-tune replicaset params https://github.com/bitnami/bitnami-docker-mongodb#setting-up-replication
cat << EOF >> /var/lib/faasd/docker-compose.yaml
  mongo:
    image: docker.io/bitnami/mongodb:MONGO_VERSION
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
    # Why? https://github.com/openfaas/faasd/issues/134#issuecomment-768587793
      - "10.62.0.1:27017:27017"
EOF

sed -i "s/MONGO_VERSION/$MONGO_VERSION/" /var/lib/faasd/docker-compose.yaml


sudo systemctl daemon-reload
sudo systemctl restart faasd

# Install Mongo CLI
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org-shell=$MONGO_VERSION mongodb-org-tools=$MONGO_VERSION
mongo --version

# Install Python for data distribution
sudo apt-get install -y python3.6

sleep 30
# Login
sudo cat /var/lib/faasd/secrets/basic-auth-password | faas-cli login -s

mkdir /syncmesh
cd /syncmesh && git clone https://github.com/DSPJ2021/syncmesh.git . 
cd /syncmesh/functions && faas template pull && faas-cli template store pull golang-http && faas-cli template store pull golang-middleware && faas deploy -f syncmesh-fn.yml

#  Install Some Demo Functions
faas-cli deploy -f https://raw.githubusercontent.com/openfaas/faas/master/stack.yml --regex echoit

# Download Data and prepare MongoDB
cd /
wget -O import.csv https://raw.githubusercontent.com/DSPJ2021/data/main/data/${id}.csv
# Use openfaas loopback IP
mongoimport --type csv -d syncmesh -c sensor_data --headerline --drop import.csv --host 10.62.0.1:27017

# Fix Dates
mongo --host 10.62.0.1:27017 <<EOF
use syncmesh
db.sensor_data.find().forEach(function(doc) {
doc.timestamp=new Date(doc.timestamp);
db.sensor_data.save(doc);
})
EOF

touch /finished-setup