import pandas as pd

project_id = '932771810925' # Our project ID
project = "dspj-315716"

ip_client = "10.1.0.2"
ip_server = "10.1.0.3"
ip_orchestrator = "10.1.0.255"
ip_seperator = "92.60.39.199"

allPreKnownServers = [ip_client, ip_server]
experiments = ["experiment-baseline-with-latency", "experiment-syncmesh-with-latency-3", "experiment-syncmesh-with-latency-6"]


def loadData(file):
    df = pd.read_json(file, lines = True)

    df = (pd.DataFrame(df['jsonPayload'].values.tolist())
            .add_prefix('jsonPayload.')
            .join(df.drop('jsonPayload', 1)))
    df = (pd.DataFrame(df['jsonPayload.connection'].values.tolist())
            .add_prefix('jsonPayload.connection.')
            .join(df.drop('jsonPayload.connection', 1)))
    df = df.dropna(subset=['jsonPayload.rtt_msec'])
    df = df.astype({
        'jsonPayload.bytes_sent': 'int32',
        'jsonPayload.rtt_msec': 'int32'
        })
    df = df.astype({'jsonPayload.connection.src_port': 'int32'})
    df = df.astype({'jsonPayload.connection.dest_port': 'int32'})
    # df.info()
    df.set_index('timestamp', inplace=True)
    return df