#!/bin/bash
#https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/


wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list

sudo apt-get update

sudo apt-get install -y mongodb-org

sudo systemctl start mongod

#sudo systemctl status mongod

#chown -R mongodb:mongodb /var/lib/mongodb
#chown mongodb:mongodb /tmp/mongodb-27017.sock


mongod

use admin
db.createUser (
	{
	user: "userAdmin",
	pwd: "random",
	roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
	}
)


#sudo vim /etc/mongod.conf -> security: authorization: enabled
#sudo systemctl restart mongods

# change Bind IP (u can only bind to one IP)
#sudo vim /etc/mongod.conf -> net: port: 27017, ip: 0.0.0.0
#net:
#  bindIp: localhost,<hostname(s)|ip address(es)>
# replication: replSetName: shard1

#sharding: clusterRole: configsvr 
#For shards: clusterRole: shardsvr



# Find my public IP
curl https://ipinfo.io/ip

# Connect to remote MongoDB Instance (for testing)
mongo -u "userAdmin" -p -authenticationDatabase admin -host 34.141.45.127

#Initiate replica set
#give a replSetName in mongod.conf
rs.initiate()

#Add members from primary node
rs.add("hostname:port")

#might be helpful
#rs.reconfig(conf);


#connect mongosh
mongosh --host <hostname> --port <port>
