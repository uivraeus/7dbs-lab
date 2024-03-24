# CouchDB

## Notes from Day 1

* Robust solution; "crash-only design"
* No "Admin Party" in v3
* Simple/straight-forward CRUD strategy but a bit cumbersome to follow "manually" (many fields to explicitly provide)
* Versions (revisions) and how to reference them is a bit unclear (when does `If-Match` work?)  
 
### Scratch pad

Status check:

```http
GET http://localhost:5984
```

Fauxton (web) UI: <http://localhost:5984/_utils/>

* Create initial "music" database with "The Beatles" document.
* Multiple revisions

```http
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

```http
GET http://localhost:5984/music/
```

Custom variables (simplify subsequent requests):

```http
@COUCH_ROOT_URL = http://localhost:5984
```

```http
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e0004eb
```

```http
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

```http
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

```http
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

```http
POST {{COUCH_ROOT_URL}}/music/
Content-Type: application/json

{
  "_id": "ulf0001"
}
```

```http
DELETE {{COUCH_ROOT_URL}}/music/ulf0001
If-Match: 1-967a00dff5e02add41819138abb3284d
```

#### Create/delete database (as server admin)

```http
curl -X PUT -u couch:couch {{COUCH_ROOT_URL}}/newdb
```

```http
curl -X DELETE -u couch:couch {{COUCH_ROOT_URL}}/newdb
```

#### Document with attachment

##### First create the document

```http
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

```http
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

```http
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

```http
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

```http
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

```http
curl --header 'If-Match: 3-fab8a962fc27ecd15fb8d6a39434a935' http://localhost:5984/music/992aa69aef40256536a422d51e00ae7f/former-members.txt
```

##### Update `members.txt`

```http
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

```http
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

```http
GET {{COUCH_ROOT_URL}}/music/992aa69aef40256536a422d51e00ae7f/members.txt
If-Match: 3-fab8a962fc27ecd15fb8d6a39434a935
```

> Still returns the latest attachment! (with "party-ulf")

```http
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

```http
GET {{COUCH_ROOT_URL}}/music/_all_docs
```

```http
GET {{COUCH_ROOT_URL}}/music/_all_docs?include_docs=true
```

```http
GET {{COUCH_ROOT_URL}}/music/_design/myLab
```

```http
GET {{COUCH_ROOT_URL}}/music/_design/myLab/_view/my-rev
```

```http
GET {{COUCH_ROOT_URL}}/music/_design/albums/_view/by_name
```

```http
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

```http
GET {{COUCH_ROOT_URL}}/music/_design/albums/_view/by_name/?key="demo"
```

```http
GET {{COUCH_ROOT_URL}}/music/_design/artists/_view/by_name/?limit=5
```

```http
GET {{COUCH_ROOT_URL}}/music/_design/artists/_view/by_name/?limit=5&startkey="C"
```

```http
GET {{COUCH_ROOT_URL}}/music/_design/artists/_view/by_name/?startkey="X"&endkey="Y"
```

```http
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

```http
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

```http
GET {{COUCH_ROOT_URL}}/music/_design/random/_view/artist/?limit=1&startkey=0.9999999&endkey=0
```

Query with the following cURL command:

```shell
curl -s "http://localhost:5984/music/_design/random/_view/artist/?limit=1&startkey=$(ruby -e 'puts rand')" | jq
```

Strictly speaking there is a risk of getting en empty result it the random value is greater than the largest assigned during import.

```http
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

