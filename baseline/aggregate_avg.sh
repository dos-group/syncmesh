#!/bin/bash

username=kreutz
CSV=2017-07_bme280sof.csv
sensor_list=("34.141.25.222") #TODO: extend for all nodes of certain tag
n="${#sensor_list[@]}"

for i in "${!sensor_list[@]}"; do
	ssh $username:${sensor_list[i]} 'python3 calc_avg.py' > ./results.txt
done