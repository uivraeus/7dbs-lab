# CouchDB

## Notes from Day 1

* Robust solution; "crash-only design"
* No "Admin Party" in v3
* Simple/straight-forward CRUD strategy but a bit cumbersome to follow "manually" (many fields to explicitly provide)
* Versions (revisions) and how to reference them is a bit unclear (when does `If-Match` work?)  
 
### Scratch pad

Status check:

```rest
GET http://localhost:5984
```

Fauxton (web) UI: <http://localhost:5984/_utils/>

* Create initial "music" database with "The Beatles" document.
* Multiple revisions

```rest
GET http://localhost:5984/music/
```

> ***First attempt: 401 Unauthorized***
>
> ```json
> {
>   "error": "unauthorized",
>   "reason": "You are not authorized to access this db."
> }
> ```
>
> Config public permissions by clearing the `_admin` roles from `members` and `admins`, according to [the docs](https://docs.couchdb.org/en/stable/api/database/security.html#db-security)
>

Confirm public access:

```rest
GET http://localhost:5984/music/
```

Custom variables (simplify subsequent requests):

```rest
@COUCH_ROOT_URL = http://localhost:5984
```

```rest
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e0004eb
```

```rest
POST {{COUCH_ROOT_URL}}/music/
Content-Type: application/json

{
  "name": "Wings"
}
```

> ***Response: 201 Created***
>
> ```json
> {
>   "ok": true,
>   "id": "992aa69aef40256536a422d51e00799d",
>   "rev": "1-2fe1dd1911153eb9df8460747dfe75a0"
> }
> ```

```rest
PUT {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e0088b3
Content-Type: application/json

{
  "_id": "992aa69aef40256536a422d51e0088b3",
  "_rev": "1-2fe1dd1911153eb9df8460747dfe75a0",
  "name": "Wings",
  "albums": ["Wild Life", "Band on the Run", "London Town"]
}
```

> ***Response: 201 Created***
>
> ```json
>   :
> ETag: "2-17e4ce41cd33d6a38f04a8452d5a860b"
>   :
> {
>   "ok": true,
>   "id": "992aa69aef40256536a422d51e0088b3",
>   "rev": "2-17e4ce41cd33d6a38f04a8452d5a860b"
> }
> ```

```rest
DELETE {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e0088b3
If-Match: 2-17e4ce41cd33d6a38f04a8452d5a860b
```

> ***Response: 200 OK***
> 
> ```json
>   :
> ETag: "3-42aafb7411c092614ce7c9f4ab79dc8b"
>   :
> {
>   "ok": true,
>   "id": "992aa69aef40256536a422d51e0088b3",
>   "rev": "3-42aafb7411c092614ce7c9f4ab79dc8b"
> }
> ```

> ***`If-Match` HTTP Header***
>
> [_Conditional_ request based on `ETag` value](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match) (which obviously corresponds to the `_rev` field)

### Homework

Other supported HTTP methods:

* HEAD
* COPY


#### Document with custom `_id`

```rest
POST {{COUCH_ROOT_URL}}/music/
Content-Type: application/json

{
  "_id": "ulf0001"
}
```

```rest
DELETE {{COUCH_ROOT_URL}}/music/ulf0001
If-Match: 1-967a00dff5e02add41819138abb3284d
```

#### Create/delete database (as server admin)

```rest
curl -X PUT -u couch:couch {{COUCH_ROOT_URL}}/newdb
```

```rest
curl -X DELETE -u couch:couch {{COUCH_ROOT_URL}}/newdb
```

#### Document with attachment

##### First create the document

```rest
POST {{COUCH_ROOT_URL}}/music/
Content-Type: application/json

{
  "name": "Scooter"
}
```

> ***Response: 201 Created***
>
> ```json
> {
>   "ok": true,
>   "id": "992aa69aef40256536a422d51e00ae7f",
>   "rev": "1-3a1e23bf54a67a86df15e36a72cc493c"
> }
> ```

##### The attach according to the [API docs](https://docs.couchdb.org/en/stable/api/document/attachments.html#put--db-docid-attname)

```rest
PUT {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f/members.txt
Content-Type: text/plain
If-Match: 1-3a1e23bf54a67a86df15e36a72cc493c

H. P. Baxxter,
Marc Blou
Jay Frog
Jens Thele
```

> ***Response: 201 Created***
>
> ```json
>   :
> Location: http://localhost:5984/music/992aa69aef40256536a422d51e00ae7f/members.txt
>   :
> {
>   "ok": true,
>   "id": "992aa69aef40256536a422d51e00ae7f",
>   "rev": "2-1e26ba1b039e4246b613993d58ce0a90"
> }
> ```

Confirm/inspect:

```rest
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f
```

> ***Response: 200 OK***
>
> ```json
> {
>   "_id": "992aa69aef40256536a422d51e00ae7f",
>   "_rev": "2-1e26ba1b039e4246b613993d58ce0a90",
>   "name": "Scooter",
>   "_attachments": {
>     "members.txt": {
>       "content_type": "text/plain",
>       "revpos": 2,
>       "digest": "md5-5NM3daPMMIobxRxJ5GAlJQ==",
>       "length": 44,
>       "stub": true
>     }
>   }
> }
> ```

##### Fetch the attachment according to the [API docs](https://docs.couchdb.org/en/stable/api/document/attachments.html#get--db-docid-attname)

```rest
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f/members.txt
If-Match: 2-1e26ba1b039e4246b613993d58ce0a90
```

> ***Response: 200 OK***
>
> ```text
>   :
> Content-MD5: 5NM3daPMMIobxRxJ5GAlJQ==
>   :
> ETag: "5NM3daPMMIobxRxJ5GAlJQ=="
>   :
>
> H. P. Baxxter,
> Marc Blou
> Jay Frog
> Jens Thele
> ```

> `If-Match` required?
>
> The docs indicates that it's not optional but the query works without it. Why?

##### Alternative with cURL and external file

```rest
curl -X PUT --header 'Content-Type: text/plain' --header 'If-Match: 2-1e26ba1b039e4246b613993d58ce0a90' --data '@former-scooter-members.txt' http://localhost:5984/music/992aa69aef40256536a422d51e00ae7f/former-members.txt
```

> ***Response: 201 Created*** 
>
> ```json
> {
>   "ok": true,
>   "id": "992aa69aef40256536a422d51e00ae7f",
>   "rev": "3-fab8a962fc27ecd15fb8d6a39434a935"
> }
> ```

```rest
curl --header 'If-Match: 3-fab8a962fc27ecd15fb8d6a39434a935' http://localhost:5984/music/992aa69aef40256536a422d51e00ae7f/former-members.txt
```

##### Update `members.txt`

```rest
PUT {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f/members.txt
Content-Type: text/plain
If-Match: 3-fab8a962fc27ecd15fb8d6a39434a935

H. P. Baxxter,
Marc Blou
Jay Frog
Jens Thele
party-ulf
```

> ***Response: 201 Created*** 
>
> ```json
> {
>   "ok": true,
>   "id": "992aa69aef40256536a422d51e00ae7f",
>   "rev": "4-e5258472d0007f7415145790033e3fe1"
> }
> ```

```rest
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f/members.txt
```

> ***Response: 200 OK***
>
> ```text
> H. P. Baxxter,
> Marc Blou
> Jay Frog
> Jens Thele
> party-ulf
> ```

***Earlier version of the document***

According to the [API docs](https://docs.couchdb.org/en/stable/api/document/attachments.html#get--db-docid-attname), the `If-Match` header should behave like the `rev` query parameter. But it doesn't!?

```rest
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f/members.txt
If-Match: 3-fab8a962fc27ecd15fb8d6a39434a935
```

> Still returns the latest attachment! (with "party-ulf")

```rest
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f/members.txt?rev=3-fab8a962fc27ecd15fb8d6a39434a935
```

> Returns the previous attachment, like expected.
>
> Doc-typo? For [regular document GET](https://docs.couchdb.org/en/stable/api/document/common.html#obtaining-a-specific-revision) it looks like the query parameter is the only option.

## Notes from Day 2

* Confusing instructions on how (/if) to test map-functions when creating a new view in Fauxton.
  * But I like the Fauxton tool/app. Very convenient.
* "Emitted" entries from map-functions are presented in alphabetical order
  * Pick "keys" that fit this fact
* General [intro to views in the docs](https://docs.couchdb.org/en/stable/ddocs/views/intro.html) was a good complement to the book

  > _"If you have a lot of documents, that takes quite a bit of time and you might wonder if it is not horribly inefficient to do this. Yes, it would be, but CouchDB is designed to avoid any extra costs: it only runs through all documents once, when you first query your view. If a document is changed, the map function is only run once, to recompute the keys and values for that single document"_

* The value emitted is stored explicitly, i.e. if the entire `doc` is emitted it implies doubled storage of it. See this [Stack Overflow answer](https://stackoverflow.com/a/36213957) for details.
 
### Scratch pad

```rest
GET {{COUCH_ROOT_URL}}/music/_all_docs
```

```rest
GET {{COUCH_ROOT_URL}}/music/_all_docs?include_docs=true
```

```rest
GET {{COUCH_ROOT_URL}}/music/_design/myLab
```

```rest
GET {{COUCH_ROOT_URL}}/music/_design/myLab/_view/my-rev
```

```rest
GET {{COUCH_ROOT_URL}}/music/_design/albums/_view/by_name
```

```rest
GET {{COUCH_ROOT_URL}}/music/_design/albums/_view/by_name/?key="Help!"
```

```shell
gem install libxml-ruby
```

```shell
gem install couchrest
```

```shell
curl -L -o dbdump_artistalbumtrack.xml.gz https://archive.org/download/jamendo-dbdump_artistalbumtrack-2011/dbdump_artistalbumtrack_20111231.xml.gz
```

> ***Obsolete link in the book***
>
> This download URL in the book doesn't exist any longer. Also, the reference (<http://developer.jamendo.com/en/wiki/DatabaseDumps>) in the [xml example](./jamendo-dbdata-example.xml) is broken.
>
> Luckily I found an archived dump instead.

```shell
zcat dbdump_artistalbumtrack.xml.gz | ruby import_from_jamendo.rb
```

```rest
GET {{COUCH_ROOT_URL}}/music/_design/albums/_view/by_name/?key="demo"
```

```rest
GET {{COUCH_ROOT_URL}}/music/_design/artists/_view/by_name/?limit=5
```

```rest
GET {{COUCH_ROOT_URL}}/music/_design/artists/_view/by_name/?limit=5&startkey="C"
```

```rest
GET {{COUCH_ROOT_URL}}/music/_design/artists/_view/by_name/?startkey="X"&endkey="Y"
```

```rest
GET {{COUCH_ROOT_URL}}/music/_design/artists/_view/by_name/?descending=true&startkey="Y"&endkey="X"
```

> Flipped `startkey`/`endkey` when reversed the order via `descending=true`

### Homework

* `emit()` - arrays as `key`
  * The whole array is the key (sorted with [0] as highest precedence)
  * Supports "group level" queries
    * Example: Date [arrays are used as keys](https://docs.couchdb.org/en/stable/ddocs/views/intro.html#find-many)
    * Example: [`group_level` query parameter](https://docs.couchdb.org/en/stable/ddocs/views/intro.html#the-view-to-get-comments-for-posts)
* Available view query parameters can be found in the [API docs](https://docs.couchdb.org/en/stable/api/ddoc/views.html#get--db-_design-ddoc-_view-view), examples:
  * `attachments` (boolean)
  * `inclusive_end` (boolean)
  * `skip`(number)
  * `sorted` (boolean)

#### Random artist

Inspect a document:

```rest
GET {{COUCH_ROOT_URL}}/music/5385
```

Using Fauxton, create a view `random`, index `artist`, with the following mapping function:

```js
function (doc) {
  if ('random' in doc && doc.name) {
    emit(doc.random, doc.name)
  }
}
```

```rest
GET {{COUCH_ROOT_URL}}/music/_design/random/_view/artist/?limit=1&startkey=0.9999999&endkey=0
```

Query with the following cURL command:

```shell
curl -s "http://localhost:5984/music/_design/random/_view/artist/?limit=1&startkey=$(ruby -e 'puts rand')" | jq
```

Strictly speaking there is a risk of getting en empty result it the random value is greater than the largest assigned during import.

```rest
GET {{COUCH_ROOT_URL}}/music/_design/random/_view/artist/?limit=1&descending=true
```

> ***Response (inner) body***
>
> ```json
> {
>   "id": "367592",
>   "key": 0.9999762693619031,
>   "value": "Patchy"
> }
> ```

```shell
curl -s "http://localhost:5984/music/_design/random/_view/artist/?limit=1&startkey=$(ruby -e 'puts [rand, 0.9999762693619031].min')" | jq
```

#### Random album, track and tag

Using Fauxton, add index `album` to view `random` with the following mapping function:

```js
function (doc) {
  if (doc.albums && doc.albums.length) {
    for (const album of doc.albums) {
      if ('random' in album && album.name) {
        emit(album.random, album.name)
      }
    }
  }
}
```

Similar for `track`:

```js
function (doc) {
  if (doc.albums && doc.albums.length) {
    for (const album of doc.albums) {
      if (album.tracks && album.tracks.length) {
        for (const track of album.tracks) {
          if ('random' in track && track.name) {
            emit(track.random, track.name)
          }
        }
      }
    }
  }
}
```

And for `tag`:

```js
function (doc) {
  if (doc.albums && doc.albums.length) {
    for (const album of doc.albums) {
      if (album.tracks && album.tracks.length) {
        for (const track of album.tracks) {
          if (track.tags && track.tags.length) {
            for (const tag of track.tags)
              if ('random' in tag && tag.idstr) {
                emit(tag.random, tag.idstr)
              }
          }
        }
      }
    }
  }
}
```

> ***The task is a bit unclear...***
>
> What's the desired "values" for album, track and tag? Better with objects where track, album and artist is included when picking a random tag?

Some test queries (ignoring the risk of missing the last entry):

```shell
curl -s "http://localhost:5984/music/_design/random/_view/album/?limit=1&startkey=$(ruby -e 'puts [rand, 0.9999762693619031].min')" | jq
curl -s "http://localhost:5984/music/_design/random/_view/track/?limit=1&startkey=$(ruby -e 'puts [rand, 0.9999762693619031].min')" | jq
curl -s "http://localhost:5984/music/_design/random/_view/tag/?limit=1&startkey=$(ruby -e 'puts [rand, 0.9999762693619031].min')" | jq
```

## Notes from Day 3

* _Incremental_ Map-Reduce (with "_rereducers_")
* Changes API
* Node v7 (ouch!) - current version as of trying this is v21!
* For the changes API, `since=now` is very useful (bit not mentioned)
* Replicas don't include older revisions
  * Why?
* The book didn't cover [Update Functions](https://docs.couchdb.org/en/stable/ddocs/ddocs.html#update-functions), which seems usable (for some tasks).
  * Especially since the earlier chapters have included sections on stored procedures etc.  
* Missing a section on access control (e.g. via [Validate Document Update Functions](https://docs.couchdb.org/en/stable/ddocs/ddocs.html#validate-document-update-functions))
  * Actually missing this topic for _all_ databases covered in the book
* The [_find](https://docs.couchdb.org/en/stable/api/database/find.html#api-db-find) API is not covered in the book (too new?)
  * Alternative to querying via views?
  * Selector syntax (more like MongoDB?)
  * Indexes for efficiency
* I would like to try something with PouchDB, e.g. test replication and offline availability in an browser app like [mentioned at in the docs](https://docs.couchdb.org/en/stable/replication/intro.html#migrating-data-to-clients).

### Scratch pad

```rest
GET {{COUCH_ROOT_URL}}/music/_changes
```

(Big/slow query - everything CouchDB has)

> ***Partial result***
>
> ```json
> {
>   "results": [
>     {
>       "seq": "4-g1AAAABteJzLYWBgYMpgTmHgzcvPy09JdcjLz8gvLskBCScyJNX___8_K5EBh4I8FiDJ0ACk_oPUZTAnsuQCBdgtzFJTzBKT0fVkAQAYWyJB",
>       "id": "992aa69aef40256536a422d51e0004eb",
>       "changes": [
>         {
>           "rev": "4-93a101178ba65f61ed39e60d70c9fd97"
>         }
>       ]
>     },
>     
>       :
>
>     {
>       "seq": "10039-g1AAAACReJzLYWBgYMpgTmHgzcvPy09JdcjLz8gvLskBCScyJNX___8_K4M5iYFBeH0uUIzdyDjJIMnEAF09DhPyWIAkQwOQ-o8wqANskIVZaopZYjK6tiwALd8sBw",
>       "id": "3775",
>       "changes": [
>         {
>           "rev": "1-45c33952b1001035f389abaaf03624c4"
>         }
>       ]
>     },
>     {
>       "seq": "10040-g1AAAACReJzLYWBgYMpgTmHgzcvPy09JdcjLz8gvLskBCScyJNX___8_K4M5iYFBeEMuUIzdyDjJIMnEAF09DhPyWIAkQwOQ-o8wqANskIVZaopZYjK6tiwALkYsCA",
>       "id": "348112",
>       "changes": [
>         {
>           "rev": "1-432df76766153fc365363cfec7abcaff"
>         }
>       ]
>     },
>     {
>       "seq": "10041-g1AAAACReJzLYWBgYMpgTmHgzcvPy09JdcjLz8gvLskBCScyJNX___8_K4M5iYFBeGMuUIzdyDjJIMnEAF09DhPyWIAkQwOQ-o8wqANskIVZaopZYjK6tiwALq0sCQ",
>       "id": "348113",
>       "changes": [
>         {
>           "rev": "1-9242b434ae44ed3cff04c302c49e25ab"
>         }
>       ]
>     }
>   ],
>   "last_seq": "10041-g1AAAACReJzLYWBgYMpgTmHgzcvPy09JdcjLz8gvLskBCScyJNX___8_K4M5iYFBeGMuUIzdyDjJIMnEAF09DhPyWIAkQwOQ-o8wqANskIVZaopZYjK6tiwALq0sCQ",
>   "pending": 0
> }
> ```
>
> 💡 Note the `seq` fields (and `last_seq`)

```rest
GET {{COUCH_ROOT_URL}}/music/_changes?since=10039-g1AAAACReJzLYWBgYMpgTmHgzcvPy09JdcjLz8gvLskBCScyJNX___8_K4M5iYFBeH0uUIzdyDjJIMnEAF09DhPyWIAkQwOQ-o8wqANskIVZaopZYjK6tiwALd8sBw
```

(Much shorter response, just the changes after, ie `10040-...` - `10041-...`)

> ***Long-polling (via cURL in a separate shell)***
>
> ```shell
> curl -s "http://localhost:5984/music/_changes?since=now&feed=longpoll"
> ```

> ***Continuous feed (via cURL in a separate shell)***
>
> ```shell
> curl -s "http://localhost:5984/music/_changes?since=now&feed=continuous"
> ```


Update my "Scooter" entry to observe the long-polling effects

```rest
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f
```

(To get the latest `_rev`)

```rest
PUT {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f
Content-Type: application/json

{
  "_id": "992aa69aef40256536a422d51e00ae7f",
  "_rev": "17-d822b07c2ce72de4bbb16c0176681a2a",
  "name": "Scooter",
  "trending": 13
}
```

***Filter changes***

```rest
PUT {{COUCH_ROOT_URL}}/music/_design/whereabouts
Authorization: Basic couch:couch
Content-Type: application/json

{
  "language": "javascript",
  "filters": {
    "by_country": "function(doc,req){return doc.country===req.query.country;}"
  }
}
```

> ***Returned: 201 Created***
>
> ```json
> {
>   "ok": true,
>   "id": "_design/whereabouts",
>   "rev": "1-2d26b247332c44647add5630fcdbe236"
> }
> ```

```rest
GET {{COUCH_ROOT_URL}}/music/_changes?filter=whereabouts/by_country&country=RUS
```

> Very slow query! ~25s!


***Query from replicated database***

> I changed the access policy to public for `music-repl` manually via Fauxton after replication.

```rest
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f
```

```rest
GET {{COUCH_ROOT_URL}}/music-repl/992aa69aef40256536a422d51e00ae7f
```

> ✅ Works (same)

```rest
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f/?rev=10-bb7a81b3f30636cd49edf2053aeda613
```

```rest
GET {{COUCH_ROOT_URL}}/music-repl/992aa69aef40256536a422d51e00ae7f/?rev=10-bb7a81b3f30636cd49edf2053aeda613
```

> ❌ rev 10 doesn't exist in the replicated database


***Creating conflicts***

```rest
POST {{COUCH_ROOT_URL}}/music/
Content-Type: application/json

{
  "_id": "myconflicts",
  "name": "My Conflicts"
}
```

```rest
GET {{COUCH_ROOT_URL}}/music/myconflicts
```

> ***Response: 201 Created***
>
> ```json
> {
>   "ok": true,
>   "id": "myconflicts",
>   "rev": "1-62e0802f3f311fd5c164de7597c7811b"
> }
> ```

```rest
GET {{COUCH_ROOT_URL}}/music-repl/myconflicts
```

> Works after manual replication trigger
>
> ```json
> {
>   "_id": "myconflicts",
>   "_rev": "1-62e0802f3f311fd5c164de7597c7811b",
>   "name": "My Conflicts"
> }
> ```


```rest
PUT {{COUCH_ROOT_URL}}/music-repl/myconflicts
Content-Type: application/json

{
  "_id": "myconflicts",
  "_rev": "1-62e0802f3f311fd5c164de7597c7811b",
  "name": "My Conflicts",
  "albums": ["Conflicts of Interest"]
}
```

> ***Response: 201 Created***
>
> ```json
> {
>   "ok": true,
>   "id": "myconflicts",
>   "rev": "2-8acf7f0dfacdea569f710c681f8681e9"
> }
> ```

```rest
PUT {{COUCH_ROOT_URL}}/music/myconflicts
Content-Type: application/json

{
  "_id": "myconflicts",
  "_rev": "1-62e0802f3f311fd5c164de7597c7811b",
  "name": "My Conflicts",
  "albums": ["Conflicting Opinions"]
}
```

> ***Response: 201 Created***
>
> ```json
> {
>   "ok": true,
>   "id": "myconflicts",
>   "rev": "2-26ee14140578ccafb87f7a1c6fe386b8"
> }
> ```

> Note the difference in `rev`

After yet another replication...

```rest
GET {{COUCH_ROOT_URL}}/music-repl/myconflicts
```

```rest
GET {{COUCH_ROOT_URL}}/music/myconflicts
```

> ❓Last update (in `music`) didn't "win", i.e. not the same "conflict resolution" as described in the book

```rest
GET {{COUCH_ROOT_URL}}/music-repl/myconflicts?conflicts=true
```

> ***Response: 200 OK***
>
> ```json
> {
>   "_id": "myconflicts",
>   "_rev": "2-8acf7f0dfacdea569f710c681f8681e9",
>   "name": "My Conflicts",
>   "albums": [
>     "Conflicts of Interest"
>   ],
>   "_conflicts": [
>     "2-26ee14140578ccafb87f7a1c6fe386b8"
>   ]
> }
> ```

```rest
GET {{COUCH_ROOT_URL}}/music-repl/myconflicts?rev=2-26ee14140578ccafb87f7a1c6fe386b8
```

> ***Response: 200 OK
>
> ```json
> {
>   "_id": "myconflicts",
>   "_rev": "2-26ee14140578ccafb87f7a1c6fe386b8",
>   "name": "My Conflicts",
>   "albums": [
>     "Conflicting Opinions"
>   ]
> }
> ```

> (So both versions exist on the replicated side)

### Homework

* [Built-in Reduce Functions](https://docs.couchdb.org/en/stable/ddocs/ddocs.html#built-in-reduce-functions) are implemented in Erlang and run inside CouchDB, so they are much faster than the equivalent JavaScript functions.
  * I noticed that my own reducer took a while so this seems useful
  * Available: `_approx_count_distinct`, `_count`, `_stats`, `_sum`
* In addition to custom (JS) filter functions (in design documents), the `_changes` API also enables ["filtering"](https://docs.couchdb.org/en/stable/api/database/changes.html#filtering) via:
  * [`_doc_ids`](https://docs.couchdb.org/en/stable/api/database/changes.html#doc-ids) - query param of payload of [POST request](https://docs.couchdb.org/en/stable/api/database/changes.html#post--db-_changes)
  * [`_selector`](https://docs.couchdb.org/en/stable/api/database/changes.html#selector) - significantly more efficient than using a JavaScript filter function and is the recommended option if filtering on document attributes only
  * [`_design`](https://docs.couchdb.org/en/stable/api/database/changes.html#design) - only changes for any design document within the requested database
  * [`_view`](https://docs.couchdb.org/en/stable/api/database/changes.html#view) - use existing map function as the filter
  * There are two types of "replication", transient (legacy), via the [`_replicate` API](https://docs.couchdb.org/en/stable/api/server/common.html#replicate) and persistent via the [`_replicator` database](https://docs.couchdb.org/en/stable/replication/replicator.html#replicator-database)
    * Both variants supports single and continuous replication (with filtering options etc)
    * Cancellation of continuous replication done via a `POST`, similar to the setup but with field `"cancel": true`. For persistent replications cancellation can also be done by deleting the replication document.
    * (Was it possible to configure _transient_ replication in Fauxton?)

#### Watch changes continuously

See [watchChangesContinuous.js](./watchChangesContinuous.js).

In paralell:

```shell
node watchChangesContinuous.js music now
```

```shell
node watchChangesLongpolling.js music now
```

> Make changes to Scooter document like above (when testing the _changes API)
>
> -> identical output
>
> But fetching _all_ changes (`since=0`) differs. Quick experiments with cURL shows that the order of the documents may differ (here and there). I.e.:
>
> ```shell
> curl -s "http://localhost:5984/music/_changes?feed=continuous"
> ```
>
> vs.
>
> ```shell
> curl -s "http://localhost:5984/music/_changes?feed=longpoll"
> ```

#### View for conflicting revisions

In `music-repl`, create design document "status" and view "conflicts" with the following map function:

```js
function (doc) {
  if (doc._conflicts) {
    for (const rev of doc._conflicts) {
      emit(doc._id, rev)
    }
  }
}
```

```rest
GET {{COUCH_ROOT_URL}}/music-repl/_design/status/_view/conflicts
```

> ***Response: 200 OK***
>
> ```json
> {
>   "total_rows": 2,
>   "offset": 0,
>   "rows": [
>     {
>       "id": "myconflicts",
>       "key": "myconflicts",
>       "value": "2-26ee14140578ccafb87f7a1c6fe386b8"
>     },
>     {
>       "id": "theconflicts",
>       "key": "theconflicts",
>       "value": "2-ba76584b2d0226f5849251b4f5aaed87"
>     }
>   ]
> }
> ```

(Somewhat unclear what the task was... why "map to doc _id"? The id is returned anyway)
