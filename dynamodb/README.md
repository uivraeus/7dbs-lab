# DynamoDB

## Notes from Day 1

* No empty strings (!)
* _Range_ (aka sort) keys, in addition to regular hash keys
  * Important to get the key strategy right (know your query needs in advance) 
* aws (CLI) syntax is quite verbose
* Not that "open" - proprietary inner design
  * _"It just works"_
* Strategy (/best practice) for selecting hash/range keys essential for good partitioning
  * But a little bit confusing description (?)
  * _"fewer partition keys and more range keys"_ vs username/date example
* LSIs (local secondary indexes) can't be modified after a table has been created (!)
  * The author states that DynamoDB is one of the most flexible databases - but not wrt administration
  * The book didn't describe how to specify/declare an LSI or GSI - just how to use them
* GSIs are more flexible - what's the rationale for using LSIs?
* The Read/Write Capacity Units are not that well described in the book, but the [Best Practice docs](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-design.html) does a better job.
  * The numbers are _per second_, and there are "burst" and "adaptive" capacity features available  

### Scratch pad

```shell
asw configure
```

> Using special IAM user (`7dbs`) with full access permissions for DynamoDB

```shell
aws dynamodb create-table \
  --table-name ShoppingCart \
  --attribute-definitions AttributeName=ItemName,AttributeType=S \
  --key-schema AttributeName=ItemName,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
```

```console
$ aws dynamodb list-tables
{
    "TableNames": [
        "ShoppingCart"
    ]
}
```

```shell
aws dynamodb describe-table --table-name ShoppingCart
```

```shell
aws dynamodb put-item --table-name ShoppingCart \
  --item '{"ItemName": {"S": "Tickle Me Elmo"}}'
aws dynamodb put-item --table-name ShoppingCart \
  --item '{"ItemName": {"S": "1975 Buick LeSabre"}}'
aws dynamodb put-item --table-name ShoppingCart \
  --item '{"ItemName": {"S": "Ken Burns: the Complete Box Set"}}'
```

```shell
aws dynamodb scan --table-name ShoppingCart
```

```shell
aws dynamodb get-item --table-name ShoppingCart \
  --key '{"ItemName": {"S": "Tickle Me Elmo"}}'
```

> ***Response***
>
> ```json
> {
>     "Item": {
>         "ItemName": {
>             "S": "Tickle Me Elmo"
>         }
>     }
> }
> ```

```shell
aws dynamodb get-item --table-name ShoppingCart \
  --key '{"ItemName": {"S": "Tickle Me Elmo"}}' \
  --consistent-read
```

```shell
aws dynamodb delete-item --table-name ShoppingCart \
  --key '{"ItemName": {"S": "Tickle Me Elmo"}}'
```

```shell
aws dynamodb create-table \
  --table-name Books \
  --attribute-definitions AttributeName=Title,AttributeType=S \
    AttributeName=PublishYear,AttributeType=N \
  --key-schema AttributeName=Title,KeyType=HASH \
    AttributeName=PublishYear,KeyType=RANGE \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
```

```shell
aws dynamodb put-item --table-name Books \
  --item '{
    "Title": {"S": "Moby Dick"},
    "PublishYear": {"N": "1851"},
    "ISBN": {"N": "12345"}
  }'

aws dynamodb put-item --table-name Books \
  --item '{
    "Title": {"S": "Moby Dick"},
    "PublishYear": {"N": "1971"},
    "ISBN": {"N": "23456"},
    "Note": {"S": "Out of print"}
  }'

aws dynamodb put-item --table-name Books \
  --item '{
    "Title": {"S": "Moby Dick"},
    "PublishYear": {"N": "2008"},
    "ISBN": {"N": "34567"}
  }'
```

```shell
aws dynamodb query --table-name Books \
  --expression-attribute-values '{
    ":title": {"S": "Moby Dick"},
    ":year": {"N": "1980"}
  }' \
  --key-condition-expression 'Title = :title AND PublishYear > :year'
```

> ***Response***
>
> ```json
> {
>     "Items": [
>         {
>             "Title": {
>                 "S": "Moby Dick"
>             },
>             "PublishYear": {
>                 "N": "2008"
>             },
>             "ISBN": {
>                 "N": "34567"
>             }
>         }
>     ],
>     "Count": 1,
>     "ScannedCount": 1,
>     "ConsumedCapacity": null
> }
> ```

