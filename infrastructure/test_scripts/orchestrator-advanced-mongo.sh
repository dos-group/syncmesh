#!/bin/bash

SERVER_IP=$(</server.txt) #10.0.0.3
CLIENT_IP="$(</client.txt)" #10.0.0.2
SEPERATOR_IP="$(</seperator.txt)" #92.60.39.199
PORT="27017"

# Those variables are set in the Orchestratore Template
#REPETITIONS=20


queryDataCollect() {
# # First Argument is the Start ISODate

 # Maybe use .aggregate({ $replaceWith: "$pressure" })
read -r -d '' COMMAND <<EOF
use syncmesh
db.sensor_data.find({
    timestamp: {
        \$gte: ISODate("$1"),
        \$lt: ISODate("2017-07-31T23:59:59Z")
    }
}, { timestamp: 1, pressure: 1, temperature: 1, humidity: 1, _id: 0 }).toArray()
EOF

for i in $(seq $REPETITIONS)
do
    # Query Data
    /usr/bin/time -ao collect.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "mongo --networkMessageCompressors snappy --host $SERVER_IP:$PORT <<'EOF'
    $COMMAND
EOF
" 1> /dev/null
echo "Finished Mongo Request"
done
}

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
    /usr/bin/time -ao aggregate.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "mongo --networkMessageCompressors snappy --host $SERVER_IP:$PORT <<'EOF'
    $COMMAND
EOF
"
echo "Finished Mongo Request"
done
}