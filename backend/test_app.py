import json
import os

import boto3
import pytest
from moto import mock_aws

os.environ["TABLE_NAME"] = "test_visitor_count_table"

import app

TEST_TABLE_NAME = "test_visitor_count_table"


@pytest.fixture(autouse=True)
def reset_dynamodb_resource():
    app.dynamodb = None
    app.TABLE_NAME = TEST_TABLE_NAME
    yield
    app.dynamodb = None


@pytest.fixture(scope="function")
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    yield
    for key in ("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SECURITY_TOKEN", "AWS_SESSION_TOKEN"):
        os.environ.pop(key, None)


@pytest.fixture(scope="function")
def dynamodb_mock(aws_credentials):
    """Mocked DynamoDB client."""
    with mock_aws():
        resource = boto3.resource("dynamodb", region_name="us-east-1")
        app.dynamodb = resource
        yield resource


def create_table(resource):
    resource.create_table(
        TableName=TEST_TABLE_NAME,
        KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )


def test_lambda_handler_creates_item_if_not_exists(dynamodb_mock):
    create_table(dynamodb_mock)

    response = app.lambda_handler({}, None)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["count"] == 1


def test_lambda_handler_increments_count(dynamodb_mock):
    create_table(dynamodb_mock)
    table = dynamodb_mock.Table(TEST_TABLE_NAME)
    table.put_item(Item={"id": "visitor", "count": 5})

    response = app.lambda_handler({}, None)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["count"] == 6


def test_lambda_handler_returns_500_when_table_is_missing(dynamodb_mock):
    dynamodb_mock.create_table(
        TableName="another_table",
        KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )

    response = app.lambda_handler({}, None)

    assert response["statusCode"] == 500
    body = json.loads(response["body"])
    assert body["error"] == "Internal Server Error"
