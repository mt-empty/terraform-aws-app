- [object_detection file](#object_detection-file)
- [Endpoints](#endpoints)
- [Developing on cloud9](#developing-on-cloud9)


## object_detection file

object_detection.py  is a Python script to perform object detection using tiny yolo weights and neural net.
The only requirements are opencv-python, numpy, and make sure you use python 3.5 or higher and upgrade your pip tool


## Endpoints

There are in total six endpoints corresponding to six functionalities, each with its own JSON schema:

- /health (GET), for checking API health.
- /upload (PUT), for uploading images.
  - `{"image_name": ImageNameString, "content": base64ImageString}`
- /detect (POST), for finding images based on the tags of an image.
  - `{"content": base64ImageString}`
- /search (POST), for finding an image based on the tags.
  - `{"tags": [tag1String, tag2String]}`
- /remove (POST), for removing tags from an image.
  - `{"url": ImageURLString, "tags": [tag1String, tag2String]}`
- /delete (POST), for deleting an image
  - `{"url": ImageURLString}`

Before calling these endpoints, you need to include the `Authorization` token header.

Full examples of JSON schema for each endpoints are available in the [events directory](./events/)


## Developing on cloud9

Although you developing can be easily performed on VScode, it can be difficult to setup for new comers, so AWS Cloud9 is an option.

First, create a cloud 9 environment, once you get to the IDE, follow the following steps:

1. Upload the folder `lambdaObjectDetection` folder
2. `cd lambdaObjectDetection`
3. Change `BUCKET_NAME` to a different name, currently used in the following files:
   1. `config.py`
   2. `template.yaml`
4. Optional, change the Test user `EMAIL` in `template.yaml`, to any email that you have access to.
5. In the `template.yaml` document replace `Role` with your `ROLE ARN` which can be found here https://console.aws.amazon.com/iam/home?#/roles/LabRole?section=permissions
6. run `sam build && sam deploy --config-file samconfig.toml --resolve-image-repos --resolve-s3`

Once deployed, it will output the required information for frontend integration, an example of output is shown below:

```
Key                 UserPoolClientId
Description         -
Value               example

Key                 UserPoolId
Description         -
Value               example

Key                 IdentityPoolId
Description         -
Value               example

Key                 API
Description         API Gateway endpoint URL for Prod stage for Object Detection function
Value               https://example.execute-api.example-region.amazonaws.com/prod/
```
