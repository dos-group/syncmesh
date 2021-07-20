#!/bin/bash

pwd

echo "Hello from the Setup script!"

sudo apt-get update
# Install Python for data distribution
sudo apt-get install -y python3.6 python3-pip mongodb-clients

pip install requests

cat > nodes.txt <<EOF
%{ for instance in instances ~}
${instance.network_interface.0.network_ip}:8080
%{ endfor ~}
EOF

cat > test.py <<EOF
${testscript}
EOF
