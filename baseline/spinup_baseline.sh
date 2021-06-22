#!/bin/bash

usernam=kreutz
CSV=2017-07_bme280sof.csv

CSV_list=("xaa" "xab" "xac")
sensor_list=("34.77.58.246" "35.246.252.243" "35.246.252.243")

#Split csv in 3 ~equal-sized parts
LENGTHCSV=$(wc -l < $CSV)
declare -i n
n=$LENGTHCSV/3
split -l $n $CSV
#rm -f $1



#Transfer each *.csv to one of the sensor-nodes and rename
for i in "${!CSV_list[@]}"; do
	scp ${CSV_list[i]} $username@${sensor_list[i]}:~/data.csv
	scp transfer_master.sh $username@${sensor_list[i]}:~/
done