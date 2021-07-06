#!/bin/bash

username="kreutz"
MASTER_IP="10.132.0.2"

for i in "$@"
do
    ssh $i "scp data.csv $MASTER_IP:~"
    mongoimport --type csv -d database_test -c test --headerline --drop data.csv
done
