#!/bin/bash
# transfers data from (sensor-)node to central db

# $MASTER, the central node
MASTER="test-node"
MASTER_IP=$2

# transfer data
scp $1 $2:~

# import to mongoDB on MASTEr

