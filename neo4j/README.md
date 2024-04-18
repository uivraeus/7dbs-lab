# Neo4j

## Notes from Day 1

* `/db/data/` endpoint not valid for the version I'm using (5.18.1)
  * [replaced in v4](https://community.neo4j.com/t/no-webpage-was-found-for-the-web-address-http-localhost-7474-db-data/22630)? (now the "bolt" protocol?)
  * Day 2 is going to be tough :-(
* [Cypher](https://neo4j.com/docs/cypher-manual/current/introduction/) querying language
  * Good documentation of the API, e.g. for [`CREATE`](https://neo4j.com/docs/cypher-manual/current/clauses/create/)
* A lot of "Warnings" about _"cartesian product between disconnected patterns"_
  * This [Stack Overflow](https://stackoverflow.com/questions/33352673/why-does-neo4j-warn-this-query-builds-a-cartesian-product-between-disconnected) explains it well
  * (but it also sounds like it shouldn't be an issue in newer versions (?) )
* Nice embedded tutorial (the movies guide)
 
### Scratch pad

```cypher
CREATE (w:Wine {name: "Prancing Wolf", style: "ice wine", vintage: 2015})
```

```cypher
MATCH (n)
RETURN n;
```

```cypher
CREATE (p:Publication {name: "Wine Expert Monthly"})
```

```cypher
MATCH (p:Publication {name: "Wine Expert Monthly"}),
  (w:Wine {name: "Prancing Wolf", vintage: 2015})
CREATE (p)-[r:report_on]->(w)
```

> ***Warning***
>
> This query builds a cartesian product between disconnected patterns.
>
> If a part of a query contains multiple disconnected patterns, this will build a cartesian product between all those parts. This may produce a large amount of data and slow down query processing. While occasionally intended, it may often be possible to reformulate the query that avoids the use of this cross product, perhaps by adding a relationship between the different parts or by using OPTIONAL MATCH (identifier is: (w))

```cypher
MATCH (n)
RETURN n;
```

```cypher
MATCH ()-[r]-()
WHERE id(r) = 0
RETURN r
```

> ***Warning***
>
> This feature is deprecated and will be removed in future versions.
>
> The query used a deprecated function: `id`.

> According to the [docs on id()](https://neo4j.com/docs/cypher-manual/current/functions/scalar/#functions-id), `elementId()` should be used instead but the following doesn't return anything
>
> ```cypher
> MATCH ()-[r]-()
> WHERE elementId(r) = 0
> RETURN r
> ```
>
> ```cyper
> MATCH ()-[r]-()
> RETURN elementId(r)
> ```
>
> Returns `["5:373d097e-487b-4d98-9fa0-83f0b64d1801:0", "5:373d097e-487b-4d98-9fa0-83f0b64d1801:0"]`
>
> (two (?) times the same elementId that was shown together with the id (0) when clicking on the relationship in the web GUI's graph)
>
> ```cypher
> MATCH ()-[r]-()
> WHERE elementId(r) = "5:373d097e-487b-4d98-9fa0-83f0b64d1801:0"
> RETURN r
> ```

```cypher
MATCH ()-[r]-()
WHERE id(r) = 0
SET r.rating = 97
RETURN r
```

```cypher
CREATE (g:GrapeType {name: "Riesling"})
```

```cypher
MATCH (w:Wine {name: "Prancing Wolf"}), (g:GrapeType {name: "Riesling"})
CREATE (w)-[r:grape_type]->(g)
```

```cypher
CREATE (e: EphemeralNode {name: "short lived"})
```

```cypher
MATCH (w:Wine {name: "Prancing Wolf"}), (e:EphemeralNode {name: "short lived"})
CREATE (w)-[r:short_lived_relationship]->(e)
```

```cypher
MATCH ()-[r:short_lived_relationship]-()
DELETE r
```

```cypher
MATCH (e: EphemeralNode)
DELETE e;
```

(would not have worked if the relationship still existed)

> ***Wipe everything (ran it after Day 1)***
>
> ```cypher
> MATCH(n)
> OPTIONAL MATCH (n)-[r]-()
> DELETE n, r
> ```
>
> Alternative (from the embedded movie guide):
>
> ```cypher
> MATCH (n) DETACH DELETE n;
> ```

*** Add winery and more wines ***

```cypher
CREATE (wr: Winery {name: "Prancing Wolf Winery"})
```

```cypher
CREATE (wr: Winery {name: "Prancing Wolf Winery"});

MATCH (w:Wine {name: "Prancing Wolf"}), (wr:Winery {name: "Prancing Wolf Winery"})
CREATE (wr)-[r:produced]->(w);

CREATE (w:Wine {name: "Prancing Wolf", style: "Kabinett", vintage: 2022});
CREATE (w:Wine {name: "Prancing Wolf", style: "Spätlese", vintage: 2010});

MATCH (wr: Winery {name: "Prancing Wolf Winery"}), (w:Wine {name: "Prancing Wolf"})
CREATE (wr)-[r:produced]->(w);

MATCH (w:Wine), (g:GrapeType {name: "Riesling"})
CREATE (w)-[r:grape_type]->(g);
```

> ***Hmmm...***
>
> This creates a second `produced` relation to the first wine (Ice Wine), which is not shown in the book
>
> Delete the first relation to keep it clean
>
> ```cypher
> MATCH ()-[r:produced]-()
> WHERE elementId(r) = "5:373d097e-487b-4d98-9fa0-83f0b64d1801:2"
> DELETE r 
> ```

***Add people and social components***

```cypher
CREATE (p:Person {name: "Alice"});
MATCH (p:Person {name: "Alice"}), (w:Wine {name: "Prancing Wolf", style: "ice wine"})
CREATE (p)-[r:likes]->(w);

CREATE (p:Person {name: "Tom"});
MATCH (p:Person {name: "Tom"}), (w:Wine {name: "Prancing Wolf", style: "Kabinett"})
CREATE (p)-[r:likes]->(w);
MATCH (p:Person {name: "Tom"}), (w:Wine {name: "Prancing Wolf", style: "ice wine"})
CREATE (p)-[r:likes]->(w);
MATCH (p:Person {name: "Tom"}), (pub:Publication {name: "Wine Expert Monthly"})
CREATE (p)-[r:trusts]->(pub);

CREATE (p:Person {name: "Patty"});
MATCH (p1:Person {name: "Patty"}), (p2:Person {name: "Tom"})
CREATE (p1)-[r:friends]->(p2);
MATCH (p1:Person {name: "Patty"}), (p2:Person {name: "Alice"})
CREATE (p1)-[r:friends]->(p2);
```

> ***Errors in the book?***
>
> - Missing `likes` relation for Tom? (He likes both ice wine and Kabinett)
> - Should the `friends` relation only have one direction?
> - The queries for friends of Alice won't work, either
>   - bi-directional relations (two of them) for `friends`
>   - query for Patty instead (maybe that was what the author intended?)
>   - query without locking on direction (what I did below)
>
>   (Alice and Tom are not friends)

```cypher
MATCH (p:Person {name: "Alice"})--(n)
RETURN n;

MATCH (p:Person {name: "Alice"})--(other: Person)
RETURN other.name;

MATCH (p:Person {name: "Patty"})-->(other: Person)
RETURN other.name;
```

```cypher
MATCH (p:Person)
WHERE p.name <> "Patty"
RETURN p;
```

```cypher
CREATE (p1:Person {name: "Ahmed"}), (p2:Person {name: "Kofi"});

MATCH (p1:Person {name: "Ahmed"}), (p2:Person {name: "Alice"})
CREATE (p1)-[r:friends]->(p2);

MATCH (p1:Person {name: "Kofi"}), (p2:Person {name: "Tom"})
CREATE (p1)-[r:friends]->(p2);
```

```cypher
MATCH (fof:Person)-[:friends]-(f:Person)-[:friends]-(p:Person {name: "Patty"})
RETURN fof.name;
```

***Indexes, constraints and "schemas"***

Support for the syntax in the book, e.g. `CREATE INDEX ON :Wine(name)` was removed in v5 according to [the docs](https://neo4j.com/docs/cypher-manual/current/deprecations-additions-removals-compatibility/).

```cypher
CREATE INDEX FOR (w:Wine) ON (w.name);
```

> ***How can I drop this index? I didn't give it a name...***
>
> ```cypher
> SHOW INDEXES;
> ```
>
> ```cypher
> DROP INDEX index_21f23d99;
> ```

```cypher
CREATE INDEX wine_name FOR (w:Wine) ON (w.name);
```

```cypher
DROP INDEX wine_name;
```

> ***Index vs Constraint?***
>
> Actually required to drop the `INDEX` above to allow the `CONSTRAINT` creation below.
>
> _"There already exists an index (:Wine {name}). A constraint cannot be created until the index has been dropped."_

```cypher
CREATE CONSTRAINT wine_unique_name FOR (w:Wine) REQUIRE (w.name, w.style) IS UNIQUE;
```

With the constraint in place this won't work

```cypher
CREATE (:Wine {name: "Daring Goat", style: "Spätlese", vintage: 2008}), (:Wine {name: "Daring Goat", style: "Spätlese", vintage: 2006})
```

> ***Error in the book?***
>
> Can't create the constraint (and violation examples) as there already are multiple wines with same name ("Prancing Wolf")
>
> ```cypher
> CREATE CONSTRAINT wine_unique_name FOR (w:Wine) REQUIRE (w.name) IS UNIQUE;
> ```

```cypher
DROP CONSTRAINT wine_unique_name;
```

### Homework

* The [docs](https://neo4j.com/docs/cypher-manual/current) are good and full of examples, nice ones
  * Create nodes and relations with a [single `CREATE` command](https://neo4j.com/docs/cypher-manual/curren)
  * [`OPTIONAL MATCH`](https://neo4j.com/docs/cypher-manual/current/clauses/optional-match/#_optional_match_in_more_detail) seems useful
  * [`MERGE`](https://neo4j.com/docs/cypher-manual/current/clauses/merge/#merge-merge-with-on-create) seems like a powerful (but tricky) clause.
  * Using [`UNWIND`](https://neo4j.com/docs/cypher-manual/current/clauses/create/#create-create-multiple-nodes-with-a-parameter-for-their-properties) to create multiple nodes from a list of properties seems convenient.
* Follow the embedded "Try Neo4j with live data" guide (a.k.a. "Movie Graph Guide")

  > The _Movie Graph_ is a mini graph application, containing actors and directors that are related through the movies they have collaborated on.
  >
  > This guide shows how to:
  > 
  > 1. Load: Insert movie data into the graph.
  > 2. Constrain: Create unique node property constraints.
  > 3. Index: Index nodes based on their labels.
  > 4. Find: Retrieve individual movies and actors.
  > 5. Query: Discover related actors and directors.
  > 6. Solve: The Bacon Path.

  Really nice! Step 5 & 6 include some great examples! (There are actually more steps beyond 6)
 
#### My "friends"

```cypher
CREATE
  (ulf:Person {name: "ulf", role:"consultant"}),
  (ron:Person {name: "ron"}),
  (leslie:Person {name: "leslie"}),
  (ron)-[:MANAGE]->(leslie),
  (leslie)-[:HIRE]->(ulf),
  (ulf)-[:ADMIRE]->(ron),
  (leslie)-[:ADMIRE]->(ron),
  (ron)-[:DESPISE]->(ulf);
```

```cypher
MATCH(n) RETURN n;
```

***Clean-up***

```cypher
MATCH (n) DETACH DELETE n;
```

## Notes from Day 2

* The REST API was removed in v4 but there is now a ["HTTP API"](https://neo4j.com/docs/http-api/current/), which i assume serves a similar purpose
  * Query parameters are [encouraged](https://neo4j.com/docs/http-api/current/query/#_query_parameters)
  * Implicit transactions in its simplest form but [explicit transactions](https://neo4j.com/docs/http-api/current/transactions/) are also supported.
  * Queries (transactions) use embedded Cypher queries (not explicit endpoints) for nodes, relations etc.
  * The [available endpoints](https://neo4j.com/docs/http-api/current/endpoints/) are instead related to the desired kind of transaction
  * Responses are always complete, with metadata etc. But you can request [different formats](https://neo4j.com/docs/http-api/current/result-formats/) for it (default is json)
* Too bad I couldn't get the original movies database working in modern Neo4j
* Maybe one should learn more about [TinkerPop](https://tinkerpop.apache.org/docs/3.7.2/tutorials/getting-started/) and [Gremlin](https://tinkerpop.apache.org/docs/3.7.2/reference/#gremlin-console)
 
### Scratch pad

An example for how to use the "HTTP API" (from the docs)

```http
POST http://localhost:7474/db/neo4j/tx/commit
Content-Type: application/json

{
  "statements": [
    {
      "statement": "MATCH (n:Person {name: 'ulf'}) RETURN n"
    },
    {
      "statement": "MATCH (n:Person {name: $name}) RETURN n",
      "parameters": {
        "name": "ron"
      }
    }
  ]
}
```

Try to follow the book but use the HTTP API (with Cypher) instead.

Also, further down, there will be a "full-text index". It doesn't seem possible to create a full-text index without labels, so I adjusted the author/book nodes below with labels AUTHOR and BOOK


```http
GET http://localhost:7474/
Accept: application/json
```

> ***Result: 200 OK***
>
> ```http
> HTTP/1.1 200 OK
> Date: Tue, 02 Apr 2024 16:30:28 GMT
> Connection: close
> Access-Control-Allow-Origin: *
> Content-Type: application/json
> Vary: Accept
> Content-Length: 343
>
> {
>   "bolt_routing": "neo4j://localhost:7687",
>   "dbms/cluster": "http://localhost:7474/dbms/cluster",
>   "db/cluster": "http://localhost:7474/db/{databaseName}/cluster",
>   "transaction": "http://localhost:7474/db/{databaseName}/tx",
>   "bolt_direct": "bolt://localhost:7687",
>   "neo4j_version": "5.18.1",
>   "neo4j_edition": "enterprise",
>   "auth_config": {
>     "oidc_providers": []
>   }
> }
> ```

```http
POST http://localhost:7474/db/neo4j/tx/commit
Content-Type: application/json

{
  "statements": [
    {
      "statement": "CREATE (:AUTHOR {name: 'P.G. Wodehouse', genre: 'British Humour'})"
    }
  ]
}
```

> ***Result: 200 OK***
>
> ```http
> HTTP/1.1 200 OK
> Date: Tue, 02 Apr 2024 16:19:28 GMT
> Connection: close
> Access-Control-Allow-Origin: *
> Content-Type: application/json
> Content-Length: 102
>
> {
>   "results": [
>     {
>       "columns": [],
>       "data": []
>     }
>   ],
>   "errors": [],
>   "lastBookmarks": [
>     "FB:kcwQNz0Jfkh7TZifoIPwtk0YAWmQ"
>   ]
> }
> ```

Using `"parameters"` according to recommendation and it makes the `"statement"` shorter (only single line supported!):

```http
POST http://localhost:7474/db/neo4j/tx/commit
Content-Type: application/json

{
  "statements": [
    {
      "statement": "CREATE (:AUTHOR $node)",
      "parameters": {
        "node": {
          "name": "P.G. Wodehouse", 
          "genre": "British Humour"
        }
      }
    }
  ]
}
```

```http
POST http://localhost:7474/db/neo4j/tx/commit
Content-Type: application/json

{
  "statements": [
    {
      "statement": "MATCH (n {name: 'P.G. Wodehouse'}) RETURN n.genre"
    }
  ]
}
```

> Always complete responses (metadata etc), not just "British Humour" as in the book.

***A second node and a relation***

```http
POST http://localhost:7474/db/neo4j/tx/commit
Content-Type: application/json

{
  "statements": [
    {
      "statement": "CREATE (:BOOK {name: 'Jeeves Takes Charge', style: 'short story'})"
    }
  ]
}
```

```http
POST http://localhost:7474/db/neo4j/tx/commit
Content-Type: application/json

{
  "statements": [
    {
      "statement": "MATCH (a {name: $author}), (b {name: $book}) CREATE (a)-[:WROTE $data]->(b)",
      "parameters": {
        "author": "P.G. Wodehouse",
        "book": "Jeeves Takes Charge",
        "data": {
          "published": "November 28, 1916"
        }
      }
    }
  ]
}
```

***Finding paths***

(with max depth 10)

```http
POST http://localhost:7474/db/neo4j/tx/commit
Content-Type: application/json

{
  "statements": [
    {
      "statement": "MATCH (a {name: $author}), (b {name: $book}), p=shortestPath((a)-[:WROTE*..10]-(b)) RETURN p",
      "parameters": {
        "author": "P.G. Wodehouse",
        "book": "Jeeves Takes Charge"
      }
    }
  ]
}
```

***Full-text indexes***

Following the [docs](https://neo4j.com/docs/cypher-manual/current/indexes/semantic-indexes/full-text-indexes/) here (the book is obsolete)

```http
POST http://localhost:7474/db/neo4j/tx/commit
Content-Type: application/json

{
  "statements": [
    {
      "statement": "CREATE FULLTEXT INDEX names IF NOT EXISTS FOR (n:BOOK|AUTHOR) ON EACH [n.name]"
    }
  ]
}
```

```http
POST http://localhost:7474/db/neo4j/tx/commit
Content-Type: application/json

{
  "statements": [
    {
      "statement": "CALL db.index.fulltext.queryNodes('names', 'P.G.') YIELD node RETURN node.name"
    }
  ]
}
```

```http
POST http://localhost:7474/db/neo4j/tx/commit
Content-Type: application/json

{
  "statements": [
    {
      "statement": "CALL db.index.fulltext.queryNodes('names', 'Takes') YIELD node RETURN node.name"
    }
  ]
}
```

***(Not so) Big Data***

> Can't (or more like "gave up on") migrate the "cineasts" movie database to a modern version of Neo4J
>
> Used the much smaller and simpler "movies" dataset from the built-in demo instead (and tweaked the experiments below)

```shell
docker cp create-movie-graph.cypher 7dbs_devcontainer-neo4j-1:/tmp/
docker exec -it 7dbs_devcontainer-neo4j-1 bash
```

```console
root@b6b3f96690e7:/var/lib/neo4j# cat /tmp/create-movie-graph.cypher | cypher-shell
```

Enter `cypher-shell` interactive mode

```console
@neo4j> MATCH(n) RETURN DISTINCT labels(n), count(n);
+-----------------------+
| labels(n)  | count(n) |
+-----------------------+
| ["Movie"]  | 38       |
| ["Person"] | 133      |
+-----------------------+

2 rows
```

```console
@neo4j> MATCH (a:Person)-[:ACTED_IN]->(m:Movie)
        WITH a, count(m) AS movie_count
        WHERE movie_count > 5
        RETURN a.name;
+----------------+
| a.name         |
+----------------+
| "Keanu Reeves" |
| "Tom Hanks"    |
+----------------+

2 rows
```

```console
@neo4j> MATCH (Person {name:"Kevin Bacon"})-[:ACTED_IN]-(m:Movie) RETURN count(m);
+----------+
| count(m) |
+----------+
| 3        |
+----------+

@neo4j> MATCH (Person {name:"Kevin Bacon"})-[:ACTED_IN]-(m:Movie) RETURN m.title;
+------------------+
| m.title          |
+------------------+
| "Apollo 13"      |
| "Frost/Nixon"    |
| "A Few Good Men" |
+------------------+

3 rows
```

One degree of Bacon...

```console
@neo4j> MATCH (Person {name: "Kevin Bacon"})-[:ACTED_IN]->(Movie)<-[:ACTED_IN]-(other:Person)
        RETURN count(DISTINCT other);
+-----------------------+
| count(DISTINCT other) |
+-----------------------+
| 19                    |
+-----------------------+
```

> Hmm... Why isn't Mr Bacon also included in this result?

Two degrees (first futile attempt)...

```console
@neo4j> MATCH (bacon:Person {name: "Kevin Bacon"})-[:ACTED_IN*1..2]-(other:Person)
        RETURN count(DISTINCT other);
+-----------------------+
| count(DISTINCT other) |
+-----------------------+
| 19                    |
+-----------------------+
```

> The `(Movie)` can be left out in the query because all relations are "Person->Movie". But each movie counts in the relation "jump chain" so the numbers must be doubled (Otherwise, its the same result as for "first degree")

Another attempt...

```console
@neo4j> MATCH (bacon:Person {name: "Kevin Bacon"})-[:ACTED_IN*1..4]-(other:Person)
        RETURN count(DISTINCT other);
+-----------------------+
| count(DISTINCT other) |
+-----------------------+
| 72                    |
+-----------------------+
```

For 3 (`1..6`) and above I need to filter out Mr Bacon from the result using `WHERE`, like this:

```console
@neo4j> MATCH (bacon:Person {name: "Kevin Bacon"})-[:ACTED_IN*1..6]-(other:Person)
        WHERE bacon <> other
        RETURN count(DISTINCT other);
+-----------------------+
| count(DISTINCT other) |
+-----------------------+
| 92                    |
+-----------------------+
```

Bacon vs Hawke...

```console
@neo4j> MATCH (bacon:Person {name: "Kevin Bacon"}), (hawke:Person {name: "Ethan Hawke"}),
        p=shortestPath((bacon)-[:ACTED_IN*]-(hawke))
        RETURN length(p)/2;
+-------------+
| length(p)/2 |
+-------------+
| 3           |
+-------------+
```

### Homework

* The REST API is dead
* [JUNG](https://jung.sourceforge.net/index.html)  has not been released since 2010
* But maybe part of [Gremlin](https://github.com/tinkerpop/gremlin/wiki/Using-JUNG)... at least until 2016
* [Apache TinkerPop](https://tinkerpop.apache.org/) seems to be what this as evolved into (?)
  * But Neo4j integration seems deprecated according to [this issue](https://github.com/neo4j-contrib/neo4j-tinkerpop-api-impl/issues/18)




