#!/bin/bash

username=kreutz
CSV=2017-07_bme280sof.csv
sensor_list=("34.141.25.222" "34.141.25.222" "34.141.25.222") #TODO: extend for all nodes of certain tag
n="${#sensor_list[@]}"

#CSV, n:=#splits
split_csv() {
	cp $CSV data
	cd data
	LENGTHCSV=$(wc -l < $1)
	n=$(($LENGTHCSV/$2))
	split -l $n --additional-suffix=.csv $1
	rm $CSV
	cd ..
}


split_csv $CSV $n


declare -a CSV_list
for i in data/*.csv; do
    CSV_list=("${CSV_list[@]}" "$i")
done

echo $CSV_list

#Transfer each *.csv to one of the sensor-nodes and rename
for i in "${!CSV_list[@]}"; do
	sed -i 1i",sensor_id,location,lat,lon,timestamp,pressure,temperature,humidity" ${CSV_list[i]}
	scp ${CSV_list[i]} ${sensor_list[i]}:~/data.csv
done

#rm -f $1


#gcloud compute instances list | awk '{print $1}' > instances.txt
#ls *.csv > csvList.txt