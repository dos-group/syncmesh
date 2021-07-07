#!/bin/bash
# ./aggregate_sensor_data.sh $day $week $month
# Parameters get subtracted from Last day of July
# This aggregates the data files from the subtracted date up until the last day of July from one node


username="dnhb"
MASTER_IP="34.78.87.225"
MASTER_IP_intern="10.2.0.3"
PORT="27017"

#time-query
currentTime=$(date --date="2017-07-31T24:00:00 -$1 days -$2 week -$3 month" +%s)

#echo $currentTime
#awk -F '|' -v dateStart="$currentTime" '{if (FNR>1 && dateStart>=$5) {print}}' "import.csv" >>data.csv



printf "sensor_id,location,lat,lon,timestamp,pressure,temperature\n" > data.csv
while IFS=, read -r sensor_id location lat lon timestamp pressure temperature humidity; do
     temp=$(date --date="$timestamp" 	+%s)	
     if [ $temp -ge $currentTime ];
     then
         printf "$sensor_id,$location,$lat,$lon,$timestamp,$pressure,$temperature,$humidity\n" >> data.csv
     fi

done < import.csv
mv import.csv temp.csv
mv data.csv import.csv

#file transfer
while IFS=, read -u10 -r externalIP internalIP; do 
    echo "SHH into $externalIP ($internalIP)"
    ssh -o StrictHostKeyChecking=no $externalIP "mongoimport -h $MASTER_IP_intern:$PORT --type csv -d database_test -c test --headerline --drop /import.csv"
done 10< ips.txt

rm import.csv
mv temp.csv import.csv