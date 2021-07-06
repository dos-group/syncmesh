#!/bin/bash

pwd

echo "Hello from the Setup script!"

## Paste all IPs of the Nodes 
#cat > nodes.json <<EOF
#%{ for instance in instances ~}
#${instance.network_interface.0.network_ip}
#%{ endfor ~}
#EOF


sudo apt update

# Install Python for data distribution
sudo apt-get install -y python3.6 python3-pip

pip install requests

# Install Mongo
# https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt-get update
sudo apt-get install -y mongodb-org

sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf

sudo systemctl daemon-reload
sudo systemctl start mongod
sudo systemctl status mongod
sudo systemctl enable mongod