```shell
aws dynamodb query --table-name Books \
  --expression-attribute-values '{
    ":title": {"S": "Moby Dick"},
    ":year": {"N": "1900"}
  }' \
  --key-condition-expression 'Title = :title AND PublishYear > :year' \
  --projection-expression 'ISBN'
```

> ***Response***
>
> ```json
> {
>     "Items": [
>         {
>             "ISBN": {
>                 "N": "23456"
>             }
>         },
>         {
>             "ISBN": {
>                 "N": "34567"
>             }
>         }
>     ],
>     "Count": 2,
>     "ScannedCount": 2,
>     "ConsumedCapacity": null
> }
> ```

```shell
aws dynamodb query --table-name Books \
  --expression-attribute-values '{
    ":title": {"S": "Moby Dick"},
    ":year": {"N": "1900"}
  }' \
  --key-condition-expression 'Title = :title AND PublishYear > :year' \
  --projection-expression 'Note'
```

> ***Response***
>
> ```json
> {
>      "Items": [
>         {
>             "Note": {
>                 "S": "Out of print"
>             }
>         },
>         {}
>     ],
>     "Count": 2,
>     "ScannedCount": 2,
>     "ConsumedCapacity": null
> }
> ```
>
> Note the empty object: `{}`


### Homework

* The official documentation on [Partitioning](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.Partitions.html) and corresponding [Best practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-design.html) doesn't give specific "formulas" but they appear in various other blogs and forums, e.g [this SO](https://stackoverflow.com/questions/73885793/what-decides-the-number-of-partitions-in-a-dynamodb-table). The number of partitions depends on either _throughput_ or _amount_ of stored data
  * #partitions = RCU/3000 + WCU/1000
  * #partitions = GB/10
  * BUT... this is probably a simplification... a lot of the logic depends on "mode" (and other details)
* From the [DynamoDB Streams docs](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html):
  * _"A DynamoDB stream is an ordered flow of information about changes to items in a DynamoDB table. When you enable a stream on a table, DynamoDB captures information about every modification to data items in the table."_
  * Log retained for up to 24h
  * Can be enabled when a table is created or afterwards (and disabled if/when not needed)
  * Different endpoints (and SDKs) for DynamoDB and DynamoDB Streams
  * _"No more than two processes at most should be reading from the same stream's shard at the same time"_
* Limits etc. are described in the official [service quotas documentation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ServiceQuotas.html
)
  * _"One read capacity unit = one strongly consistent read per second, or two eventually consistent reads per second, for items up to 4 KB in size."_
  * _"One write capacity unit = one write per second, for items up to 1 KB in size."_
  * Other rules for transactional requests and there are differences wrt "Provisioned" or "On-Demand" mode configurations.
  * There are also quotas/limits for "import jobs" (S3), "insights", "tables per account per region", "L/GSIs", "partition/sort key lengths", "item size", "numerical precision", "expression lengths", "items and data per _transaction_", "streams capacity" and more.

#### 100GB data, 2000 RCU and 3000 WCU

  * Throughput: 2000/3000 + 3000/1000 = 3.67
  * Data: 100/10 = 10

  If the formulas are correct that should imply 10 partitions

#### Tweets vs data types

The actual message can be represented as strings but there are probably metadata which makes a Document (Map) Type more feasible. Any date/time information would have to be stored as strings.

#### Conditional update of an item

Based on the [official docs](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_UpdateItem.html) there are several condition expressions available, e.g. `attribute_exists`, `contains` and `begins_with`.

