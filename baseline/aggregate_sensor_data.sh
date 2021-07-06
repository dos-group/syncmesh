#!/bin/bash

username="dnhb"
MASTER_IP="34.78.87.225"
MASTER_IP_intern="10.2.0.3"
PORT="27017"

while IFS=, read -u10 -r externalIP internalIP; do 
    echo "SHH into $externalIP ($internalIP)"
    ssh -o StrictHostKeyChecking=no $externalIP "mongoimport -h $MASTER_IP_intern:$PORT --type csv -d database_test -c test --headerline --drop /import.csv"
done 10< ips.txt
