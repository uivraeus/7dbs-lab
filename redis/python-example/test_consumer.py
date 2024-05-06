from redis import Redis

# https://redis-py.readthedocs.io/en/stable/commands.html#redis.commands.core.CoreCommands.brpop

TIMEOUT=30

def test_blocking_pop(r):
   print("Test blocking pop...")
   
   result = -1 # dummy default
   while result is not None:
      result = r.brpop('numbers', TIMEOUT)
      if result is None:
         print("❌ timeout")
      else:
         print("✅ popped:", result)

if __name__ == "__main__":   
   print("Connecting...")
   r = Redis(host='localhost', port=6379, decode_responses=True)
   print("✅ Connected")

   test_blocking_pop(r)
   

