# Very much inspired by this example/guide:
# - https://boto3.amazonaws.com/v1/documentation/api/latest/guide/dynamodb.html

import boto3
import time
from boto3.dynamodb.conditions import Key, Attr

def print_delta(ref_time, heading):
  print(f"### {heading}: [{(time.time_ns() - ref_time)/1000} us]")

print("### Starting ###")
ref_time=time.time_ns()

# Get the service resource.
dynamodb = boto3.resource('dynamodb')

print_delta(ref_time, "Service resource obtained")
ref_time = time.time_ns()

# Create the DynamoDB table.
table = dynamodb.create_table(
    TableName='users',
    KeySchema=[
        {
            'AttributeName': 'first_name',
            'KeyType': 'HASH'
        },
        {
            'AttributeName': 'last_name',
            'KeyType': 'RANGE'
        }
    ],
    AttributeDefinitions=[
        {
            'AttributeName': 'first_name',
            'AttributeType': 'S'
        },
        {
            'AttributeName': 'last_name',
            'AttributeType': 'S'
        },
    ],
    ProvisionedThroughput={
        'ReadCapacityUnits': 1,
        'WriteCapacityUnits': 1
    }
)

print_delta(ref_time, "Create table completed")
ref_time = time.time_ns()

# Wait until the table exists.
table.wait_until_exists()

print_delta(ref_time, "Table available")

# Print out some data about the table.
print(f"Table created: {table}")
print(f"Number of users in table: {table.item_count}")
print("Adding users...")

ref_time = time.time_ns()

table.put_item(
   Item={
        'username': 'ulf',
        'first_name': 'Ulf',
        'last_name': 'Ivraeus',
        'age': 47,
        'account_type': 'coder',
    }
)

table.put_item(
   Item={
        'username': 'sweden',
        'first_name': 'Ulf',
        'last_name': 'Kristersson',
        'age': 60,
        'account_type': 'prime_minister',
    }
)

print_delta(ref_time, "Put 2 Items")

print(f"Number of users in table: {table.item_count}")
print("Wait 10s...")
time.sleep(10)
print(f"Number of users in table: {table.item_count}") # <---? this isn't updated; always 0?

print("Query...")
ref_time = time.time_ns()

response_1 = table.get_item(
    Key={
        'first_name': 'Ulf',
        'last_name': 'Ivraeus'
    }
)

print_delta(ref_time, "Get Item completed")

print(f"Result from query 1:\n---\n{response_1['Item']}\n---\n")

print("Query all Ulfs...")
ref_time = time.time_ns()

response_2 = table.query(
    KeyConditionExpression=Key('first_name').eq('Ulf')
)

print_delta(ref_time, "Get Items completed")

print(f"Result from query 2:\n---\n{response_2['Items']}\n---\n")

print("Scan for old users...")
ref_time = time.time_ns()

response_3 = table.scan(
    FilterExpression=Attr('age').lt(50)
)

print_delta(ref_time, "Scan Items completed")

print(f"Result from query 3:\n---\n{response_3['Items']}\n---\n")

print("Delete table...")
ref_time = time.time_ns()

table.delete()

print_delta(ref_time, "Delete Table completed")

print("Bye")

