const db = connect('mongodb://localhost/blogger')
const articles = db.articles

const numArticles = articles.countDocuments()
const queriedArticles = articles.find({ author: 'ulf' })

print(`Tot num articles: ${numArticles}`)
print(`ulf's articles:`)
for (const article of queriedArticles) {
  const numComments = article.comments ? article.comments.length : 0
  print(`- ${article.createdAt.toDateString()}: ${article.text}`)
  print(`  ${numComments} comment${numComments !== 1 ? "s" : ""}`)
}
