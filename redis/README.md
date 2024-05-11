# Redis

## Notes from Day 1

* Book use v 3.2.8 - I use 7.2.4 (but 6.0.16 of the CLI - default `apt` for Ubuntu 22.04)
* "Data structure server" is a really good description of Redis
* Tested with parallel BRPOP (multiple consumers) -> round-robin ~"load sharing" (not duplicated processing)

### Scratch pad

```console
$ redis-cli
127.0.0.1:6379> PING
PONG
```

```redis
SET 7wks http://www.sevenweeks.org/
GET 7wks

MSET gog http://www.google.com yah http://www.yahoo.com
MGET gog yah

```console
127.0.0.1:6379> SET count 2
OK
127.0.0.1:6379> INCR count
(integer) 3
127.0.0.1:6379> GET count
"3"
```

```redis
MULTI
SET prag http://pragprog.com
INCR count
EXEC
```

```redis
HMSET user:ulf name Ulf password s3cr3!
HLEN user:ulf
HVALS user:ulf
HKEYS user:ulf
HGETALL user:ulf
HGET user:ulf password
```

```redis
RPUSH eric:wishlist 7wks gog prag
LLEN eric:wishlist
LRANGE eric:wishlist 0 -1
LREM eric:wishlist 0 gog
LPOP eric:wishlist
```

> ***Hmmm...***
>
> The book claims that this will _not_ work due to restrictions in Redis but it worked well for me.
>
> ```shell
> ruby ./list-move.rb 
> ```
> 
> ```console
> 127.0.0.1:6379> LRANGE eric:wishlist 0 -1
> (empty array)
> 127.0.0.1:6379> LRANGE eric:visited 0 -1
> 1) "prag"
> ```

```redis
RPUSH eric:wishlist gog
RPOPLPUSH eric:wishlist eric:visited
LRANGE eric:wishlist 0 -1
LRANGE eric:visited 0 -1
```

```redis
BRPOP comments 300
```

```redis
LPUSH comments "Prag is a great publisher"
```

```redis
SADD news nytimes.com pragprog.com
SMEMBERS news

SADD tech pragprog.com apple.com
SINTER news tech
SDIFF news tech
SDIFF tech news
SUNION news tech

SUNIONSTORE websites news tech
SMEMBERS websites

