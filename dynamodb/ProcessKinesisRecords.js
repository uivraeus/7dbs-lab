const { DynamoDB } = require('@aws-sdk/client-dynamodb');
const db = new DynamoDB({
  // same as in the book
  // The key apiVersion is no longer supported in v3, and can be removed.
  // @deprecated The client uses the "latest" apiVersion.
  apiVersion: '2012-08-10',

  region: 'eu-north-1',
});

exports.kinesisHandler = function(event, context /*not used*/, callback) {
  // We only need to handle one record at a time
  const kinesisRecord = event.Records[0];

  // The data payload is base 64 encoded and needs to be decoded to a string
  const data   =
    Buffer.from(kinesisRecord.kinesis.data, 'base64').toString('ascii');
  // Create a JSON object out of that string
  const obj    = JSON.parse(data);
  const sensorId    = obj.sensor_id,
        currentTime = obj.current_time,
        temperature = obj.temperature;

  // Define the item to write to DynamoDB
  const item = {
    TableName: "SensorData",
    Item: {
      SensorId: {
        S: sensorId
      },
      CurrentTime: {
        // Remember that all numbers need to be input as strings
        N: currentTime.toString()
      },
      Temperature: {
        N: temperature.toString()
      }
    }
  };

  // Perform a put operation, logging both successes and failures
  db.putItem(item, function(err, data) {
    if (err) {
      console.log(err, err.stack);
      callback(err.stack);
    } else {
      console.log(data);
      callback(null, data);
    }
  });
}
