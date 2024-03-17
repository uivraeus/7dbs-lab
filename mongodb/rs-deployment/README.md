# Notes

The replica set will be initialized via a Docker health probe which periodically executes the following piece of code on one of the containers (mongodb1).

```js
try {
  rs.status()
} catch (err) {
  rs.initiate({
    _id: 'rs0',
    members: [
      { _id: 0, host: 'mongodb1:27017', priority: 1 },
      { _id: 1, host: 'mongodb2:27017', priority: 0.5 },
      { _id: 2, host: 'mongodb3:27017', priority: 0.5 }
    ]
  })
}
```

The connection string looks like this:

```shell
mongosh mongodb://mongodb1:27017,mongodb2:27017,mongodb3:27017/?replicaSet=rs0
```