#!/bin/bash

CLIENT_IP="$(</client.txt)"
SEPERATOR_IP="$(</seperator.txt)"

SLEEP_TIME=120
PRE_TIME=60
# REPETITIONS=20

seperate () {
    curl "https://$SEPERATOR_IP"
    sleep $PRE_TIME
}

seperate

# Collect
echo "Scenario: Collect - 1 day"
ssh -o StrictHostKeyChecking=no $CLIENT_IP 'python3 /test.py --repetitions 20 --requestType "collect" --startTime "2017-07-31T00:00:00Z" --endTime "2017-07-31T23:59:59Z"'

sleep $SLEEP_TIME
seperate

echo "Scenario: Collect - 7 day"
ssh -o StrictHostKeyChecking=no $CLIENT_IP 'python3 /test.py --repetitions 20 --requestType "collect" --startTime "2017-07-24T00:00:00Z" --endTime "2017-07-31T23:59:59Z"'

sleep $SLEEP_TIME
seperate

echo "Scenario: Collect - 14 day"
ssh -o StrictHostKeyChecking=no $CLIENT_IP 'python3 /test.py --repetitions 20 --requestType "collect" --startTime "2017-07-17T00:00:00Z" --endTime "2017-07-31T23:59:59Z"'

sleep $SLEEP_TIME
seperate

echo "Scenario: Collect - 30 day"
ssh -o StrictHostKeyChecking=no $CLIENT_IP 'python3 /test.py --repetitions 20 --requestType "collect" --startTime "2017-06-30T00:00:00Z" --endTime "2017-07-31T23:59:59Z"'

sleep $SLEEP_TIME
seperate

# Aggregate 
echo "Scenario: Aggregate - 1 day"
ssh -o StrictHostKeyChecking=no $CLIENT_IP 'python3 /test.py --repetitions 20 --requestType "aggregate" --startTime "2017-07-31T00:00:00Z" --endTime "2017-07-31T23:59:59Z"'

sleep $SLEEP_TIME
seperate

echo "Scenario: Aggregate - 7 day"
ssh -o StrictHostKeyChecking=no $CLIENT_IP 'python3 /test.py --repetitions 20 --requestType "aggregate" --startTime "2017-07-24T00:00:00Z" --endTime "2017-07-31T23:59:59Z"'

sleep $SLEEP_TIME
seperate

echo "Scenario: Aggregate - 14 day"
ssh -o StrictHostKeyChecking=no $CLIENT_IP 'python3 /test.py --repetitions 20 --requestType "aggregate" --startTime "2017-07-17T00:00:00Z" --endTime "2017-07-31T23:59:59Z"'

sleep $SLEEP_TIME
seperate

echo "Scenario: Aggregate - 30 day"
ssh -o StrictHostKeyChecking=no $CLIENT_IP 'python3 /test.py --repetitions 20 --requestType "aggregate" --startTime "2017-06-30T00:00:00Z" --endTime "2017-07-31T23:59:59Z"'

sleep $SLEEP_TIME
seperate