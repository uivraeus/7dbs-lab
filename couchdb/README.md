# CouchDB

## Notes from Day 1

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