SCARD websites
```

```redis
ZADD visits 500 7wks 9 gog 9999 prag
ZRANGE visits 0 -1
ZINCRBY visits 1 prag
ZRANGE visits 0 -1 WITHSCORES
ZREVRANGE visits 0 -1 WITHSCORES
ZRANGEBYSCORE visits 9 10000
ZRANGEBYSCORE visits (9 10000
ZRANGEBYSCORE visits -inf inf
ZREVRANGEBYSCORE visits inf -inf
```

```redis
ZADD votes 2 7wks 0 gog 9001 prag
ZUNIONSTORE imp 2 visits votes WEIGHTS 1 2 AGGREGATE SUM
ZRANGE imp 0 -1 WITHSCORES

ZUNIONSTORE votes 1 votes WEIGHTS 2
```

```redis
SET ice "I'm melting..."
EXPIRE ice 10
EXISTS ice
GET ice
TTL ice
PERSIST ice
```

```redis
SET greeting hello
SELECT 1
SET greeting "guten Tag"
GET greeting
SELECT 0
GET greeting

MOVE greeting 2
SELECT 2
GET greeting
```

### Homework

* The [Command docs](https://redis.io/docs/latest/commands/) provide filtering and searching.
  * Under each command, details on complexity (and more) can be found
  * Example: [RPOP](https://redis.io/docs/latest/commands/rpop/), with complexity _O(N)_

#### Testing Python integration

See [Python example](./python-example/README.md), which includes connect, popping and pushing.

Two consumers?

I tested with two instances of the "consumer" (two BRPOP from the same list). The values pushed by the producer ended up in one or the other (round robin)

```console
$ python test_producer.py
Connecting...
✅ Connected
Pushing numbers...
 - 1
 - 2
 - 3
 - 4
 - 5
✅ done
```  

```console
$ python test_consumer.py
Connecting...
✅ Connected
Test blocking pop...
✅ popped: ('numbers', '1')
✅ popped: ('numbers', '3')
✅ popped: ('numbers', '5')
```

```console
$ python test_consumer.py
Connecting...
✅ Connected
Test blocking pop...
✅ popped: ('numbers', '2')
✅ popped: ('numbers', '4')
```

## Notes from Day 2

* Section on security feels a bit outdated when reading the [docs](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)
  * But maybe still not "state-of-the-art security"...
* The "renaming" option for hiding/disabling dangerous commands is somewhat unique
* The `redis-benchmark` tool is cool!
* My "Data Dump" experiments didn't run very fast (nor did I get `hiredis` working)
  * Unclear if it was because of my containerized `ruby` or `redis-server`
* The SETBIT/GETBIT support is kind of cool/special for a database I think
* Isn't there a lot more to "Redis Cluster" than what's described in the book?
  * [Redis Cluster 101](https://redis.io/docs/latest/operate/oss_and_stack/management/scaling/) states:
  * _"Redis Cluster provides a way to run a Redis installation where data is automatically sharded across multiple Redis nodes. Redis Cluster also provides some degree of availability during partitions"_
    * _"Automatically split your dataset among multiple nodes."_
    * _"Continue operations when a subset of the nodes are experiencing failures or are unable to communicate with the rest of the cluster."_


### Scratch pad

```console
$ telnet localhost 6379
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
SET test hello
+OK
GET test
$5
hello
SADD stest 1 99
:2
SMEMBERS stest
*2
$1
1
$2
99
```

> _Exit_ `telnet` is tricky!

```console
$ (echo -en "PING\r\nPING\r\nPING\r\n"; sleep 1) | nc localhost 6379
+PONG
+PONG
+PONG
^C
```

Subscribe to channel

```redis
SUBSCRIBE comments
```

Do this for multiple subscribers, then publish

```redis
PUBLISH comments "Checkout 7wks!"
```

Server Info:

```redis
INFO
```

(a lot of info)

```console
$ redis-benchmark
====== PING_INLINE ======
  100000 requests completed in 1.21 seconds
  50 parallel clients
  3 bytes payload
  keep alive: 1
  host configuration "save": 3600 1 300 100 60 10000
  host configuration "appendonly": no
  multi-thread: no

  :
  :

====== MSET (10 keys) ======
  100000 requests completed in 1.22 seconds
  50 parallel clients
  3 bytes payload
  keep alive: 1
  host configuration "save": 3600 1 300 100 60 10000
  host configuration "appendonly": no
  multi-thread: no

99.82% <= 1 milliseconds
99.99% <= 2 milliseconds
100.00% <= 2 milliseconds
81699.35 requests per second
```

Master-Slave replication

```console
$ cd redis-cluster

$ docker compose up
[+] Running 2/0
 ✔ Container redis-cluster-redis-master-1  Created                                                                       0.0s 
 ✔ Container redis-cluster-redis-slave-1   Created                                                                       0.0s 
Attaching to redis-master-1, redis-slave-1
  :
redis-master-1  | 1:M 10 May 2024 15:12:20.175 * Ready to accept connections tcp
  :
redis-slave-1   | 1:S 10 May 2024 15:12:20.237 * Before turning into a replica, using my own master parameters to synthesize a cached master: I may be able to synchronize with the new master with just a partial transfer.
redis-slave-1   | 1:S 10 May 2024 15:12:20.237 * Ready to accept connections tcp
redis-slave-1   | 1:S 10 May 2024 15:12:20.239 * Connecting to MASTER redis-master:6379
redis-slave-1   | 1:S 10 May 2024 15:12:20.240 * MASTER <-> REPLICA sync started
redis-slave-1   | 1:S 10 May 2024 15:12:20.240 * Non blocking connect for SYNC fired the event.
redis-slave-1   | 1:S 10 May 2024 15:12:20.240 * Master replied to PING, replication can continue...
redis-slave-1   | 1:S 10 May 2024 15:12:20.240 * Trying a partial resynchronization (request ffbf497124a9f1a1822d465be31101dd0af20558:239).
redis-master-1  | 1:M 10 May 2024 15:12:20.240 * Replica 172.20.0.4:6379 asks for synchronization
redis-master-1  | 1:M 10 May 2024 15:12:20.240 * Partial resynchronization request from 172.20.0.4:6379 accepted. Sending 0 bytes of backlog starting from offset 239.
redis-slave-1   | 1:S 10 May 2024 15:12:20.240 * Successful partial resynchronization with master.
redis-slave-1   | 1:S 10 May 2024 15:12:20.240 * Master replication ID changed to 45a7e9e88b0fe92639d48d67b084baa67fc348e5
redis-slave-1   | 1:S 10 May 2024 15:12:20.240 * MASTER <-> REPLICA sync: Master accepted a Partial Resynchronization.
```

```console
$ redis-cli -h redis-master
redis-master:6379> SADD meetings "StarTrel Pastry Chefs" "LARPers Intl." [member .
redis-master:6379> SADD meetings "StarTrel Pastry Chefs" "LARPers Intl."
(integer) 2
```

```console
$ redis-cli -h redis-slave
redis-slave:6379> SMEMBERS meetings
1) "StarTrel Pastry Chefs"
2) "LARPers Intl."
```

Data Dump

```shell
gem install redis
```

```console
$ ruby data_dump.rb 100000
100000 items in 9.185947267 seconds
```

> Without `hiredis` as that doesn't work any longer according to this [issue](https://github.com/redis/redis-rb/issues/1178)

```console
$ ruby data_dump_pipelined.rb 100000
100000 items in 9.287009866 seconds
```

Dual masters (use regular devcontainer-instance + master i my docker-compose cluster)

```shell
docker compose up
```

```console
$ ruby data_dump_cluster.rb 100000
100000 items in 13.018273455 seconds

