let totalBands = null; // how many bands we expect to process
let processedBands = 0; // and keep track of how many bands we have processed
const couchDBDatabase = 'bands'; // The name of the couch database
const batchSize = 50; // The size of document upload batches

const redis = require('redis');
const couchClient = require('nano')('http://couch:couch@localhost:5984');


/**
 * A helper function that builds a good CouchDB key
 * @param string the unicode string being keyified
 */
function couchKeyify(string)
{
  // remove bad chars, and disallow starting with an underscore
  return string.
    replace(/[\t \?\#\\\-\+\.\,'"()*&!\/]+/g, '_').
    replace(/^_+/, '');
};

/*
 * Keep track of the number of bands processed, output every 1000 loaded,
 * and close the Redis client when we've loaded them all.
 */
function trackLineCount(increment) {
  processedBands += increment;

  // Output once every 1000 lines
  if (processedBands % 1000 === 0) {
    console.log('Bands Loaded: ' + processedBands);
  }

  // Close the Redis client when complete
  if (totalBands <= processedBands) {
    console.log(`Total Bands Loaded: ${processedBands}`);
    redisClient.quit();
  }
};

/*
 * Post documents into CouchDB in bulk.
 * @param documents The documents to store
 * @param count The number of documents being inserted.
 */
async function saveDocs(documents, count) {
  const db = couchClient.use(couchDBDatabase)
  try {
    await db.bulk({ docs: documents });
  }
  catch(e) {
    console.error("bulk error:", e)
  }
  trackLineCount(count);
};

/*
 * Loop through all of the bands populated in Redis. We expect
 * the format of each key to be 'band:Band Name' having the value
 * as a set of artist names. The artists each have the list of roles
 * they play in each band, keyed by 'artist:Band Name:Artist Name'.
 * The band name, set of artists, and set of roles each artist plays
 * populates the CouchDB documents. eg:
  {
    name:"Nirvana",
    artists:[{
      name: "Kurt Cobain",
      roles:["Lead Vocals", "Guitar"]
    },...]
  }
 */
async function populateBands(redisClient) {

  const bandKeys = await redisClient.keys('band:*')
    
  totalBands = bandKeys.length;
  let readBands = 0;
  let bandsBatch = [];

  for (const bandKey of bandKeys) {
    // substring of 'band:'.length gives us the band name
    const bandName = bandKey.substring(5);
    const artists =  await redisClient.sMembers(bandKey);
    // batch the Redis calls to get all artists' information at once
    var roleBatch = [];
    artists.forEach(function(artistName) {
      roleBatch.push([
        'smembers',
        `artist:${bandName}:${artistName}`
      ]);
    });

    // batch up each band member to find the roles they play
    const roles = await redisClient.multi(roleBatch).exec();
    
    let i = 0;
    let artistDocs = [];

    // build the artists sub-documents
    artists.forEach(function(artistName) {
      artistDocs.push({ name: artistName, role : roles[i++] });
    });

    // add this new band document to the batch to be executed later
    const bandId = couchKeyify(bandName)
    if (bandId) {
      bandsBatch.push({
        _id: couchKeyify(bandName),
        name: bandName,
        artists: artistDocs
      });
    } else {
      console.log(`Warning: Skipping band ${bandName}, can't derive ID`);
    }
    // keep track of the total number of bands read
    readBands++;

    // upload batches of 50 values to couch, or the remaining values left
    if (bandsBatch.length >= batchSize || totalBands - readBands == 0) {
      await saveDocs(bandsBatch, bandsBatch.length);

      // empty out the batch array to be filled again
      bandsBatch = [];
    }
  };
}
    

async function main () {
  const db = couchClient.db.use(couchDBDatabase);
  if (!db) {
    await couchClient.db.create(couchDBDatabase);  
  }

  const redisClient = await redis.createClient()
    .on('error', err => console.log('Redis Client Error', err))
    .connect();

  await populateBands(redisClient);
}

main();
