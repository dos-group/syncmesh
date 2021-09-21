#!/bin/bash

pwd

echo "Hello from the Setup script!"

# Install Mongo
#https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/

wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org=$VERSION mongodb-org-server=$VERSION mongodb-org-shell=$VERSION mongodb-org-mongos=$VERSION mongodb-org-tools=$VERSION
mongod --version
sudo systemctl start mongod


sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf

sudo systemctl daemon-reload
sudo systemctl start mongod
sudo systemctl status mongod
sudo systemctl enable mongod
sudo systemctl stop mongod

#sudo systemctl status mongod


#Step 2 - Create Shards and connect

#printf "XIR0lH6bSx+78jP2aZlOU2f85ShjwMWZSj1uPGGEFjq7c3xzeIETzqTTh+b26j51n3YfQOUwsPwf32YTxlOlPJPahm9h+fftxfRjr//wfeGPX5fOXVCPd3Jbf203E+iu6QZttbHrYBTHK962YoSIjbkzWv5wTT5X0/q7UnjJK7veful0X+f5fh2RGIs6FclUSwzrFtqoAUwuD5R5Z4IPCQxe4QlD2KTbvMLS9ua/B97ENuEY9K/166PTOdfuoeeX/g2Mxlq6t9YT765VXJBFpnPeyLZoMw5uZdaGrqJd7rf8edzFmeMBJMrq2WDkRfJRoUVv4l2r6oagV0z4aJ8Bn5wYaq2DiddVD3fkuPI7lymJFPUX7GPZzTXWdTJiSHsNpOWPtfCh+2Vsj7T2D1OIKDE8qb8zRYEbcE4t/5Pfc+5mqbg5nhMVJBrgW23xYT/8CMrOjUWnQBKSdUtOh6K5/ZOBhdRdcBKCAPhi/SXxnVy37B8geufyt/3qpMZOIYrOabANIY+1qbeSp5CMDPy1tANqaRzajVYrCYW8rZ92wMx0omjze9MV5zkfRsFdxAIDGcJ0Gm8lFxnaSLLv5KVSbaRf6CuENuTHwTBFkHpgr5cZYjfKTz8ykhbhsz9Ud2rCN5nUHgZcPXqbgPdwSKZlawntxriD4MgMnIEjaAJy92wLInub7r8icychOc72x55eMGwPX4QwAHJE95No1c6d0dlDiqtTpAQmLbUQjs9+Ie7Zlt31EvXxS4mhrdbkvi/CTpXOYeOUljGxXWOZ3wRGMUT6Q2ddrb6+arbBmYtxaXmVAvFcuU+bAhgya2BPJfrqkTqicJ5KePPDoQFjfShKpDrmg8WZxnJ4Xk5CNRH8wJ3q5I2yuXKK89sOkbYkqj6R66C9HteBGCRjdK5hv+eXu+1+VzBSEr3tr601ZCeW2qKMxsiAcEPp4UtGCjtF0KAEzkkGez2dOhL243/LzFWqu9f5YazdRMdRDgZRtM7tw9fV2N+W" > /home/$user/mongodb.key
#sudo chmod 600 /home/$user/mongodb.key

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
#  keyFile: /home/$user/mongodb.key
  
" > /etc/mongod.conf

sudo mongod --config /etc/mongod.conf &




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