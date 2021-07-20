#!/bin/bash

sudo apt update

# Install Python for data distribution
# sudo apt-get install -y python3.6 python3-pip

# pip install requests

cat > /nodes.txt <<EOF
%{ for node in nodes ~}
${node.network_interface.0.network_ip}
%{ endfor ~}
EOF


cat > /client.txt <<EOF
${client.network_interface.0.network_ip}
EOF

cat > /server.txt <<EOF
${try(server.network_interface.0.network_ip, "")}
EOF

cat > /scenario.txt <<EOF
${scenario}
EOF

cat > /seperator.txt <<EOF
${seperator}
EOF

cat > ~/.ssh/id_rsa <<EOF
${private_key}
EOF
ssh-add ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

cat > ~/.ssh/config <<EOF
Host *
    User orchestrator
EOF

cat > test.sh <<EOF
${testscript}
EOF

echo "Waiting for everything to be set up (static timer)"
sleep 360
echo "Executing Scenarios"

# Execute
bash test.sh