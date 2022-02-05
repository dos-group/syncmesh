#!/usr/bin/env python3
#
# Example:
# python3 test.py --repetitions 11 --requestType "list" --startTime "2017-06-30T00:00:00Z" --endTime "2017-07-01T00:00:00Z"
# python3 /test.py --requestType 'aggregate' --startTime 2017-07-31T00:00:00Z --endTime 2017-07-31T23:59:59Z
# python3 /test.py --requestType 'function' --startTime 2017-07-31T00:00:00Z --endTime 2017-07-31T23:59:59ZH

from time import time, sleep
import requests
import argparse
import sys
import json


# Defaults
repetitions = 1
filepath = '/nodes.txt'
request_type = 'aggregate'


def main(args):
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('-f', '--file', help="IP list file",
                        default=filepath, type=str)
    parser.add_argument('-r', '--repetitions',
                        help="Repetitions for the request", default=repetitions, type=int)
    parser.add_argument(
        '-l', '--limit', help="Document limit per node", default=0, type=int)
    parser.add_argument('-t', '--requestType',
                        help="The Request Type for Syncmesh Function (e.g. collect, aggregate)", default=request_type, type=str)
    parser.add_argument('--startTime', help="Start time for the query",
                        default="2017-06-30T00:00:00Z", type=str)
    parser.add_argument('--endTime', help="End time for the query",
                        default="2017-07-01T00:00:00Z", type=str)
    parser.add_argument('--deploy', help="Function Image to deploy",
                        default="", type=str)
    parser.add_argument('--function', help="Which function should be called additionally",
                        default="", type=str)
    parser.add_argument('--password', help="Faasd Admin password",
                        default="", type=str)

    args = parser.parse_args(args)

    with open(args.file) as f:
        ip_addresses = f.readlines()
        ips = ["http://" + ip.strip() + ":8080" +
               "/function/syncmesh-fn" for ip in ip_addresses]

        ip = ips[0]
        ip_list = ips[1:]
        print(f"Starting Measurement with args: ")
        print(args)

        query = f"{{sensors(start_time: \"{args.startTime}\", end_time: \"{args.endTime}\"){{temperature humidity pressure}}}}"
        body = {
            "query": query,
            "database": "syncmesh",
            "collection": "sensor_data",
            "request_type": args.requestType,
            "external_nodes": ip_list
        }
        if args.deploy != "":
            body["deploy_function_image"] = args.deploy

        if args.password != "":
            body["password"] = args.password

        if args.function != "":
            body["external_functions_name"] = [args.function]

        print(body)
        for i in range(args.repetitions):
            r = requests.post(ip, data=json.dumps(body))
            print(len(r.content))
            print(r.status_code, r.reason)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
