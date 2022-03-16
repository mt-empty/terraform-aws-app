import json
import logging
import sys
import traceback

import boto3
from botocore.exceptions import ClientError
from config import BUCKET_NAME, CORS_HEADERS, IMAGE_TABLE_NAME, TAG_TABLE_NAME

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
s3 = boto3.resource("s3")


def handle_delete(body):
    try:
        url = body["url"]
        image_name = url.replace(f"https://{BUCKET_NAME}.s3.amazonaws.com/", "")

        # check if object exist
        is_object_exist_s3(BUCKET_NAME, image_name)

        # get image items from DynamoDB
        image = get_item_from_DB(IMAGE_TABLE_NAME, url)
        if "Item" not in image:
            raise ValueError("image cannot be found.")
        else:
            image = image["Item"]

        # delete related info in both tables in DB
        tag_table_response = delete_image_in_tags(image["tags"], image)
        if not tag_table_response:
            raise ValueError("Image cannot be removed from tags Table.")
        else:
            logger.info("Remove image: {} from tags succeeded".format(image["id"]))

        # delete image item in DB
        image_delete_response = delete_item_in_DB(IMAGE_TABLE_NAME, url)
        if not image_delete_response:
            raise ValueError("Image cannot be removed from images Table.")
        else:
            logger.info("Remove image: {} from images succeeded".format(image["id"]))

        # remove image from s3 bucket
        image_s3_delete_response = delete_item_in_bucket(BUCKET_NAME, image_name)
        if not image_s3_delete_response:
            raise ValueError("Image cannot be removed from S3 bucket.")
        else:
            logger.info("Remove image: {} from S3 succeeded".format(url))

    except ValueError as e:
        err_msg = json.dumps(
            {
                "errorType": "ValueError",
                "errorMessage": str(e),
            }
        )
        return {
            "body": f"{err_msg}",
        }
    except Exception:
        exception_type, exception_value, exception_traceback = sys.exc_info()
        traceback_string = traceback.format_exception(
            exception_type, exception_value, exception_traceback
        )
        err_msg = json.dumps(
            {
                "errorType": exception_type.__name__,
                "errorMessage": str(exception_value),
                "stackTrace": traceback_string,
            }
        )
        logger.error(err_msg)
        return {
            "body": f"{err_msg}",
        }
    else:
        return {
            "body": json.dumps({"Results": "Remove image:{} succeeded ".format(url)}),
        }


def is_object_exist_s3(bucket, key):
    try:
        s3.Object(bucket, key).load()
    except ClientError as e:
        logger.error(e.response["Error"]["Message"])
        if e.response["Error"]["Code"] == "404":
            # The object does not exist.
            raise ValueError("image object cannot be found in S3")
    else:
        return True


# function to delete the image id in related tags
def delete_image_in_tags(tags, image):
    # get the tag items of the image from DB
    related_tag_items = []
    for tag in tags:
        tag_item = get_item_from_DB(TAG_TABLE_NAME, tag)
        # if tag key is not found in DB, raise and error
        if "Item" not in tag_item:
            raise ValueError("tag:{} cannot be found in DB".format(tag))
        else:
            related_tag_items.append(tag_item["Item"])

    # look up image ids in relatedImages attribute of related tags
    for tag in related_tag_items:
        # remove related image id from tags
        if "relatedImages" in tag and image["id"] in tag["relatedImages"]:
            tag["relatedImages"].remove(image["id"])

    # update tags in DB
    for tag in related_tag_items:
        tag_id = tag["id"]
        if "relatedImages" in tag:
            tag_update_response = update_tag(tag_id, tag["relatedImages"])
            if not tag_update_response:
                raise ValueError("Image cannot be removed from tags Table.")
            else:
                logger.info("Remove image from tag: {} succeeded".format(tag_id))

    return True

    # function to get item from Dynamodb Table


# function to get item from Dynamodb Table
def get_item_from_DB(table_name, key):
    table = dynamodb.Table(table_name)
    try:
        response = table.get_item(Key={"id": key})
    except ClientError as e:
        logger.error(e.response["Error"]["Message"])
    else:
        return response

    # function to update tags in DynamoDB


# function to update tag in DynamoDB
def update_tag(tag_id, images):
    table = dynamodb.Table(TAG_TABLE_NAME)
    if images == set({}):
        response = table.update_item(
            Key={"id": tag_id},
            UpdateExpression="remove relatedImages",
        )
    else:
        response = table.update_item(
            Key={"id": tag_id},
            UpdateExpression="set relatedImages=:i",
            ExpressionAttributeValues={":i": images},
        )
    return response


# function to delete item in DynamoDB
def delete_item_in_DB(table_name, key):
    table = dynamodb.Table(table_name)
    try:
        response = table.delete_item(Key={"id": key})
    except ClientError as e:
        print(e.response["Error"]["Message"])
    else:
        return response

    # delete image in S3 bucket


# function to delete item in S3 bucket
def delete_item_in_bucket(bucket_name, key):
    bucket = s3.Bucket(bucket_name)
    try:
        # using image name as key
        response = bucket.delete_objects(Delete={"Objects": [{"Key": key}]})
    except ClientError as e:
        logger.info(e.response["Error"]["Message"])
    else:
        return response