The [CLI docs](https://docs.aws.amazon.com/cli/latest/reference/dynamodb/update-item.html) are quite overwhelming but [this guide](https://amazon-dynamodb-labs.workshop.aws/hands-on-labs/explore-cli/cli-writing-data.html#updating-data) helped me define the following command for adding a "note" to one of the entries in the ShoppingCart:

```shell
aws dynamodb update-item --table-name ShoppingCart \
  --update-expression 'SET Note = :note' \
  --key '{"ItemName":{"S":"Ken Burns: the Complete Box Set"}}' \
  --condition-expression 'attribute_not_exists(Note)' \
  --expression-attribute-values '{
    ":note": {"S": "Very cool"}
  }' \
  --return-values ALL_NEW
```

## Notes from Day 2

* Don't understand the "Getting Our Keys Right" section!
  * Long argument for a random `ReadingId` attribute (w/o range key)... 
  * Then something completely opposite in the actual definition
* LSB share/re-use HASH key from Key Schema (SensorId)
* Nice to use json files instead of very long argument strings to `aws` CLI.


### Scratch pad

> Delete stuff from Day 1
>
> ```shell
> aws dynamodb delete-table --table-name Book
> aws dynamodb delete-table --table-name ShoppingCart
> ```

```shell
aws dynamodb create-table --cli-input-json file://sensor-data-table.json
```

```shell
export STREAM_NAME=temperature-sensor-data
aws kinesis create-stream \
  --stream-name ${STREAM_NAME} \
  --shard-count 1
```

```shell
aws kinesis describe-stream --stream-name ${STREAM_NAME}
```

```shell
aws kinesis put-record \
  --stream-name ${STREAM_NAME} \
  --partition-key sensor-data \
  --data $(echo -n "Baby's first Kinesis record" | base64)
```

> I had to add base64 encoding. The command in the book returned _"nvalid base64: "Baby's first Kinesis record""_

```shell
export IAM_ROLE_NAME=kinesis-lambda-dynamodb

aws iam create-role \
  --role-name ${IAM_ROLE_NAME} \
  --assume-role-policy-document file://lambda-kinesis-role.json

aws iam attach-role-policy \
  --role-name ${IAM_ROLE_NAME} \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole

aws iam attach-role-policy \
  --role-name ${IAM_ROLE_NAME} \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
```

```shell
aws iam get-role --role-name ${IAM_ROLE_NAME}
```

```shell
export ROLE_ARN=$(aws iam get-role --role-name ${IAM_ROLE_NAME} | jq -r '.Role.Arn')
```

```shell
zip ProcessKinesisRecords.zip ProcessKinesisRecords.js 

aws lambda create-function \
  --region eu-north-1 \
  --function-name ProcessKinesisRecords \
  --zip-file fileb://ProcessKinesisRecords.zip \
  --role ${ROLE_ARN} \
  --handler ProcessKinesisRecords.kinesisHandler \
  --runtime nodejs18.x
```

> The book's "nodejs6.10" isn't supported any longer (not that surprising)

Updates are done (after re-zipping) using:

```shell
aws lambda update-function-code \
  --function-name ProcessKinesisRecords \
  --zip-file fileb://ProcessKinesisRecords.zip
```

```shell
aws lambda invoke \
  --invocation-type RequestResponse \
  --function-name ProcessKinesisRecords \
  --payload file://test-lambda-input.base64 \
  lambda-output.txt
```

> Again, I had to convert to base64 encoding as the book's syntax didn't work

> Also, the code's js-file didn't work so I had to adjust it. On the first attempt I got the following error:
>
>> _"Error: Cannot find module 'aws-sdk'\nRequire stack:\n- /var/task/ProcessKinesisRecords.js\n- /var/runtime/index.mjs"_
>
> Now I use ["v3 of the AWS SDK"](https://aws.amazon.com/blogs/developer/why-and-how-you-should-use-aws-sdk-for-javascript-v3-on-node-js-18/)


```shell
export KINESIS_STREAM_ARN?$(aws kinesis describe-stream --stream-name ${STREAM_NAME} | jq -s '.StreamDescription.StreamARN')

aws lambda create-event-source-mapping \
  --function-name ProcessKinesisRecords \
  --event-source-arn ${KINESIS_STREAM_ARN} \
  --starting-position LATEST
```

```shell
aws lambda list-event-source-mappings
```

```shell
export DATA=$(
  echo '{
    "sensor_id":"sensor-1",
    "temperature":99.7,
    "current_time":123456790
  }' | base64 -w0
)

aws kinesis put-record \
 --stream-name ${STREAM_NAME} \
 --partition-key sensor-data \
 --data $DATA
```

```shell
aws dynamodb scan --table-name SensorData
```

### Homework

* See Day 1's notes on the [DynamoDB Streams docs](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html)
  * Possible use-case; react on updates to the database 
* Tried out Python and [boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
  * see [python-app](./python-app/README.md)
  