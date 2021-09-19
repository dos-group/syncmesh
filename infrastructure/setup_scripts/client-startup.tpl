#!/bin/bash
VERSION=${mongo_version}

pwd

echo "Hello from the Setup script!"

sudo apt-get update
# Install Python for data distribution
sudo apt-get install -y python3.6 python3-pip

wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org=$VERSION mongodb-org-server=$VERSION mongodb-org-shell=$VERSION mongodb-org-mongos=$VERSION mongodb-org-tools=$VERSION
mongo --version

pip install requests

cat > nodes.txt <<EOF
%{ for instance in instances ~}
${instance.network_interface.0.network_ip}:8080
%{ endfor ~}
EOF

cat > test.py <<EOF
${testscript}
EOF
