from gcp_flowlogs_reader import Reader

credentials_path = './../infrastructure/credentials.json'
ip_set = set()
for flow_record in Reader(service_account_json=credentials_path):
    ip_set.add(flow_record.src_ip)
    ip_set.add(flow_record.dest_ip)

print(len(ip_set))