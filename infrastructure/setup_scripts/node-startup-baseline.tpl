#!/bin/bash
VERSION=${mongo_version}

pwd

echo "Hello from the Setup script!"
while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
  echo "waiting for other package installs to complete..."
  sleep 1
done

# Install Monitoring Agent
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh && sudo bash add-monitoring-agent-repo.sh --also-install && sudo service stackdriver-agent start

# Install Mongoimport Tool
#https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/

wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org=$VERSION mongodb-org-server=$VERSION mongodb-org-shell=$VERSION mongodb-org-mongos=$VERSION mongodb-org-tools=$VERSION
mongod --version

# Download Data 
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