#!/bin/bash
VERSION=${mongo_version}

pwd

echo "Hello from the Setup script!"
while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
  echo "waiting for other package installs to complete..."
  sleep 1
done
# Install Monitoring Agent
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh && sudo bash add-monitoring-agent-repo.sh --also-install && sudo service stackdriver-agent start

sudo apt-get update
# Install Python for data distribution
sudo apt-get install -y python3.6 python3-pip

pip install requests

cat > nodes.txt <<EOF
%{ for instance in instances ~}
${instance.network_interface.0.network_ip}
%{ endfor ~}
EOF

cat > test.py <<EOF
${testscript}
EOF

touch /finished-setup