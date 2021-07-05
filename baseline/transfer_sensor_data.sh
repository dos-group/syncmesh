#!/bin/bash

# Arguments: External IP of worker-nodes 
# Assummes: sensor_data in /data

declare -a sensor_list
for i in "$@"
do
    sensor_list=("${sensor_list[@]}" "$i")
done


declare -a CSV_list
for i in data/*.csv; do
    CSV_list=("${CSV_list[@]}" "$i")
done

echo $CSV_list

#Transfer each *.csv to one of the sensor-nodes and rename
for i in "${!sensor_list[@]}"; do
	sed -i 1i"sensor_id,location,lat,lon,timestamp,pressure,temperature,humidity" ${CSV_list[i]}
	scp ${CSV_list[i]} ${sensor_list[i]}:~/data.csv
done