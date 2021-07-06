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
