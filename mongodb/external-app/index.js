const { MongoClient, ServerApiVersion } = require("mongodb");

const uri = "mongodb://localhost/blogger";

const client = new MongoClient(uri,  {
        serverApi: {
            version: ServerApiVersion.v1,
            strict: true,
            deprecationErrors: true,
        }
    }
);
const db = client.db(); //no arg -> use db from connection string
const articles = db.collection('articles')
  

async function addBlogEntry(author, email, text) {
  const result = await articles.insertOne({
    author,
    email,
    createdAt: new Date(),
    text
  })

  console.log(`Added article, result: ${JSON.stringify(result, null, 2)}`)
  if (result.acknowledged && result.insertedId) {
    return result.insertedId
  } else {
    return null
  }
}

async function addAuthorIndex() {
  //https://mongodb.github.io/node-mongodb-native/6.5/classes/Collection.html#createIndex
  const result = await articles.createIndex('author')

  console.log(`Added author index, result: ${JSON.stringify(result, null, 2)}`)
}

async function queryBlog(author) {
  const numArticles = await articles.countDocuments()
  const queriedArticles = articles.find({ author })
  
  console.log(`Tot num articles: ${numArticles}`)
  console.log(`${author}'s articles:`)
  for await (const article of queriedArticles) {
    const numComments = article.comments ? article.comments.length : 0
    console.log(`- ${article.createdAt.toDateString()}: ${article.text}`)
    console.log(`  ${numComments} comment${numComments !== 1 ? "s" : ""}`)
  }
}

async function addComment(articleId, commenter, comment) {
  const result = await articles.updateOne({ _id: articleId }, {
    $push: { comments:
      { author: commenter, text: comment }
    }
  })

  console.log(`Added comment, result: ${JSON.stringify(result, null, 2)}`)
}

async function run() {
  try {
    // Connect the client to the server (optional starting in v4.7)
    await client.connect();
    // Send a ping to confirm a successful connection
    await client.db("admin").command({ ping: 1 });
    console.log("Connected to MongoDB!");

    await queryBlog('ulf')

    await addAuthorIndex()

    const id = await addBlogEntry(
      'ulf',
      'ulf@email.com',
      `More content at ${new Date().toLocaleTimeString()}`
    )

    if (id) {
      addComment(id, 'sauron', "I'm watching you")
    }

    await queryBlog('ulf')

  } finally {
    // Ensures that the client will close when you finish/error
    await client.close();
  }
}
run().catch(console.dir);
