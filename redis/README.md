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

