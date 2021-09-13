#!/bin/bash

pwd

echo "Hello from the Setup script!"


ConfSvrIP=$(dig @resolver4.opendns.com myip.opendns.com +short)
PORT=27017
user=$(whoami)


sudo apt update

# Install Python for data distribution
sudo apt-get install -y python3.6 python3-pip

pip install requests


# Install Mongo
#https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/

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
sudo systemctl stop mongod

#sudo systemctl status mongod


# Setting up config server

printf "
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

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
#  keyFile: /tmp/key

replication:
  replSetName: configserver01

sharding:
  clusterRole: configsvr

  " > /etc/mongod.conf

sudo mongod --config  /etc/mongod.conf &