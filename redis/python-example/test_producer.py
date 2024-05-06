from redis import Redis
import time

# https://redis-py.readthedocs.io/en/stable/commands.html#redis.commands.core.CoreCommands.lpush

def test_pushing(r):
   print("Pushing numbers...")
   numbers = [1,2,3,4,5]
   for n in numbers:
      time.sleep(2)
      print(" -", n)
      r.lpush('numbers', n)

   print("✅ done")

if __name__ == "__main__":   
   print("Connecting...")
   r = Redis(host='localhost', port=6379, decode_responses=True)
   print("✅ Connected")

   test_pushing(r)
   

