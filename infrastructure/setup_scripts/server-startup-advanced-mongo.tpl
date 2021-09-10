#!/bin/bash

pwd

echo "Hello from the Setup script!"

Mongos_IP=$(dig @resolver4.opendns.com myip.opendns.com +short)
PORT=27017


## Paste all IPs of the Nodes 
#cat > nodes.txt <<EOF
#%{ for instance in instances ~}
#${instance.network_interface.0.network_ip}
#%{ endfor ~}
#EOF


sudo apt update

# Install Python for data distribution
sudo apt-get install -y python3.6 python3-pip

pip install requests

# Install MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl start mongod

sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf

sudo systemctl daemon-reload
sudo systemctl start mongod
sudo systemctl status mongod
sudo systemctl enable mongod



#Step 3 - Create Mongos and connect


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

sharding:
  configDB: configserver01/10.1.0.4:27017

  " > /etc/mongod.conf

#<configReplSetName>/cfg1.example.net:27019,cfg2.example.net:27019

sudo mongos --config /etc/mongod.conf &

sleep 10
#mongosh --host 35.242.219.104 --port 27017



#sh.addShard("shard01/34.141.45.127:27017")

#sh.addShard("shard1/34.132.202.59:27017")
#sh.addShard("shard2/34.80.19.221:27017")
#sh.addShard("shard3/34.88.177.75:27017")




# Shard Collection
#sh.shardCollection("test.user", { name : "hashed" } )
#sh.shardCollection("<database>.<collection>", { <shard key field> : "hashed" } )

#db.collection.createIndex(
#  {
#      "age": 1
#  },
#  {
#      unique: true,
#      sparse: true,
#      expireAfterSeconds: 3600
#  }
#)

#db.createCollection("user")

#db.user.find()

# Enable Sharding for database
#sh.enableSharding("database")