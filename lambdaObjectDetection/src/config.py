"""
File used to store configs
"""
IMAGE_TABLE_NAME = "images"
TAG_TABLE_NAME = "tags"
BUCKET_NAME = "terraform-aws-images-prod"
CORS_HEADERS = {
    "Access-Control-Allow-Headers": "*",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "OPTIONS,POST,PUT",
}
