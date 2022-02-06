#!/bin/bash

CLIENT_IP="$(</client.txt)"
SEPERATOR_IP="$(</seperator.txt)"

# Those variables are set in the Orchestratore Template
#REPETITIONS=20


queryDataCollect() {
# $1 - First Argument is the Start ISODate
for i in $(seq $REPETITIONS)
do

    # Query Data
    /usr/bin/time -ao collect.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "python3 /test.py --requestType 'collect' --startTime $1 --endTime 2017-07-31T23:59:59Z" 1> /dev/null
    echo "Finished Request"
done
}

queryDataAggregate() {
# $1 - First Argument is the Start ISODate
for i in $(seq $REPETITIONS)
do
    # Query Data
    /usr/bin/time -ao aggregate.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "python3 /test.py --requestType 'aggregate' --startTime $1 --endTime 2017-07-31T23:59:59Z" 1> /dev/null
    echo "Finished Request"
done
}

