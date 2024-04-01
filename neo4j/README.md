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
