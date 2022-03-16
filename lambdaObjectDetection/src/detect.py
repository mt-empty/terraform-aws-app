import base64
import json
import logging

import boto3
from config import CORS_HEADERS, TAG_TABLE_NAME
from object_detection import get_prediction

dynamodb = boto3.client("dynamodb")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handle_detect(body):
    """
    This function handles the detect image functionality

    Args:
        body (JSON): body of the event

    Returns:
        JSON: the results of detect request
    """
    image = base64.b64decode(body["content"])
    predictions = get_prediction(image)

    relatedImages = []

    for prediction in predictions:
        tagid = {"S": str(prediction)}
        response = dynamodb.get_item(TableName=TAG_TABLE_NAME, Key={"id": tagid})
        logger.info(f" {TAG_TABLE_NAME} response: {response}")
        try:
            items = response.get("Item").get("relatedImages").get("SS")
            relatedImages.extend(items)
        except AttributeError as e:
            logger.info(f"AttributeError: {e}")
            continue

    return {
        "body": json.dumps({"links": relatedImages}),
    }
