import os
import json

import boto3

dynamodb = None
TABLE_NAME = os.environ.get("TABLE_NAME", "visitor_count_table")


def get_dynamodb_resource():
    global dynamodb
    if dynamodb is None:
        dynamodb = boto3.resource("dynamodb")
    return dynamodb


def lambda_handler(event, context):
    """Increment and return the visitor count."""
    try:
        table = get_dynamodb_resource().Table(TABLE_NAME)
        response = table.update_item(
            Key={"id": "visitor"},
            UpdateExpression="ADD #count :increment",
            ExpressionAttributeNames={"#count": "count"},
            ExpressionAttributeValues={":increment": 1},
            ReturnValues="UPDATED_NEW",
        )

        count = response.get("Attributes", {}).get("count", 0)

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "OPTIONS,POST,GET",
            },
            "body": json.dumps({"count": int(count)}),
        }

    except Exception as exc:
        print(f"Error updating count: {exc}")
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"error": "Internal Server Error"}),
        }
