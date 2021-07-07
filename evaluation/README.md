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
```

```SQL
SELECT timestamp, jsonPayload.bytes_sent, jsonPayload.rtt_msec, jsonPayload.connection.src_ip, jsonPayload.connection.dest_ip FROM `dspj-315716.syncmesh.compute_googleapis_com_vpc_flows_20210706`
WHERE jsonPayload.connection.src_ip = "10.2.0.10"
WHERE CAST(jsonPayload.bytes_sent AS int) > 100
ORDER BY timestamp
LIMIT 1000
```
