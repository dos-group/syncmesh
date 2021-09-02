#!/bin/bash

#Step 1 - Install and Config configserver
#Ubuntu 20.4 LTS VM
#ec2.micro
#allow http and https traffic

ConfSvrIP=35.198.165.251
Port=27017


# Install MongoDB on every Ubuntu 20.04 instance and start
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
#sudo systemctl start mongod


#Config file

sudo vim /etc/mongod.conf


net:
  port: 27017
  bindIp: 0.0.0.0



replication:
  replSetName: configserver01
sharding:
  clusterRole: configsvr



sudo mongod --config  /etc/mongod.conf


# MongoDB settings
use admin
db.createUser (
	{
	user: "userAdmin",
	pwd: "random",
	roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
	}
)
mongo -u "userAdmin" -p -authenticationDatabase admin -host $ConfSvrIP

mongosh --host 35.198.165.251 --port 27017
rs.initiate({
	_id: "configserver01",
	configsvr: true,
	members:  [
		{_id:0, host: "$ConfSvrIP:$Port"}
	]
})
