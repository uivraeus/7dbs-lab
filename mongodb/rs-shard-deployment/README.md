# Notes

The replica sets will be initialized via a Docker health probe which periodically executes one of the "rs-init" code snippets, stored in individual ENV variables (see [.env](.env)), depending on the server's role.

> Note that there is no replica set for the `mongos` server. The `addShard` operations that must be carried out manually (are not automated).

Adding shards (via mongosh):

```shell
mongosh mongodb://mongodb-mongos:27017/admin
```

```js
sh.addShard('shard1/mongodb-shard1-1:27017')
sh.addShard('shard2/mongodb-shard2-1:27017')
sh.status()
```

_Example:_

```console
[direct: mongos] admin> sh.addShard('shard1/mongodb-shard1-1:27017')
{
  shardAdded: 'shard1',
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1711045893, i: 5 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1711045893, i: 5 })
}
[direct: mongos] admin> sh.addShard('shard2/mongodb-shard2-1:27017')
{
  shardAdded: 'shard2',
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1711045903, i: 13 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1711045903, i: 3 })
}
[direct: mongos] admin> sh.status()
shardingVersion
{ _id: 1, clusterId: ObjectId('65fc7cd09cdce409ee8c453c') }
---
shards
[
  {
    _id: 'shard1',
    host: 'shard1/mongodb-shard1-1:27017,mongodb-shard1-2:27017,mongodb-shard1-3:27017',
    state: 1,
    topologyTime: Timestamp({ t: 1711045893, i: 2 })
  },
  {
    _id: 'shard2',
    host: 'shard2/mongodb-shard2-1:27017,mongodb-shard2-2:27017,mongodb-shard2-3:27017',
    state: 1,
    topologyTime: Timestamp({ t: 1711045903, i: 1 })
  }
]
---
active mongoses
[ { '7.0.6': 1 } ]
---
autosplit
{ 'Currently enabled': 'yes' }
---
balancer
{
  'Currently enabled': 'yes',
  'Currently running': 'no',
  'Failed balancer rounds in last 5 attempts': 0,
  'Migration Results for the last 24 hours': 'No recent migrations'
}
---
databases
[
  {
    database: { _id: 'config', primary: 'config', partitioned: true },
    collections: {
      'config.system.sessions': {
        shardKey: { _id: 1 },
        unique: false,
        balancing: true,
        chunkMetadata: [ { shard: 'shard1', nChunks: 1 } ],
        chunks: [
          { min: { _id: MinKey() }, max: { _id: MaxKey() }, 'on shard': 'shard1', 'last modified': Timestamp({ t: 1, i: 0 }) }
        ],
        tags: []
      }
    }
  }
]
```
