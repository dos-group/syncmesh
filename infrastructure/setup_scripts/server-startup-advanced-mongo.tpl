#!/bin/bash

pwd

echo "Hello from the Setup script!"

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
  configDB: configserver01/10.1.0.4:27017

  " > /etc/mongod.conf

#<configReplSetName>/cfg1.example.net:27019,cfg2.example.net:27019

sudo mongos --config /etc/mongod.conf &

until mongo --host 10.1.0.4 --eval "print(\"waited for connection\")"
  do
    sleep 60
  done


mongo --host 10.1.0.4:27017 <<EOF
rs.initiate({
  _id: "configserver01",
  configsvr: true,
  members:  [
    {_id:0, host:  "10.1.0.4:27017"}
  ]
})
EOF

#Loop over shards and configure them if mongod ready

 count=1
 while read shardIP; do
   until mongo --host $shardIP --eval "print(\"waited for connection\")"
   do
     sleep 60
   done
   mongo --host $shardIP:27017 <<EOF
   rs.initiate({
     _id: "shard$count",
     members:  [
       {_id:0, host:  "$shardIP:27017"}
     ]
   })
EOF
 (( count++ ))
  
done <nodes.txt


#ToDo make for n nodes (to enable 6)

count=1
while read shardIP; do
  mongo --host 10.1.0.3:27017 <<EOF
  sh.addShard("shard$count/$shardIP:27017")
EOF
(( count++ ))
done < nodes.txt

mongo --host 10.1.0.3:27017 <<EOF
db.collection.createIndex(
  {
      "sensor_id": 1
  },
  {
      sparse: true,
      expireAfterSeconds: 3600
  }
)
use syncmesh
db.createCollection("sensor_data")
sh.enableSharding("syncmesh")
sh.shardCollection("syncmesh.sensor_data", {sensor_id: "hashed"})
EOF



#sleep 10
#mongosh --host 35.242.219.104 --port 27017



#sh.addShard("shard01/34.141.45.127:27017")






# Shard Collection
#sh.shardCollection("test.user", { name : "hashed" } )
#sh.shardCollection("<database>.<collection>", { <shard key field> : "hashed" } )



#db.createCollection("user")

#db.user.find()

# Enable Sharding for database
#sh.enableSharding("database")