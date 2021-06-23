#!/bin/bash
#executed from master-node to calculate average from all sensors


#MASTER=test-node
username=kreutz
sensor_list=("35.225.152.156" "34.70.48.221" "34.72.45.142")

#run script on each node

averages=0
for i in "${!sensor_list[@]}"
do 
	let averages+=( $(ssh $username@${sensor_list[i]} 'python3 calc_avg.py data.csv humidity') )
done

echo $averages
#gcloud compute ssh test-node --command="./transfer_master.sh *.csv" 



#calculate AVG on master
#gcloud compute ssh test-node --command=""

