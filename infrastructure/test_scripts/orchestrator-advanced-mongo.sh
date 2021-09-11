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

uploadData() {
# First Argument is the days for the import script

while read internalIP; do
    echo "SHH $internalIP"
    ssh -o StrictHostKeyChecking=no $internalIP "mongoimport -h $SERVER_IP:$PORT --type csv -d syncmesh -c sensor_data --headerline --drop /import$1.csv" < /dev/null
done < /nodes.txt

# Fix Dates
ssh -o StrictHostKeyChecking=no $SERVER_IP "mongo --host localhost:27017 <<-EOF
    use syncmesh
    db.sensor_data.find().forEach(function(doc) {
    doc.timestamp=new Date(doc.timestamp);
    db.sensor_data.save(doc);
    })
EOF
"
}

# queryDataCollect() {
# # First Argument is the Start ISODate

# # Maybe use .aggregate({ $replaceWith: "$pressure" })
# read -r -d '' COMMAND <<EOF
# use syncmesh
# db.sensor_data.find({
#     timestamp: {
#         \$gte: ISODate("$1"),
#         \$lt: ISODate("2017-07-31T23:59:59Z")
#     }
# }, { timestamp: 1, pressure: 1, temperature: 1, humidity: 1, _id: 0 }).toArray()
# EOF

# for i in $(seq $REPETITIONS)
# do
#     # Query Data 
#     ssh -o StrictHostKeyChecking=no $CLIENT_IP "mongo --host $SERVER_IP:$PORT <<'EOF'
#     $COMMAND
# EOF
# " 1> /dev/null
# echo "Finished Mongo Request"
# done
# }

queryDataAggregate() {
# First Argument is the Start ISODate

# Maybe use .aggregate({ $replaceWith: "$pressure" })
read -r -d '' COMMAND <<EOF
use syncmesh
db.sensor_data.aggregate([{ 
    \$match: {
      timestamp: {
        \$gte: ISODate("$1"),
        \$lt: ISODate("2017-07-31T23:59:59Z")
        } 
    } 
  },{
    \$group: {
        _id: null,
        avgTemperature: { \$avg: "\$temperature" }, 
        avgPressure: { \$avg: "\$pressure" },
        avgHumidity: { \$avg: "\$humidity" }
    }
}]) 
EOF

for i in $(seq $REPETITIONS)
do
    # Query Data 
    ssh -o StrictHostKeyChecking=no $CLIENT_IP "mongo --host $SERVER_IP:$PORT <<'EOF'
    $COMMAND
EOF
"
echo "Finished Mongo Request"
done
}



seperate

# Collect
echo "Scenario: Collect - 1 day"
# Write Data Once to central database
uploadData 1
#queryDataCollect "2017-07-31T00:00:00Z"


sleep $SLEEP_TIME
seperate

echo "Scenario: Collect - 7 day"

uploadData 7
#queryDataCollect "2017-07-24T00:00:00Z"


sleep $SLEEP_TIME
seperate

echo "Scenario: Collect - 14 day"

uploadData 14
#queryDataCollect "2017-07-17T00:00:00Z"

sleep $SLEEP_TIME
seperate

echo "Scenario: Collect - 30 day"

uploadData 30
#queryDataCollect "2017-06-30T00:00:00Z"

sleep $SLEEP_TIME
seperate


# Aggregate
echo "Scenario: Aggregate - 1 day"
# Write Data Once to central database
uploadData 1
#queryDataAggregate "2017-07-31T00:00:00Z"


sleep $SLEEP_TIME
seperate

echo "Scenario: Aggregate - 7 day"

uploadData 7
queryDataAggregate "2017-07-24T00:00:00Z"


sleep $SLEEP_TIME
seperate

echo "Scenario: Aggregate - 14 day"

uploadData 14
queryDataAggregate "2017-07-17T00:00:00Z"

sleep $SLEEP_TIME
seperate

echo "Scenario: Aggregate - 30 day"

uploadData 30
queryDataAggregate "2017-06-30T00:00:00Z"

sleep $SLEEP_TIME
seperate


