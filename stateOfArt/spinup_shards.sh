#!/bin/bash

#Step 2 - Create Shards and connect
#This can be done for every Shard

Shard01_IP=34.141.45.127
Shard01_PORT=27017



# Install MongoDB on every Ubuntu 20.04 instance and start
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
#sudo systemctl start mongod


# Config file

sudo vim /etc/mongod.conf

sharding:
    clusterRole: shardsvr
replication:
    replSetName: shard01
net:
    bindIp: 0.0.0.0

sudo mongod --config /etc/mongod.conf


# mongosh --host 34.141.45.127 --port 27017

rs.initiate({
	_id: "shard01",
	members:  [
		{_id:0, host: "34.141.45.127:27017"}
	]
})
#rs.conf()