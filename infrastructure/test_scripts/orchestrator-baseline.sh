#!/bin/bash

SERVER_IP=$(</server.txt)
CLIENT_IP="$(</client.txt)"
SEPERATOR_IP="$(</seperator.txt)"
PORT="27017"

# Those variables are set in the Orchestratore Template
#REPETITIONS=20



uploadData() {
# First Argument is the days for the import script
do_only_on_first="--drop"
while read internalIP; do
    echo "SHH $internalIP"
    ssh -o StrictHostKeyChecking=no $internalIP "mongoimport -h $SERVER_IP:$PORT --type csv -d syncmesh -c sensor_data $do_only_on_first --headerline /import$1.csv" < /dev/null
    do_only_on_first=""
done < /nodes.txt

# Fix Dates
ssh -o StrictHostKeyChecking=no $SERVER_IP "mongo --networkMessageCompressors snappy --host localhost:27017 <<-EOF
    use syncmesh
    db.sensor_data.find().forEach(function(doc) {
    doc.timestamp=new Date(doc.timestamp);
    db.sensor_data.save(doc);
    })
EOF
"
}

queryDataCollect() {
# First Argument is the Start ISODate
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
    # Upload Data
    uploadData $2
    # Query Data 
    /usr/bin/time -ao server-collect.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo /usr/bin/time -ao /collect.timings -f '%E' mongo --networkMessageCompressors snappy --host $SERVER_IP:$PORT <<'EOF'
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
    # Upload Data
    uploadData $2
    # Query Data 
    /usr/bin/time -ao server-aggregate.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo /usr/bin/time -ao /aggregate.timings -f '%E' mongo --networkMessageCompressors snappy --host $SERVER_IP:$PORT <<'EOF'
    $COMMAND
EOF
" 1> /dev/null
echo "Finished Mongo Request"
done
}