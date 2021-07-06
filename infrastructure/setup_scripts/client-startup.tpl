#!/bin/bash

pwd

echo "Hello from the Setup script!"

sudo apt update

# Install Python for data distribution
sudo apt-get install -y python3.6 python3-pip

pip install requests

cat > nodes.json <<EOF
%{ for instance in instances ~}
${instance.network_interface.0.network_ip}:8080
%{ endfor ~}
EOF

cat > test.py <<EOF
from time import time, sleep
import requests
import json

with open('./nodes.json') as f:
  node = f.readline()

  while True:
      r =requests.get("http://" + node + "/function/nodeinfo")
      print(r.status_code)
      sleep(1)
EOF

# Execute
# python3 test.py