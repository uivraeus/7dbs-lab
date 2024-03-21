# Notes

The replica sets will be initialized via a Docker health probe which periodically executes one of the following four pieces of code, depending on the server's role.

> Note that there is no replica set for the `mongos` server. The `addShard` operations that must be carried out there are not automated here.

The config server (mongodb1):

```js
try {
  rs.status()
} catch (err) {
  rs.initiate({
    _id: 'configSet',
    configsvr: true,
    members: [
      { _id: 0, host: 'mongodb1:27017' }
    ]
  })
}
```

The first shard server (mongodb3):

```js
try {
  rs.status()
} catch (err) {
  rs.initiate({
    _id: 'shard1',
    members: [
      { _id: 0, host: 'mongodb3:27017' }
    ]
  })
}
```

The second shard server (mongodb4):

```js
try {
  rs.status()
} catch (err) {
  rs.initiate({
    _id: 'shard2',
    members: [
      { _id: 0, host: 'mongodb4:27017' }
    ]
  })
}
```

The connection string looks like this:

```shell
mongosh mongodb://mongodb2:27017
```