import json
import logging

import boto3
from config import CORS_HEADERS, TAG_TABLE_NAME

dynamodb = boto3.client("dynamodb")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handle_search(body):
    """
    This function handles the search functionality

    Args:
        body (JSON): body of the event

    Returns:
        JSON: the results of search request
    """
    tags = body["tags"]

    relatedImages = []

    for tag in tags:
        tagid = {"S": str(tag)}
        response = dynamodb.get_item(TableName=TAG_TABLE_NAME, Key={"id": tagid})

        logger.info(f" {TAG_TABLE_NAME} response: {response}")
        if response.get("Item") is not None:
            items = response.get("Item").get("relatedImages").get("SS")
            if items is not None:
                relatedImages.extend(items)

    return {
        "body": json.dumps({"links": relatedImages}),
    }
