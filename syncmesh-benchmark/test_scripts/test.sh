#!/bin/bash

# Those variables are set in the Orchestratore Template
#SLEEP_TIME=120
#PRE_TIME=60
#REPETITIONS=20

seperate () {
    echo "Waiting for Sleep Time ($SLEEP_TIME s)"
    sleep $SLEEP_TIME
}


#!/bin/bash

CLIENT_IP="$(</client.txt)"




normal() {
# $1 - First Argument is the Start ISODate
for i in $(seq $REPETITIONS)
do
    # Query Data
    /usr/bin/time -ao server-normal.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP " sudo /usr/bin/time -ao /normal.timings -f '%E' python3 /test.py --requestType 'collect' --startTime $1 --endTime 2017-07-31T23:59:59Z" 1> /dev/null
    echo "Finished Request"
done
}


external_function() {
# $1 - First Argument is the Start ISODate
for i in $(seq $REPETITIONS)
do
    # Query Data
    /usr/bin/time -ao server-function.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP " sudo /usr/bin/time -ao /function.timings -f '%E' python3 /test.py --requestType 'function' --startTime $1 --endTime 2017-07-31T23:59:59Z" 1> /dev/null
    echo "Finished Request"
done
}

external_function_cold() {
# $1 - First Argument is the Start ISODate
for i in $(seq $REPETITIONS)
do
    while read internalIP; do
        echo "SHH $internalIP"
        ssh -o StrictHostKeyChecking=no $internalIP "curl -sS http://admin:\$(sudo cat /var/lib/faasd/secrets/basic-auth-password)@localhost:8080/system/scale-function/figlet -d '{\"serviceName\":\"echoit\", \"replicas\": 0}'" < /dev/null
    done < /nodes.txt
    # Query Data
    /usr/bin/time -ao server-cold.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP " sudo /usr/bin/time -ao /cold.timings -f '%E' python3 /test.py --requestType 'function' --startTime $1 --endTime 2017-07-31T23:59:59Z" 1> /dev/null
    echo "Finished Request"
done
}

external_function_cold_both() {
# $1 - First Argument is the Start ISODate
for i in $(seq $REPETITIONS)
do
    while read internalIP; do
        echo "SHH $internalIP"
        ssh -o StrictHostKeyChecking=no $internalIP "sudo faas list"
        ssh -o StrictHostKeyChecking=no $internalIP "curl -sS http://admin:\$(sudo cat /var/lib/faasd/secrets/basic-auth-password)@localhost:8080/system/scale-function/figlet -d '{\"serviceName\":\"echoit\", \"replicas\": 0}'" < /dev/null
        ssh -o StrictHostKeyChecking=no $internalIP "curl -sS http://admin:\$(sudo cat /var/lib/faasd/secrets/basic-auth-password)@localhost:8080/system/scale-function/figlet -d '{\"serviceName\":\"syncmesh-fn\", \"replicas\": 0}'" < /dev/null
        sleep 2
        ssh -o StrictHostKeyChecking=no $internalIP "sudo faas list"
    done < /nodes.txt
    # Query Data
    /usr/bin/time -ao server-cold-both.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo /usr/bin/time -ao /cold-both.timings -f '%E' python3 /test.py --requestType 'function' --startTime $1 --endTime 2017-07-31T23:59:59Z" 1> /dev/null
    echo "Finished Request"
done
}


external_function_fetch() {
# $1 - First Argument is the Start ISODate
for i in $(seq $REPETITIONS)
do
    while read internalIP; do
        echo "SHH $internalIP"
        ssh -o StrictHostKeyChecking=no $internalIP "ctr -n openfaas-fn t rm echoit --force" < /dev/null
    done < /nodes.txt
    # Query Data
    /usr/bin/time -ao server-fetch.timings -f '%E' ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo /usr/bin/time -ao /fetch.timings -f '%E' python3 /test.py --requestType 'function-fetch' --startTime $1 --endTime 2017-07-31T23:59:59Z" 1> /dev/null
    echo "Finished Request"
done
}



# Normal

seperate

echo "normal - 1 day"
normal "2017-07-31T00:00:00Z" 1

seperate

echo "normal - 7 day"
normal "2017-07-24T00:00:00Z" 7

seperate

echo "normal - 14 day"
normal "2017-07-17T00:00:00Z" 14

seperate

echo "normal - 30 day"
normal "2017-06-30T00:00:00Z" 30

seperate


# external_function


echo "external_function - 1 day"
external_function "2017-07-31T00:00:00Z" 1

seperate

echo "external_function - 7 day"
external_function "2017-07-24T00:00:00Z" 7

seperate

echo "external_function - 14 day"
external_function "2017-07-17T00:00:00Z" 14

seperate

echo "external_function - 30 day"
external_function "2017-06-30T00:00:00Z" 30

seperate


# external_function_cold

echo "external_function_cold - 1 day"
external_function_cold "2017-07-31T00:00:00Z" 1

seperate

echo "external_function_cold - 7 day"
external_function_cold "2017-07-24T00:00:00Z" 7

seperate

echo "external_function_cold - 14 day"
external_function_cold "2017-07-17T00:00:00Z" 14

seperate

echo "external_function_cold - 30 day"
external_function_cold "2017-06-30T00:00:00Z" 30

seperate

# external_function_cold_both

echo "external_function_cold_both - 1 day"
external_function_cold_both "2017-07-31T00:00:00Z" 1

seperate

echo "external_function_cold_both - 7 day"
external_function_cold_both "2017-07-24T00:00:00Z" 7

seperate

echo "external_function_cold_both - 14 day"
external_function_cold_both "2017-07-17T00:00:00Z" 14

seperate

echo "external_function_cold_both - 30 day"
external_function_cold_both "2017-06-30T00:00:00Z" 30

seperate


# external_function_fetch

# echo "external_function_fetch - 1 day"
# external_function_fetch "2017-07-31T00:00:00Z" 1

# seperate

# echo "external_function_fetch - 7 day"
# external_function_fetch "2017-07-24T00:00:00Z" 7

# seperate

# echo "external_function_fetch - 14 day"
# external_function_fetch "2017-07-17T00:00:00Z" 14

# seperate

# echo "external_function_fetch - 30 day"
# external_function_fetch "2017-06-30T00:00:00Z" 30

# seperate

echo "Benchmark script finished!"