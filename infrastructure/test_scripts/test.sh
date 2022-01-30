#!/bin/bash

# Those variables are set in the Orchestratore Template
#SLEEP_TIME=120
#PRE_TIME=60

seperate () {
    echo "Waiting for Seperation Request ($SLEEP_TIME s)"
    sleep $SLEEP_TIME
    ssh -o StrictHostKeyChecking=no $CLIENT_IP "curl 'https://$SEPERATOR_IP'"
    echo "Waiting after Seperation Request ($PRE_TIME s)"
    sleep $PRE_TIME
}


# Collect

seperate

echo "Scenario: Collect - 1 day"
queryDataCollect "2017-07-31T00:00:00Z" 1

seperate

echo "Scenario: Collect - 7 day"
queryDataCollect "2017-07-24T00:00:00Z" 7

seperate

echo "Scenario: Collect - 14 day"
queryDataCollect "2017-07-17T00:00:00Z" 14

seperate

echo "Scenario: Collect - 30 day"
queryDataCollect "2017-06-30T00:00:00Z" 30

seperate


# Aggregate


echo "Scenario: Aggregate - 1 day"
queryDataAggregate "2017-07-31T00:00:00Z" 1

seperate

echo "Scenario: Aggregate - 7 day"
queryDataAggregate "2017-07-24T00:00:00Z" 7

seperate

echo "Scenario: Aggregate - 14 day"
queryDataAggregate "2017-07-17T00:00:00Z" 14

seperate

echo "Scenario: Aggregate - 30 day"
queryDataAggregate "2017-06-30T00:00:00Z" 30

seperate


