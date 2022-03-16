import json
import logging
import sys
import traceback

from config import CORS_HEADERS
from delete_image import handle_delete
from detect import handle_detect
from remove_tag import handle_remove
from search import handle_search
from upload import handle_upload

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    This function handles all Fat lambda methods

    Args:
        event (JSON): the event object
        context (JSON): the context within AWS

    Returns:
        JSON: the results of incoming requests
    """
    try:
        logger.info(f" Event: {event}")
        if isinstance(event["body"], str):
            body = json.loads(event["body"])
        else:
            body = event["body"]

        logger.info(event)
        path = event["rawPath"]

        if path == "/prod/upload":
            return handle_upload(body)

        elif path == "/prod/detect":
            return handle_detect(body)

        elif path == "/prod/remove":
            return handle_remove(body)

        elif path == "/prod/delete":
            return handle_delete(body)

        elif path == "/prod/search":
            return handle_search(body)
        else:
            return {
                "body": json.dumps("resource not found"),
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
