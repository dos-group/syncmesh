#!/bin/bash

pwd

echo "Hello from the Setup script!"

sudo apt update

# Install Python for data distribution
sudo apt-get install -y python3.6 python3-pip mongodb-org

pip install requests

cat > nodes.txt <<EOF
%{ for instance in instances ~}
${instance.network_interface.0.network_ip}:8080
%{ endfor ~}
EOF

cat > test.py <<EOF
${testscript}
EOF
