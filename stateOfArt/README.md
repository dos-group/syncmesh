# MongoDb sharded Setup

For a single node replicaSet 







errMsg:

"already initialized"
rsconf = rs.conf()
rsconf.members = [{_id:0, host: "35.198.165.251:27017"}]
rs.reconfig(rsconf, {force: true})

"was not started with replSet option"