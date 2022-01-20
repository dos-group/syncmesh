
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


