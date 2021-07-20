#!/bin/bash

SERVER_IP=$(</server.txt)
CLIENT_IP="$(</client.txt)"
SEPERATOR_IP="$(</seperator.txt)"
PORT="27017"

REPETITIONS=20

SLEEP_TIME=120
PRE_TIME=60

seperate () {
    curl "https://$SEPERATOR_IP"
    sleep $PRE_TIME
}

seperate

# Collect
echo "Scenario: Collect - 1 day"
# Write Data Once to central database
while IFS=, read internalIP; do 
    echo "SHH $internalIP"
    ssh -o StrictHostKeyChecking=no $internalIP "mongoimport -h $SERVER_IP:$PORT --type csv -d database_test -c test --headerline --drop /import1.csv"
done < /nodes.txt

for i in $(seq $REPETITIONS)
do 
    # Query Data 
    ssh -o StrictHostKeyChecking=no $CLIENT_IP "mongo --host $SERVER_IP:$PORT <<EOF
use syncmesh
db.sensor_data.find({
    created_at: {
        $gte: ISODate("2017-07-31T00:00:00Z"),
        $lt: ISODate("2017-07-31T23:59:59Z")
    }
})
EOF"
done

sleep $SLEEP_TIME
seperate

echo "Scenario: Collect - 7 day"
for i in $(seq $REPETITIONS)
do 
    while IFS=, read internalIP; do 
        echo "SHH $internalIP"
        ssh -o StrictHostKeyChecking=no $internalIP "mongoimport -h $SERVER_IP:$PORT --type csv -d database_test -c test --headerline --drop /import7.csv"
    done < /nodes.txt

    # TODO: Client Request
done

sleep $SLEEP_TIME
seperate

echo "Scenario: Collect - 14 day"
for i in $(seq $REPETITIONS)
do 
    while IFS=, read internalIP; do 
        echo "SHH $internalIP"
        ssh -o StrictHostKeyChecking=no $internalIP "mongoimport -h $SERVER_IP:$PORT --type csv -d database_test -c test --headerline --drop /import14.csv"
    done < /nodes.txt

    # TODO: Client Request
done

sleep $SLEEP_TIME
seperate

echo "Scenario: Collect - 30 day"
for i in $(seq $REPETITIONS)
do 
    while IFS=, read internalIP; do 
        echo "SHH $internalIP"
        ssh -o StrictHostKeyChecking=no $internalIP "mongoimport -h $SERVER_IP:$PORT --type csv -d database_test -c test --headerline --drop /import30.csv"
    done < /nodes.txt

    # TODO: Client Request
done

sleep $SLEEP_TIME
seperate


# Aggregate
echo "Scenario: Aggregate - 1 day"
for i in $(seq $REPETITIONS)
do 
    while IFS=, read internalIP; do 
        echo "SHH $internalIP"
        ssh -o StrictHostKeyChecking=no $internalIP "mongoimport -h $SERVER_IP:$PORT --type csv -d database_test -c test --headerline --drop /import1.csv"
    done < /nodes.txt

    # TODO: Client Request
done

sleep $SLEEP_TIME
seperate

echo "Scenario: Aggregate - 7 day"
for i in $(seq $REPETITIONS)
do 
    while IFS=, read internalIP; do 
        echo "SHH $internalIP"
        ssh -o StrictHostKeyChecking=no $internalIP "mongoimport -h $SERVER_IP:$PORT --type csv -d database_test -c test --headerline --drop /import7.csv"
    done < /nodes.txt

    # TODO: Client Request
done

sleep $SLEEP_TIME
seperate

echo "Scenario: Aggregate - 14 day"
for i in $(seq $REPETITIONS)
do 
    while IFS=, read internalIP; do 
        echo "SHH $internalIP"
        ssh -o StrictHostKeyChecking=no $internalIP "mongoimport -h $SERVER_IP:$PORT --type csv -d database_test -c test --headerline --drop /import14.csv"
    done < /nodes.txt

    # TODO: Client Request
done

sleep $SLEEP_TIME
seperate

echo "Scenario: Aggregate - 30 day"
for i in $(seq $REPETITIONS)
do 
    while IFS=, read internalIP; do 
        echo "SHH $internalIP"
        ssh -o StrictHostKeyChecking=no $internalIP "mongoimport -h $SERVER_IP:$PORT --type csv -d database_test -c test --headerline --drop /import30.csv"
    done < /nodes.txt

    # TODO: Client Request
done

sleep $SLEEP_TIME
seperate


