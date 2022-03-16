
## object_detection file

object_detection.py  is a Python script to perform object detection using tiny yolo weights and neural net.
The only requirements are opencv-python, numpy, and make sure you use python 3.5 or higher and upgrade your pip tool


## Deploying on cloud9

Create a cloud 9 environment

1. Upload the folder `lambdaObjectDetection` folder
2. `cd lambdaObjectDetection`
3. Change `BUCKET_NAME` to a different name, because other team members might have deployed this and therefore the no longer is unique, currently used in the following files:
   1. `config.py`
   3. `template.yaml`
4. Optional, change the Test user `EMAIL` in `template.yaml`, to any email that you have access to.
5. In the `template.yaml` document replace `Role` with your `ROLE ARN` which can be found here https://console.aws.amazon.com/iam/home?#/roles/LabRole?section=permissions
6. run `sam build && sam deploy --config-file samconfig.toml --resolve-image-repos --resolve-s3`

Once deployed, it will output the required information for frontend integration, an example of output is shown below:

```
Key                 UserPoolClientId
Description         -
Value               74e348ocoigjdg4to1vuvab6ct

Key                 UserPoolId
Description         -
Value               us-east-1_ogHUzN2oz

Key                 IdentityPoolId
Description         -
Value               us-east-1:5dacd94c-1512-44b5-8d46-b5abb983f29e

Key                 API
Description         API Gateway endpoint URL for Prod stage for Object Detection function
Value               https://hamav2dn6k.execute-api.us-east-1.amazonaws.com/Prod/
```

## Endpoints

There are in total 5 endpoints corrosponding to 5 functionalities, each with its own JSON schema:

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

Before calling these endpoints, you need to include the `Autherization` token header.

Full examples of JSON schema for each endpoints are available in the [events directory](../events/)
