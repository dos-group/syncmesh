#!/bin/bash

pwd

echo "Hello from the Setup script!"

# TODO: Use  a normal docker installation
# Installf faasd 
# https://github.com/openfaas/faasd#deploy-faasd
git clone https://github.com/openfaas/faasd --depth=1
cd faasd

sudo ./hack/install.sh

# Add Mongo to faasd installation
sudo mkdir -p /var/lib/faasd/mongo_data
sudo chown -R 1000:1000 /var/lib/faasd/mongo_data

cat << EOF >> /var/lib/faasd/docker-compose.yaml
  mongo:
    image: docker.io/bitnami/mongodb:latest
    volumes:
      # we assume cwd == /var/lib/faasd
      - type: bind
        source: ./mongo_data
        target: /bitnami/mongodb
    cap_add:
      - CAP_NET_RAW
    user: "1000"
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    ports:
      - "10.62.0.1:27017:27017"
EOF

sudo systemctl daemon-reload
sudo systemctl restart faasd

# Install Mongo CLI
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# Download Data and prepare MongoDB
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