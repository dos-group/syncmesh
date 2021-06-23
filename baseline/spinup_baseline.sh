#!/bin/bash

usernam=kreutz
CSV=2017-07_bme280sof.csv

CSV_list=("xaa" "xab" "xac")

#enter external ips of our sensor nodes
sensor_list=("35.225.152.156" "34.70.48.221" "34.72.45.142")

#Split csv in 3 ~equal-sized parts
LENGTHCSV=$(wc -l < $CSV)
declare -i n
n=$LENGTHCSV/3
split -l $n $CSV

#rm -f $1

#add headline to splitted files (change later to account for multiple nodes)
sed -i 1i",sensor_id,location,lat,lon,timestamp,pressure,temperature,humidity" xab
sed -i 1i",sensor_id,location,lat,lon,timestamp,pressure,temperature,humidity" xac

#gcloud compute instances list | awk '{print $1}' > instances.txt
#ls *.csv > csvList.txt



#Transfer each *.csv to one of the sensor-nodes and rename
for i in "${!CSV_list[@]}"; do
	scp ${CSV_list[i]} $username@${sensor_list[i]}:~/data.csv
	scp transfer_master.sh $username@${sensor_list[i]}:~/
	scp calc_avg.py $username@${sensor_list[i]}:~/
done