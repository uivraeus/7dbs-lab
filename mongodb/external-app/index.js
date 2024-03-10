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

async function queryBlog(author) {
  const options = { _id: false };
  const db = client.db(); //no arg -> use db from connection string
  const articles = db.collection('articles')
  
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

async function run() {
  try {
    // Connect the client to the server (optional starting in v4.7)
    await client.connect();
    // Send a ping to confirm a successful connection
    await client.db("admin").command({ ping: 1 });
    console.log("Connected to MongoDB!");

    await queryBlog('ulf')

  } finally {
    // Ensures that the client will close when you finish/error
    await client.close();
  }
}
run().catch(console.dir);
