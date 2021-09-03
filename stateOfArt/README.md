# MongoDb sharded Setup
This MongoDB setup creates a sharded cluster with single node replicasets.  
Single node replicasets are not encouraged for production deployments. But for testing and experimental purposes we decided to use a single node replicaset.  
Execute in the following order:  
1. spinup_configsvr.sh
2. spinup_shards.sh
3. spinup_mongos.sh

Script 1 creates a replicaSet and enables it as a configserver.  
Script 2 creates a sharding instance (this can be done for n sharding instances)  
Script 3 creates a mongos instance, binds it to the configsvr and adds sharding instances.






## Overview of error-messages we encountered and how to solve them:

* "already initialized"
```
rsconf = rs.conf()
rsconf.members = [{_id:0, host: "35.198.165.251:27017"}]
rs.reconfig(rsconf, {force: true})
```

* "was not started with replSet option"
Shut down the mongod
```
sudo systemctl mongod stop
```
and change the /etc/mongod.conf, then restart mongod with the new conf
```
sudo mongod --config /etc/mongod.conf
```


Resources: 
* [Offical Tutorial](https://docs.mongodb.com/manual/tutorial/deploy-shard-cluster/)
