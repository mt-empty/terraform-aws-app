import base64
import io
import json
import logging
import uuid
from urllib.parse import unquote_plus

import boto3
from config import BUCKET_NAME, CORS_HEADERS, IMAGE_TABLE_NAME, TAG_TABLE_NAME
from object_detection import get_prediction

dynamodb = boto3.client("dynamodb")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handle_upload(body):
    """
    This function handles the upload functionality

    Args:
        body (JSON): body of the event

    Returns:
        JSON: the results of upload request
    """

    image = base64.b64decode(body["content"])
    image_name = unquote_plus(body["image_name"])
    imageuuid = str(uuid.uuid4())

    predictions = get_prediction(image)
    image_url = f"https://{BUCKET_NAME}.s3.amazonaws.com/{imageuuid}"

    logger.info(f"Predicted {predictions} after processing the uploaded image")

    # put image in IMAGE_TABLE_NAME
    response = dynamodb.put_item(
        TableName=IMAGE_TABLE_NAME,
        Item={
            "id": {"S": image_url},
            "name": {"S": image_name},
            "tags": {"SS": predictions},
        },
    )

    logger.info(f" {IMAGE_TABLE_NAME} response: {response}")

    for prediction in predictions:
        tagid = {"S": str(prediction)}

        # update TAG_TABLE_NAME
        response = dynamodb.update_item(
            TableName=TAG_TABLE_NAME,
            Key={"id": tagid},
            # img and images are a placegolder , images refers to the ExpressionAttributeValues
            UpdateExpression="ADD #ri :vals",
            ExpressionAttributeNames={
                # this is just remapping the image attribute in the document/table
                "#ri": "relatedImages",
            },
            ExpressionAttributeValues={":vals": {"SS": [image_url]}},
            ReturnValues="UPDATED_NEW",
        )

        logger.info(f" {TAG_TABLE_NAME} response: {response}")

    s3_client = boto3.client("s3")
    response = s3_client.upload_fileobj(io.BytesIO(image), BUCKET_NAME, imageuuid)

    logger.info(
        f"The image {image_url} was uploaded to '{BUCKET_NAME}' bucket: {response}"
    )

    return {
        "body": json.dumps(
            {
                "results": f"successfully added {len(predictions)} tag(s),: {predictions} \
to the database after processing the uploaded image, {image_url}",
                "predictions": predictions,
                "image_url": image_url,
            }
        ),
    }
