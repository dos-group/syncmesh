#!/bin/bash
# Script for setting up mongodb instances and enabling sharding
# Assumption: all VMs have mongodb installed and can be accessed by each other

#https://www.youtube.com/watch?v=j1eCzBueWoQ&list=LL&index=2
#https://docs.mongodb.com/manual/tutorial/deploy-shard-cluster/
#https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/

#helpful for debugging
#ps -ef | grep mongod
#mongo --port
#db.data.find().pretty()
#sh.addShard() 

#sudo systemctl start mongod
username="kreutz"
MASTER_IP="34.72.103.114"
MASTER_IP_intern="10.128.0.3"
PORT="27017"

shard01_IP="34.141.25.222"
shard01_IP_intern="10.156.0.11"



# CONFIG-SERVER node

#create config server replica set
mongod --replSet shard01 --logpath "1.log" --dbpath shard01 --port 27017 --fork --shardsvr  &

#connect mongosh to primary config server
mongosh --host <hostname> --port <port>

mkdir -p shard01 shard02 shard03
mongod --replSet sharding --logpath "1.log" --dbpath shard01 --port 27017 --fork --shardsvr  &
mongod --replSet sharding --logpath "2.log" --dbpath shard02 --port 27018 --fork --shardsvr  &
mongod --replSet sharding --logpath "3.log" --dbpath shard03 --port 27019 --fork --shardsvr  &


#initialize replica set on one node
mongo --port 27017
"rs.initiate(
  {
    _id: "sharding",
    members: [
      { _id : 0, host : "localhost:27017" },
      { _id : 1, host : "localhost:27018" },
      { _id : 2, host : "localhost:27019" }
    ]
  }
)"
#rs.status();


#init sharded mongodb
#mongod --shardsvr --replSet <replSetname>  --dbpath <path> --bind_ip localhost,<hostname(s)|ip address(es)>
sudo mongod --logpath "cfg-a.log" --dbpath /data/config/config-a --replSet conf --port 57040 --fork --configsvr
mongo --port 57040
mongosh --host <hostname> --port <port>
"rs.initiate(
  {
    _id : "sharding",
    members: [
      { _id : 0, host : "34.72.103.114:27017" },
      { _id : 1, host : "34.72.103.114:27018" },
      { _id : 2, host : "34.72.103.114:27019" }
    ]
  }
)"
mongos --configdb conf/34.72.103.114:27017,34.72.103.114:27018,34.72.103.114:27019 --bind_ip localhost

#Add shards (e.g. sensors)
sh.addShard( "sharding/34.72.103.114:27017")

#Enable Sharding for DB
#sh.enableSharding("<database>")

#Start config-server
#sudo mongod --logpath "cfg-a.log" --dbpath /data/config/config-a --replSet conf --port 57040 --fork --configsvr --smallfiles
#mongos --configdb conf/localhost:57040,localhost:57041,localhost:57042 --logpath "mongos-1.log" --port 




#Import CSV, locally into nodes
mongoimport -h $MASTER_IP_intern:$PORT --type csv -d sensor_data -c data --headerline --drop /import.csv