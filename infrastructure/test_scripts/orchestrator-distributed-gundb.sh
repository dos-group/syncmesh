#!/bin/bash

SERVER_IP=$(</server.txt) #10.0.0.3
CLIENT_IP="$(</client.txt)" #10.0.0.2
SEPERATOR_IP="$(</seperator.txt)" #92.60.39.199

# Those variables are set in the Orchestratore Template
#REPETITIONS=20


queryDataCollect() {
# $1 - First Argument is the Start ISODate
ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo rm -r /radata"
ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo rm /*.tmp"

# TODO implement only once as after that the data is already in the local database
for i in $(seq $REPETITIONS)
do

    # Query Data
    /usr/bin/time -ao collect.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "cd /; sudo node test.py collect $1 2017-07-31T23:59:59Z<<'EOF'
    $COMMAND
EOF
" 1> /dev/null
echo "Finished Request"
done
}

queryDataAggregate() {
# $1 - First Argument is the Start ISODate
# TODO implement only once as after that the data is already in the local database
ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo rm -r /radata"
ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo rm *.tmp"
for i in $(seq $REPETITIONS)
do
    # Query Data
    /usr/bin/time -ao aggregate.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "cd /; sudo node test.py aggregate $1 2017-07-31T23:59:59Z<<'EOF'
    $COMMAND
EOF
" 1> /dev/null
    echo "Finished Request"
done
}

