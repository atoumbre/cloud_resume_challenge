import os
import json
import boto3
import pytest
from moto import mock_aws

# Set environment variable for testing
os.environ['TABLE_NAME'] = 'test_visitor_count_table'

from app import lambda_handler

@pytest.fixture(scope='function')
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'

@pytest.fixture(scope='function')
def dynamodb_mock(aws_credentials):
    """Mocked DynamoDB client."""
    with mock_aws():
        yield boto3.resource('dynamodb', region_name='us-east-1')

def test_lambda_handler_creates_item_if_not_exists(dynamodb_mock):
    # Create the table
    dynamodb_mock.create_table(
        TableName='test_visitor_count_table',
        KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 5, 'WriteCapacityUnits': 5}
    )
    
    # Run handler
    response = lambda_handler({}, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['count'] == 1

def test_lambda_handler_increments_count(dynamodb_mock):
    # Create the table
    dynamodb_mock.create_table(
        TableName='test_visitor_count_table',
        KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 5, 'WriteCapacityUnits': 5}
    )
    
    table = dynamodb_mock.Table('test_visitor_count_table')
    # Pre-populate item
    table.put_item(Item={'id': 'visitor', 'count': 5})
    
    # Run handler
    response = lambda_handler({}, None)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['count'] == 6
