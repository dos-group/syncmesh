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
mkdir shard01
mongod --configsvr --replSet conf --dbpath shard01 --bind_ip localhost,$MASTER_IP

#inititate replica set
mongosh --host $MASTER_IP --port $PORT
"rs.initiate(
  {
    _id : "conf",
    configsvr: true,
    members: [
      { _id : 0, host : "$MASTER_IP:$PORT" }
    ]
  }
)"
rs.status()


#Shard-nodes
#create replica set (for each replica set member | for each sharded node)
mkdir shard01
mongod --shardsvr --replSet sharding  --dbpath shard01 --bind_ip localhost,$shard01_IP

#initiate replica set
mongosh --host $shard01_IP --port $PORT
"rs.initiate(
  {
    _id : "sharding",
    members: [
      { _id : 0, host : "$shard01:$PORT" }
    ]
  }
)"
rs.status()

#START Sharding connection
mongos --configdb conf/$MASTER_IP:$PORT --bind_ip localhost,$MASTER_IP
#mongos --configdb conf/cfg1.example.net:27019,cfg2.example.net:27019,cfg3.example.net:27019


#Connect to sharded cluster
mongosh --host $MASTER_IP --port $PORT

#Add our shard nodes
sh.addShard( "sharding/$shard01:$PORT")

#Enable sharding for certain DB (from mongosh instance)
sh.enableSharding("<database>")
#or shard collection
#sh.shardCollection("<database>.<collection>", { <shard key field> : "hashed" } )








#Import CSV, locally into nodes
mongoimport -h $MASTER_IP_intern:$PORT --type csv -d sensor_data -c data --headerline --drop /import.csv