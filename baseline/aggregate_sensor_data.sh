#!/bin/bash

username="kreutz"
MASTER_IP="34.78.87.225"
MASTER_IP_intern="10.132.0.2"
PORT="2784"

while IFS=, read -r externalIP; do 
    ssh $externalIP "mongoimport -h $MASTER_IP_intern:$PORT --type csv -d database_test -c test --headerline --drop import.csv"
done < ips.txt
