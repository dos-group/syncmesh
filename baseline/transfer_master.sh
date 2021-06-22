#!/bin/bash
# transfers data from (sensor-)node to central db

# $MASTER, the central node
MASTER="test-node"
MASTER_IP="34.77.72.236"

# transfer data
gcloud compute scp $1 test-node:~

# import to mongoDB on MASTEr
gcloud compute ssh test-node --command="mongoimport --type csv -d database_test -c test --headerline --drop" $1
