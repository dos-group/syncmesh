#!/bin/bash

pwd

echo "Hello from the Setup script!"


ShardIP=$(dig @resolver4.opendns.com myip.opendns.com +short)
PORT=27017

user=$(whoami)


hostName=$(hostname)
iterator=$(echo $hostName| cut -c 56)


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


#Step 2 - Create Shards and connect

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

sharding:
    clusterRole: shardsvr
replication:
    replSetName: shard$iterator

  " > /etc/mongod.conf

sudo mongod --config /etc/mongod.conf &



# Download the data 
cd /
wget -O import.csv https://raw.githubusercontent.com/DSPJ2021/data/main/data/${id}.csv

# 1 Day
currentTime=$(date --date="2017-07-31T00:00:00" +%s)
{

printf "sensor_id,location,lat,lon,timestamp,pressure,temperature,humidity\n" > data.csv
# This Read skipts the header line!
read 
while IFS=, read -r sensor_id location lat lon timestamp pressure temperature humidity; do
    temp=$(date --date=$timestamp +%s)  
    if [ $temp -ge $currentTime ];
    then
        printf "$sensor_id,$location,$lat,$lon,$timestamp,$pressure,$temperature,$humidity\n" >> data.csv
    fi
done 
} < import.csv
mv data.csv import1.csv

# 7 Day
currentTime=$(date --date="2017-07-31T00:00:00 7 day ago" +%s)
{

printf "sensor_id,location,lat,lon,timestamp,pressure,temperature,humidity\n" > data.csv
# This Read skipts the header line!
read 
while IFS=, read -r sensor_id location lat lon timestamp pressure temperature humidity; do
    temp=$(date --date=$timestamp +%s)  
    if [ $temp -ge $currentTime ];
    then
        printf "$sensor_id,$location,$lat,$lon,$timestamp,$pressure,$temperature,$humidity\n" >> data.csv
    fi
done 
} < import.csv
mv data.csv import7.csv

# 14 Day
currentTime=$(date --date="2017-07-31T00:00:00 14 day ago" +%s)
{

printf "sensor_id,location,lat,lon,timestamp,pressure,temperature,humidity\n" > data.csv
# This Read skipts the header line!
read 
while IFS=, read -r sensor_id location lat lon timestamp pressure temperature humidity; do
    temp=$(date --date=$timestamp +%s)  
    if [ $temp -ge $currentTime ];
    then
        printf "$sensor_id,$location,$lat,$lon,$timestamp,$pressure,$temperature,$humidity\n" >> data.csv
    fi
done 
} < import.csv
mv data.csv import14.csv

# 14 Day
currentTime=$(date --date="2017-07-31T00:00:00 30 day ago" +%s)
{

printf "sensor_id,location,lat,lon,timestamp,pressure,temperature,humidity\n" > data.csv
# This Read skipts the header line!
read 
while IFS=, read -r sensor_id location lat lon timestamp pressure temperature humidity; do
    temp=$(date --date=$timestamp +%s)  
    if [ $temp -ge $currentTime ];
    then
        printf "$sensor_id,$location,$lat,$lon,$timestamp,$pressure,$temperature,$humidity\n" >> data.csv
    fi
done 
} < import.csv
mv data.csv import30.csv

#"mongoimport -h $SERVER_IP:$PORT --type csv -d syncmesh -c sensor_data --headerline --drop /import$1.csv"