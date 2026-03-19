import json
import boto3
import os

# Initialize DynamoDB resource lazily
dynamodb = None
TABLE_NAME = os.environ.get('TABLE_NAME', 'visitor_count_table')

def lambda_handler(event, context):
    """
    AWS Lambda handler for incrementing and returning visitor count.
    """
    global dynamodb
    if not dynamodb:
        # Initialized on first call within execution context
        dynamodb = boto3.resource('dynamodb')
        
    try:
        table = dynamodb.Table(TABLE_NAME)
        
        # Atomically increment the 'count' attribute
        # If the item doesn't exist, it will be created with count=0 then incremented?
        # Actually, for ADD to work on non-existent item, it depends on the DB setup.
        # It's better to use UpdateExpression that handles init if needed, 
        # or assume Terraform initializes it.
        # Standard approach:
        response = table.update_item(
            Key={'id': 'visitor'},
            UpdateExpression='ADD #c :incr',
            ExpressionAttributeNames={'#c': 'count'},
            ExpressionAttributeValues={':incr': 1},
            ReturnValues='UPDATED_NEW'
        )
        
        count = response.get('Attributes', {}).get('count', 0)
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps({'count': int(count)})
        }
        
    except Exception as e:
        print(f"Error updating count: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Internal Server Error', 'message': str(e)})
        }
