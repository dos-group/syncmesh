#!/usr/bin/env python3
import argparse
import sys
import time
import json

import requests


def main(args):
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('-d', '--delay', help="Time delay in seconds", default=60, type=int)
    parser.add_argument('-f', '--file', help="IP list file", default='ips.txt', type=str)
    parser.add_argument('-l', '--limit', help="Document limit per node", default=10, type=int)
    parser.add_argument('--start_time', help="Start time for the query", default="2017-06-30T00:00:00Z", type=str)
    parser.add_argument('--end_time', help="End time for the query", default="2017-08-01T00:00:00Z", type=str)

    args = parser.parse_args(args)
    print(args)
    with open(args.file) as f:
        ip_addresses = f.readlines()
    ips = ["http://" + ip.strip() + "/function/syncmesh-fn" for ip in ip_addresses]
    for ip in ips:
        ip_list = ips.copy()
        ip_list.remove(ip)
        print(get_request_body(limit=args.limit, start_time=args.start_time,
                                                     end_time=args.end_time,
                                                     external_nodes_list=ip_list))
        r = requests.post(ip, data=get_request_body(limit=args.limit, start_time=args.start_time,
                                                     end_time=args.end_time,
                                                     external_nodes_list=ip_list))
        print(r.status_code, r.reason)
        time.sleep(args.delay)


def get_request_body(limit: int, start_time: str, end_time: str, external_nodes_list: [str], aggregate=False):
    query = f"{{sensors(start_time: \"{start_time}\", end_time: \"{end_time}\"){{temperature humidity pressure}}}}"
    request_type = "collect"
    if aggregate:
        request_type = "aggregate"
    return json.dumps({
        "query": query,
        "database": "syncmesh",
        "collection": "sensor_data",
        "request_type": request_type,
        "external_nodes": external_nodes_list
    })


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))