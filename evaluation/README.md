# How to obtain the data

Get Flow Logs for network traffic:
https://cloud.google.com/vpc/docs/flow-logs

Read on how to export Logs: https://cloud.google.com/logging/docs/export/configure_export_v2

1. Go to big Query
2. Select Database
3. Export to bucket
4. Download from there

```bash
# unzip
gzip -d export.gz
sudo apt update
sudo apt install -y tcpdump
# Only Headers
sudo tcpdump -ni any net 10.0.0.0/8 -w test5.pcap -s 96
# Full packages
sudo tcpdump -ni any net 10.0.0.0/8 -s 65535 -w test4.pcap
scp dnhb@34.135.226.204:/captures.zip /mnt/c/Develop/captures-grzip.zip
```

```SQL
SELECT timestamp, jsonPayload.bytes_sent, jsonPayload.rtt_msec, jsonPayload.connection.src_ip, jsonPayload.connection.dest_ip FROM `dspj-315716.syncmesh.compute_googleapis_com_vpc_flows_20210706`
WHERE jsonPayload.connection.src_ip = "10.2.0.10"
WHERE CAST(jsonPayload.bytes_sent AS int) > 100
ORDER BY timestamp
LIMIT 1000
```

```
resource.type="gce_subnetwork"
resource.labels.subnetwork_name="experiment-baseline-with-latency-3-subnetwork-2" OR resource.labels.subnetwork_name="experiment-baseline-with-latency-3-subnetwork-1" OR resource.labels.subnetwork_name="experiment-baseline-with-latency-3-subnetwork-1"
jsonPayload.connection.dest_ip="92.60.39.199" OR jsonPayload.connection.src_ip="92.60.39.199"
```

Add Monitoring to the project:
https://cloud.google.com/monitoring/agent/monitoring/installation
