# MongoDB

## Notes from Day 1

* Again, some details in the book are a bit obsolete or deprecated
  * E.g. DBRef and functions in queries
* Is there a formal definition of "document database"?
  * "Structured document"? "Serializable objects"? "No-schema"?
* MongoDB licensing model is not (after 2018) true open source
  * Server Side Public Licensing ([SSPL](https://www.mongodb.com/legal/licensing/server-side-public-license/faq))
  * [Controversial](https://www.percona.com/blog/why-is-mongodbs-sspl-bad-for-you/)
* References (in the book) to the "distributed model" of MongoDB but very little explanation/elaboration.
 
### Scratch pad

```js
db.towns.insert({
  name: "New York",
  population: 22200000,
  lastCensus: ISODate("2016-07-01"),
  famousFor: [ "the MOMA", "food", "Derek Jeter" ],
  mayor: {
    name: "Bill de Blasio",
    party: "D"
  }
})
```

```console
DeprecationWarning: Collection.insert() is deprecated. Use insertOne, insertMany, or bulkWrite.
{
  acknowledged: true,
  insertedIds: { '0': ObjectId('65e9f1a5b94696435fb001fd') }
}
```

```js
show collections
db.towns.find()
```

> Script files ...
>
> [`load()`](https://www.mongodb.com/docs/mongodb-shell/reference/methods/#std-label-mongosh-native-method-load) or copy-paste into shell but pay attention to [scoping](https://www.mongodb.com/docs/mongodb-shell/write-scripts/scoping/)

```js
insertCity('Punxustawney', 6200, '2016-01-31', 'Punxustawney Phil', {name: 'Richard Alexander'})

insertCity('Portland', 582000, '2016-09-20', ['beer', 'food', 'Portlandia'], {name: 'Ted Wheeler', party: 'D'})
```

> Accidentally applied the "wrong" type for `famousFor` in one of the inserts there. Also, accidentally named the field `mayorInfo` (instead of `mayor`).
>
> ```js
> db.towns.updateOne( { name: 'Punxustawney'}, { $set: { famousFor: ['Punxustawney Phil'] }})
> ```
>
> ```js
> db.towns.updateMany( {}, { $rename: {'mayorInfo': 'mayor'} }, false /*upsert*/, true /*multi*/)
> ```
>
> ```console
> {
>   acknowledged: true,
>   insertedId: null,
>   matchedCount: 3,
>   modifiedCount: 2,
>   upsertedCount: 0
> }
> ```

```js
db.towns.find({ _id: ObjectId('65e9f1a5b94696435fb001fd') })
db.towns.find({ _id: ObjectId('65e9f1a5b94696435fb001fd') }, { name: true })
db.towns.find({ _id: ObjectId('65e9f1a5b94696435fb001fd') }, { name: false })
```

```js
db.towns.find({ name: /^P/, population: 582000}, {_id: false, name: true, population: true })
db.towns.find({ name: /^P/, population: { $lt: 10000 }}, {_id: false, name: true, population: true })
```

```js
let populationRange = {
  $lt: 1000000,
  $gt: 10000
}
db.towns.find({ population: populationRange }, { name: true })
```

```js
db.towns.find({ lastCensus: { $gte: ISODate('2016-06-01') }}, { _id: false, name: true} )
```

```js
db.towns.find({ famousFor: 'food'}, { _id: false, name: true, famousFor: true })
db.towns.find({ famousFor: /MOMA/}, { _id: false, name: true, famousFor: true })
```

> Not case-invariant regex per default (like in the book)

```js
db.towns.find({ famousFor: { $all: ['food', 'beer'] } }, { _id: false, name: true, famousFor: true })
db.towns.find({ famousFor: { $nin: ['food', 'beer'] } }, { _id: false, name: true, famousFor: true })
```

```js
db.towns.find({ 'mayor.party': 'D' }, { _id: false, name: true, mayor: true} )
db.towns.find({ 'mayor.party': 'D' }, { _id: false, name: true, 'mayor.name': true} )

```

```js
db.countries.insertOne({
  _id: 'us',
  name: 'United States',
  exports: {
    foods: [
      { name: 'bacon', tasty: true },
      { name: 'burgers' }
    ]
  }
})

db.countries.insertOne({
  _id: 'ca',
  name: 'Canada',
  exports: {
    foods: [
      { name: 'bacon', tasty: false },
      { name: 'syrup', tasty: true }
    ]
  }
})

db.countries.insertOne({
  _id: 'mx',
  name: 'Mexico',
  exports: {
    foods: [
      { name: 'salsa', tasty: true, condiment: true }
    ]
  }
})
```

```js
db.countries.count()
```

```console
DeprecationWarning: Collection.count() is deprecated. Use countDocuments or estimatedDocumentCount.
3
```

```js
db.countries.countDocuments()
```

```js
db.countries.find(
  { 'exports.foods.name': 'bacon', 'exports.foods.tasty': true },
  { _id: false, name: true }
)
```

(Doesn't give the desired result!)

Correct version:

```js
db.countries.find({
    'exports.foods' : {
      $elemMatch: {
        name: 'bacon',
        tasty: true
      }
    }
}, {_id: false, name: true })
```

```js
db.countries.find({
    'exports.foods' : {
      $elemMatch: {
        tasty: true,
        condiment: { $exists: true }
      }
    }
}, {_id: false, name: true })
```

```js
db.countries.find({
  $or: [
    { _id: 'mx' },
    { name: 'United States' }
  ]
}, { _id: true })
```

```js
db.towns.findOne({ name: 'Portland' })
db.towns.update(
  { name: 'Portland' },
  { $set: { state: 'OR' }}
)
db.towns.findOne({ name: 'Portland' })
db.towns.update(
  { name: 'Portland' },
  { $inc: { population: 1000 }}
)
db.towns.findOne({ name: 'Portland' })
```

```js
db.towns.update(
  { name: 'Portland' },
  { $set: { country: { $ref: 'countries', $id: 'us' } } }
)
db.towns.findOne({ name: 'Portland' })
```

```console
{
  _id: ObjectId('65ebf957317eacc3ff04eeba'),
  name: 'Portland',
  population: 583000,
  lastCensus: ISODate('2016-09-20T00:00:00.000Z'),
  famousFor: [ 'beer', 'food', 'Portlandia' ],
  mayor: { name: 'Ted Wheeler', party: 'D' },
  state: 'OR',
  country: DBRef('countries', 'us')
}
```

```js
const portland = db.towns.findOne({ name: 'Portland' })
//db.countries.findOne({ _id: portland.country.$id })  DOESN'T WORK - old syntax
db.countries.findOne({ _id: portland.country.oid }) // new syntax (but the whole DBRef concept seems deprecated)

//const portlandCountryRef=portland.country.$ref       DOESN'T WORK - old syntax'
const portlandCountryCollection=portland.country.collection
db[portlandCountryCollection].findOne({  _id: portland.country.oid })
```

```js
const badBacon = {
  'exports.foods': {
    $elemMatch: {
      name: 'bacon',
      tasty: false

    }
  }
}
db.countries.find(badBacon) // just to check before removing
db.countries.remove(badBacon)
```

```console
DeprecationWarning: Collection.remove() is deprecated. Use deleteOne, deleteMany, findOneAndDelete, or bulkWrite.
{ acknowledged: true, deletedCount: 1 }
```

```js
db.countries.countDocuments()
```

> These won't work (like they do in the book)
>
> ```js
> db.towns.find(function() {
>   return this.population > 6000 && this.population < 600000;
> })
> db.towns.find("this.population > 6000 && this.population < 600000")
> ```
> 
> ```console
> MongoInvalidArgumentError: Query filter must be a plain object or ObjectId
> ```

```js
db.towns.find({ $where: function() {
  return this.population > 6000 && this.population < 600000;
}})
db.towns.find({ $where: "this.population > 6000 && this.population < 600000" })
db.towns.find({ $where: "this.population > 6000 && this.population < 600000", famousFor: /Phil/ })
```

### Homework

#### Dummy hello world

```js
db.dummy.insertOne({ hello: 'world' })
b.dummy.find({}, {_id: false})
```

Query case-insensitive _new_ (see [documentation on regex in MongoDB](https://www.mongodb.com/docs/manual/reference/operator/query/regex/) for details):

```js
db.towns.find({ name: /new/i })
```

#### Towns containing _e_ which are famous for food or beer:

> Add to towns:
>
> ```js
> insertCity('Milwaukee', 577222, "2020-04-01", ['beer', 'cheese'], { name: 'Cavalier Johnson', party: 'D'})
> ```

```js
db.towns.find({ 
    name: /e/,
    famousFor: {
      $in: ['food', 'beer']
    }
  },
  { _id: false, name: true, famousFor: true }
)
``` 

#### Create _blogger_ DB with _articles_ collection

```js
use blogger
db.articles.insertOne({
  author: 'ulf',
  email: 'ulf@email.com',
  createdAt: ISODate('2024-03-10'),
  text: 'Hello blog!'
})
```

#### Add support for _comments_

```js
db.articles.updateMany( {}, { 
  $set: { comments: [
    { author: 'arnold', text: "I'll be back" }
  ] }
})
```

#### Query from external script

> Add some more entries:
>
> ```js
> db.articles.insertOne({ author: 'ulf', email: 'ulf@email.com', createdAt: ISODate('2024-03-10'), text: 'Next level' })
> db.articles.insertOne({ author: 'petter', email: 'petter@email.com', createdAt: ISODate('2024-03-10'), text: 'Yo!' })
> db.articles.updateMany( {}, { 
>   $push: { comments:
>     { author: 'sly', text: "I'm your worst nightmare" }
>   }
> })
> ```

Simple "mongosh script" [external-query.js](./external-query.js)_

```shell
mongosh -f external-query.js
```

Use [_mongodb package_](https://www.npmjs.com/package/mongodb) for running NodeJs scripts (see [external-app](./external-app/index.js)).

```shell
cd external-app
npm run dev
```

> ***Note***
>
> The _external-app_ and the _external-script_ are both written in JavaScript but the "app" version must be aware of `async`/`await` details.

The queries can also be run from non-JS, e.g. Python, as in the [external-python-app](./external-python-app/README.md) example.

```shell
cd external-python-app
python main.py
```
