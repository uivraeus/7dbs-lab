 // Import libraries
const csv = require('csv-parser')
const redis = require('redis')
const fs = require('fs')

// The TSV file containing the data for our exercise
const tsvFilename = 'group_membership.tsv'

// Track how many file lines we've processed
let processedLines = 0

async function main() {
  const redisClient = await redis.createClient()
    .on('error', err => console.log('Redis Client Error', err))
    .connect();

  await populateRedis(redisClient);
  await redisClient.disconnect();
}

/**
 * A helper function that splits up the comma-seperated list of roles and
 * converts it to an array. If no valid roles exist, return an empty array.
 * @param string the CSV to split into a role array
 */
function buildRoles(string) {
  if (string === undefined) {
    return [];
  } else {
    var roles = string.split(',');
    if (roles.length === 1 && roles[0] === '') {
      roles = [];
    }
    return roles;
  }
};

/**
 * Utility function that increments the total number
 * of lines (artists) processed and outputs every 1000.
 */
function trackLineCount() {
  if (++processedLines % 1000 === 0) {
    console.log(`Lines Processed: ${processedLines}`);
  }
}

/**
 * This function does all the heavy lifting. It loops through the
 * TSV data file and populates Redis with the given values.
 */
async function populateRedis(redisClient) {
  await new Promise((procDone, procReject) => {
  
    const stream = csv({
      separator: '\t',
      newline: '\n'
    });

    promises = []
    fs.createReadStream(tsvFilename)
      .pipe(stream)
      .on('data', function(data) {
        var
          artist = data['member'],
          band = data['group'],
          roles = buildRoles(data['role']);

        if (artist === '' || band === '') {
          trackLineCount();
          return true;
        }

        promises.push(redisClient.SADD('band:' + band, artist));

        if (roles.length > 0) {
          roles.forEach(function(role) {
            promises.push(redisClient.SADD(`artist:${band}:${artist}`, role));
          });
        }

        trackLineCount();
      })
      .on('end', async function(totalLines) {
        console.log(`Total lines processed: ${processedLines}`);
        await Promise.all(promises);
        procDone();
      });
  });
  
};

main();