$ redis-cli --raw GET key537


$ redis-cli -h redis-master --raw GET key537
value537

$ redis-cli --raw info keyspace
# Keyspace
db0:keys=51112,expires=0,avg_ttl=0

$ redis-cli -h redis-master --raw info keyspace
# Keyspace
db0:keys=48888,expires=0,avg_ttl=0
```

Bloom filters

```shell
gem install bloomfilter-rb
```

```shell
curl -O https://www.gutenberg.org/files/2701/old/moby10b.txt
```

```shell
ruby bloom_filter.rb moby10b.txt > bloom_result.txt
```

```console
$ head bloom_result.txt 
the
project
gutenberg
etext
of
moby
dick
by
herman
melville

$ tail bloom_result.txt 
dirgelike
padlocks
sheathed
deviouscruising
retracing
orphan
Total number of (cleaned) words: 214091
Number of words in filter: 125000
Number of filter matches: 194521
Number of false positives: 2393
```

> Do these numbers make sense?

### Homework

* Messaging patterns - Pub/Sub, Req/Rep, Msg Queue ...?
  * Redis clearly supports Pub/Sub
  * Also Msg Queue (blocking list pop)
  * Can probably be (mis?)used to realize Req/Rep as well
* [Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/):
  * _"Redis Sentinel provides high availability for Redis when not using [Redis Cluster](https://redis.io/docs/latest/operate/oss_and_stack/management/scaling/)"_
  * _"Redis Sentinel is a distributed system [...] Sentinel itself is designed to run in a configuration where there are multiple Sentinel processes cooperating together"_
  * Macro-level capabilities: Monitoring, Notification, Automatic (master) failover, Configuration provider.

(Won't do the "Do"s)
