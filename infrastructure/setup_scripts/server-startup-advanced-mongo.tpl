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

Mongos_IP=$(dig @resolver4.opendns.com myip.opendns.com +short)
PORT=27017
user=$(whoami)

currentPath=$(pwd)


## Paste all IPs of the Nodes 
cat > nodes.txt <<EOF
%{ for instance in instances ~}
${instance.network_interface.0.network_ip}
%{ endfor ~}
EOF


sudo apt update

# Install Python for data distribution
sudo apt-get install -y python3.6 python3-pip

pip install requests

# Install Mongo
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org=$VERSION mongodb-org-server=$VERSION mongodb-org-shell=$VERSION mongodb-org-mongos=$VERSION mongodb-org-tools=$VERSION
mongod --version

#Step 3 - Create Mongos and connect


## Keyfile-Authentication Create & Distribute to mongod/mongos
#sudo openssl rand -base64 756 > /tmp/key
#sudo chmod 400 /tmp/key

#while read internalIP; do
#    echo "SCP KeyFile $internalIP"
#    scp -o StrictHostKeyChecking=no /tmp/key $internalIP:/tmp/
#    ssh -o StrictHostKeyChecking=no $internalIP "sudo chmod 400  /tmp/key"
#done < /nodes.txt

#printf "XIR0lH6bSx+78jP2aZlOU2f85ShjwMWZSj1uPGGEFjq7c3xzeIETzqTTh+b26j51n3YfQOUwsPwf32YTxlOlPJPahm9h+fftxfRjr//wfeGPX5fOXVCPd3Jbf203E+iu6QZttbHrYBTHK962YoSIjbkzWv5wTT5X0/q7UnjJK7veful0X+f5fh2RGIs6FclUSwzrFtqoAUwuD5R5Z4IPCQxe4QlD2KTbvMLS9ua/B97ENuEY9K/166PTOdfuoeeX/g2Mxlq6t9YT765VXJBFpnPeyLZoMw5uZdaGrqJd7rf8edzFmeMBJMrq2WDkRfJRoUVv4l2r6oagV0z4aJ8Bn5wYaq2DiddVD3fkuPI7lymJFPUX7GPZzTXWdTJiSHsNpOWPtfCh+2Vsj7T2D1OIKDE8qb8zRYEbcE4t/5Pfc+5mqbg5nhMVJBrgW23xYT/8CMrOjUWnQBKSdUtOh6K5/ZOBhdRdcBKCAPhi/SXxnVy37B8geufyt/3qpMZOIYrOabANIY+1qbeSp5CMDPy1tANqaRzajVYrCYW8rZ92wMx0omjze9MV5zkfRsFdxAIDGcJ0Gm8lFxnaSLLv5KVSbaRf6CuENuTHwTBFkHpgr5cZYjfKTz8ykhbhsz9Ud2rCN5nUHgZcPXqbgPdwSKZlawntxriD4MgMnIEjaAJy92wLInub7r8icychOc72x55eMGwPX4QwAHJE95No1c6d0dlDiqtTpAQmLbUQjs9+Ie7Zlt31EvXxS4mhrdbkvi/CTpXOYeOUljGxXWOZ3wRGMUT6Q2ddrb6+arbBmYtxaXmVAvFcuU+bAhgya2BPJfrqkTqicJ5KePPDoQFjfShKpDrmg8WZxnJ4Xk5CNRH8wJ3q5I2yuXKK89sOkbYkqj6R66C9HteBGCRjdK5hv+eXu+1+VzBSEr3tr601ZCeW2qKMxsiAcEPp4UtGCjtF0KAEzkkGez2dOhL243/LzFWqu9f5YazdRMdRDgZRtM7tw9fV2N+W" > /home/$user/mongodb.key
#sudo chmod 600 /home/$user/mongodb.key
printf "
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

#security:
#  keyFile: /home/$user/mongodb.key

sharding:
  configDB: configserver01/10.0.0.4:27017

  " > /etc/mongod.conf

#<configReplSetName>/cfg1.example.net:27019,cfg2.example.net:27019

echo "Start Mongo Server"
sudo mongos --config /etc/mongod.conf &


echo "Wait for Config Server"
until mongo --host 10.0.0.4 --eval "print(\"waited for connection\")"
  do
    sleep 60
done

echo "Add Config Server"
mongo --host 10.0.0.4:27017 <<EOF
rs.initiate({
  _id: "configserver01",
  configsvr: true,
  members:  [
    {_id:0, host:  "10.0.0.4:27017"}
  ]
})
EOF

echo "Loop over shards and configure them if mongod ready"
count=1
while read shardIP; do
  until mongo --host $shardIP --eval "print(\"waited for connection\")"
  do
    sleep 20
  done
  mongo --host $shardIP:27017 <<EOF
  rs.initiate({
    _id: "shard$count",
    members:  [
      {_id:0, host:  "$shardIP:27017"}
    ]
  })
EOF

case $count in

  1) 
    FROM=0
    TO=1765
    ;;
  2) 
    FROM=1846
    TO=1847
    ;;
  3) 
    FROM=1849
    TO=1850
    ;;
  4) 
    FROM=1951
    TO=1952
    ;;
  5) 
    FROM=1953
    TO=1952
    ;;
  6) 
    FROM=1961
    TO=1962
    ;;
esac
  until mongo --eval "print(\"waited for connection\")"
  do
    sleep 20
  done

  mongo <<EOF
  sh.addShard("shard$count/$shardIP:27017")
  use syncmesh
  sh.addShardToZone("shard$count", "shard$count-zone")
  sh.updateZoneKeyRange(
   "syncmesh.sensor_data",
   { sensor_id : $FROM, "_id" : MinKey },
   { sensor_id : $TO, "_id" : MaxKey },
   "shard$count-zone"
)
EOF
 (( count++ ))
  
done <nodes.txt

#ToDo Zones for 6 nodes (txt or redo data)
mongo --host 10.0.0.3:27017 <<EOF
use syncmesh
db.sensor_data.createIndex(
  {
      "sensor_id": 1,
      "_id": "hashed"
  }
)
sh.enableSharding("syncmesh")
sh.shardCollection("syncmesh.sensor_data", {sensor_id: 1, _id: "hashed"})
EOF