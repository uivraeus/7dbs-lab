from pymongo import MongoClient
def get_blogger_database():
 
   CONNECTION_STRING = "mongodb://localhost"
 
   client = MongoClient(CONNECTION_STRING)
 
   return client['blogger']

if __name__ == "__main__":   
   db = get_blogger_database()
   articles = db['articles']
   queried_articles = articles.find({ 'author': 'ulf' })

   num_articles = 0
   num_comments = 0
   for article in queried_articles:
      num_articles += 1
      num_comments += len(article['comments'])

   print(f"ulf has written {num_articles} articles and received {num_comments} comments")


   