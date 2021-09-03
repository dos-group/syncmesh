#!/bin/bash


cat > /nodes.txt <<EOF
%{ for node in nodes ~}
${node.network_interface.0.network_ip}
%{ endfor ~}
EOF


cat > /client.txt <<EOF
${client.network_interface.0.network_ip}
EOF

%{ for s in server ~}
cat > /server.txt <<EOF
${s.network_interface.0.network_ip}
EOF
%{ endfor ~}

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

# The Quotes are there so the variables arent expanded
cat > test.sh <<'CUSTOMEOF'
${testscript}
CUSTOMEOF

echo "Waiting for everything to be set up (static timer)"
# 10 Minutes should be more than sufficient
sleep 600

echo "Executing Scenarios"

# Execute
bash test.sh