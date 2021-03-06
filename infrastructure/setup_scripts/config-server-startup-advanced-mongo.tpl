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


# Setting up config server

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

replication:
  replSetName: configserver01

sharding:
  clusterRole: configsvr

  " > /etc/mongod.conf

sudo mongod --config  /etc/mongod.conf &

touch /finished-setup