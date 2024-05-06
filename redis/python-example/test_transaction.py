from redis import Redis

# https://redis.io/docs/latest/develop/connect/clients/python/

def test_insert_increment(r):
   with  r.pipeline() as pipe:
      pipe.multi() # default?
      pipe.set('counter', 0)
      pipe.incr('counter', 1)
      pipe.execute()

   result = r.get('counter')
   print("Test insert/increment as single transaction: result =", result)

if __name__ == "__main__":   
   print("Connecting...")
   r = Redis(host='localhost', port=6379, decode_responses=True)
   print("✅ Connected")

   test_insert_increment(r)

