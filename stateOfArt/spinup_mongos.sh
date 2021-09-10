#!/bin/bash

#Step 3 - Create Mongos and connect
#This can be done for every Shard

Mongos_IP=35.242.219.104
Mongos_PORT=27017

# Install MongoDB on every Ubuntu 20.04 instance and start
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
#sudo systemctl start mongod


# Config file


sudo vim /etc/mongod.conf

#delete storage parameters
sharding:
  configDB: configserver01/35.198.165.251:27017
 #<configReplSetName>/cfg1.example.net:27019,cfg2.example.net:27019
net:
  bindIp: 0.0.0.0 #localhost,<hostname(s)|ip address(es)>

sudo mongos --config /etc/mongod.conf


#mongosh --host 35.242.219.104 --port 27017

sh.addShard("shard01/34.141.45.127:27017")



# Enable Sharding for database
sh.enableSharding("database")


# Shard Collection
sh.shardCollection("test.user", { name : "hashed" } )
#sh.shardCollection("<database>.<collection>", { <shard key field> : "hashed" } )

db.collection.createIndex(
  {
      "age": 1
  },
  {
      unique: true,
      sparse: true,
      expireAfterSeconds: 3600
  }
)

#db.user.find()
