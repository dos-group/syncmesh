#!/bin/bash

username="kreutz"
MASTER_IP="34.78.87.225"
MASTER_IP_intern="10.132.0.2"
PORT="2784"

for i in "$@"
do
    ssh $i "mongoimport -h $MASTER_IP:$PORT --type csv -d database_test -c test --headerline --drop import.csv"
done
