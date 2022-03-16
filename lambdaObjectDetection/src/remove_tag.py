import json
import logging
import sys
import traceback

import boto3
from botocore.exceptions import ClientError
from config import CORS_HEADERS, IMAGE_TABLE_NAME, TAG_TABLE_NAME

dynamodb = boto3.resource("dynamodb")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handle_remove(body):
    # get image url and tags to be deleted
    url = body["url"]
    tags = set(body["tags"])

    try:
        if len(tags) < 1 or len(url) < 1:
            raise ValueError("URL and tags cannot be null.")

        # get image item from DB with url as key
        image = get_item_from_DB(IMAGE_TABLE_NAME, url)
        if "Item" not in image:
            raise ValueError("image cannot be found.")
        else:
            image = image["Item"]

        # delete related info in both tables in DB
        delete_image_in_tags(tags, image)
        delete_tags_in_image(image["id"], image["tags"])

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
            "body": json.dumps(
                {
                    "Results": "Delete tags:{}, from image:{} succeeded ".format(
                        tags, image["id"]
                    )
                }
            ),
        }


# function to check if all tags exist, if any request tag is found not exist for image tags, return list of unfound tags
def is_all_tags_in_image(tags, image_tags):
    unfound_tags = []
    # look up detected tags in image, and remove if find a match,
    # add to unfound_tags if not found in image item.
    for tag in tags:
        if tag not in image_tags:
            unfound_tags.append(tag)
    if not unfound_tags:
        return True

    return str(unfound_tags)


# function to delete the image id in related tags
def delete_image_in_tags(tags, image):
    # verify if all the tags to be deleted exist in image tags
    tags_exist_res = is_all_tags_in_image(tags, image["tags"])
    if tags_exist_res is not True:
        raise ValueError("tag: {} cannot be found in image".format(tags_exist_res))

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
        if image["id"] in tag["relatedImages"]:
            tag["relatedImages"].remove(image["id"])

    # update tags in DB
    for tag in related_tag_items:
        tag_id = tag["id"]
        tag_update_response = update_tag(tag_id, tag["relatedImages"])
        if not tag_update_response:
            raise ValueError("Image cannot be removed from tags Table.")
        else:
            logger.info("Remove image from tag: {} succeeded".format(tag_id))


# function to delete tags in image item
def delete_tags_in_image(image_id, tags):
    # update images in DB
    image_update_res = update_image(image_id, tags)
    if not image_update_res:
        raise ValueError("Tags cannot be removed from images Table.")
    else:
        logger.info("Remove tags from image: {} succeeded".format(image_id))


# function to get item from Dynamodb Table
def get_item_from_DB(table_name, key):
    table = dynamodb.Table(table_name)
    try:
        response = table.get_item(Key={"id": key})
    except ClientError as e:
        logger.error(e.response["Error"]["Message"])
    else:
        return response


# function to update images in DynamoDB
def update_image(image_id, tags):
    table = dynamodb.Table(IMAGE_TABLE_NAME)

    # if tags is empty remove the attribute all together, because dynamodb doesn't all empty string sets
    if tags == set({}):
        response = table.update_item(
            Key={"id": image_id},
            UpdateExpression="remove tags",
        )
    else:
        response = table.update_item(
            Key={"id": image_id},
            UpdateExpression="set tags=:t",
            ExpressionAttributeValues={":t": tags},
        )

    return response


# function to update tags in DynamoDB
def update_tag(tag_id, images):
    table = dynamodb.Table(TAG_TABLE_NAME)

    # if relatedImages is empty remove the attribute all together, because dynamodb doesn't all empty string sets
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
