#!/bin/bash

CLIENT_IP="$(</client.txt)"
SEPERATOR_IP="$(</seperator.txt)"

# Those variables are set in the Orchestratore Template
#SLEEP_TIME=120
#PRE_TIME=60
#REPETITIONS=20

seperate () {
    echo "Waiting for Seperation Request ($SLEEP_TIME s)"
    sleep $SLEEP_TIME
    ssh -o StrictHostKeyChecking=no $CLIENT_IP "curl 'https://$SEPERATOR_IP'"
    echo "Waiting after Seperation Request ($PRE_TIME s)"
    sleep $PRE_TIME
}

queryDataCollect() {
# $1 - First Argument is the Start ISODate
for i in $(seq $REPETITIONS)
do

    # Query Data
    /usr/bin/time -ao collect.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "python3 /test.py --requestType 'collect' --startTime $1 --endTime 2017-07-31T23:59:59Z" # 1> /dev/null
    echo "Finished Request"
done
}

queryDataAggregate() {
# $1 - First Argument is the Start ISODate
ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo rm -r /radata"
ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo rm *.tmp"
for i in $(seq $REPETITIONS)
do
    # Query Data
    /usr/bin/time -ao collect.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "python3 /test.py --requestType 'aggregate' --startTime $1 --endTime 2017-07-31T23:59:59Z" # 1> /dev/null
    echo "Finished Request"
done
}



seperate

# Collect
echo "Scenario: Collect - 1 day"
# Write Data Once to central database
uploadData 1
queryDataCollect "2017-07-31T00:00:00Z"


seperate

echo "Scenario: Collect - 7 day"

uploadData 7
queryDataCollect "2017-07-24T00:00:00Z"


seperate

echo "Scenario: Collect - 14 day"

uploadData 14
queryDataCollect "2017-07-17T00:00:00Z"

seperate

echo "Scenario: Collect - 30 day"

uploadData 30
queryDataCollect "2017-06-30T00:00:00Z"

seperate


# Aggregate
echo "Scenario: Aggregate - 1 day"
# Write Data Once to central database
uploadData 1
queryDataAggregate "2017-07-31T00:00:00Z"


seperate

echo "Scenario: Aggregate - 7 day"

uploadData 7
queryDataAggregate "2017-07-24T00:00:00Z"


seperate

echo "Scenario: Aggregate - 14 day"

uploadData 14
queryDataAggregate "2017-07-17T00:00:00Z"

seperate

echo "Scenario: Aggregate - 30 day"

uploadData 30
queryDataAggregate "2017-06-30T00:00:00Z"

seperate


