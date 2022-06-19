terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.6.0"
    }
    null = {
      version = "~> 3.0.0"
    }
  }
  cloud {
    organization = "example-org-76fbff"

    workspaces {
      name = "aws-terraform-app"
    }
  }
}

provider "aws" {
  region = var.region
}


data "aws_caller_identity" "current_identity" {}

# locals cannot be changed at runtime
locals {
  account_id          = data.aws_caller_identity.current_identity.account_id
  prefix              = "objdet"
  ecr_repository_name = "${local.prefix}-image-repo"
  region              = var.region
  ecr_image_tag       = "latest"
  table_names         = ["images", "tags"]
  paths = {
    "Upload" = "Method"
    "Detect" = "Method"
    "Remove" = "Method"
    "Delete" = "Method"
    "Search" = "Method"
  }
}


resource "aws_s3_bucket" "S3Bucket" {
  bucket        = var.bucket_name
  force_destroy = true
}

# resource "aws_s3_bucket_acl" "S3Bucket_acl" {
#   bucket = aws_s3_bucket.S3Bucket.id
#   acl    = "private"
# }

# the application requires two tables
resource "aws_dynamodb_table" "imageDB" {
  for_each       = toset(local.table_names)
  name           = each.key
  hash_key       = "id"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  attribute {
    name = "id"
    type = "S"
  }

  lifecycle {
    # this can help avoid zero time down time
    create_before_destroy = false
    # prevents terraform from trying to revert metadata being set elsewhere
    ignore_changes = [
      # some resource have metadata
      # modified automaticall outside
      # of terraform
      tags
    ]
    # this will prevent terraform from running a plan that destroys this resource
    prevent_destroy = false
  }
}


# Store the image in aws container registry
resource "aws_ecr_repository" "docker_image" {
  name                 = local.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# terraform is not used for building docker images, but we can use this hack
resource "null_resource" "ecr_image" {
  triggers = {
    src_hash = sha1(join("", [for f in fileset("${path.module}/../lambdaObjectDetection/src/", "**") : filesha1("${path.module}/../lambdaObjectDetection/src/${f}")]))
    #  docker_file = filemd5("${path.module}/../lambdaObjectDetection/git_client/Dockerfile")
  }

  # this will be exucted on local machine
  provisioner "local-exec" {
    command = <<EOF
           aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${local.region}.amazonaws.com
           docker build -t ${aws_ecr_repository.docker_image.repository_url}:${local.ecr_image_tag} ${path.module}/../lambdaObjectDetection/src/
           docker push ${aws_ecr_repository.docker_image.repository_url}:${local.ecr_image_tag}
       EOF
  }
}

data "aws_ecr_image" "lambda_image" {
  depends_on = [
    null_resource.ecr_image
  ]
  repository_name = local.ecr_repository_name
  image_tag       = local.ecr_image_tag
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "${local.prefix}for_lambda"

  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Action : "sts:AssumeRole",
          Principal : {
            Service : "lambda.amazonaws.com"
          },
          Effect : "Allow",
          Sid : ""
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect : "Allow",
      Action : "*",
      Resource : "*"
      }
    ]
    }
  )
}


# allow it to create cloudwatch logs
# data "aws_iam_policy_document" "lambda" {
#   statement {
#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents"
#     ]
#     effect    = "Allow"
#     resources = ["*"]
#     sid       = "CreateCloudWatchLogs"
#   }
# }

# resource "aws_iam_policy" "lambda" {
#   name   = "${local.prefix}-lambda-policy"
#   path   = "/"
#   policy = data.aws_iam_policy_document.lambda.json
# }


# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  for_each = {
    Upload = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ApiGatewayApi.id}/*/${aws_apigatewayv2_route.Upload.route_key}",
    Detect = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ApiGatewayApi.id}/*/${aws_apigatewayv2_route.Upload.route_key}",
    Search = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ApiGatewayApi.id}/*/${aws_apigatewayv2_route.Upload.route_key}",
    Delete = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ApiGatewayApi.id}/*/${aws_apigatewayv2_route.Upload.route_key}",
    Remove = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ApiGatewayApi.id}/*/${aws_apigatewayv2_route.Upload.route_key}",
    # Upload = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ApiGatewayApi.id}/*/${aws_api_gateway_method.UploadMethod.http_method}${aws_api_gateway_resource.Upload.path}",
    # Detect = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ApiGatewayApi.id}/*/${aws_api_gateway_method.DetectMethod.http_method}${aws_api_gateway_resource.Detect.path}",
    # Search = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ApiGatewayApi.id}/*/${aws_api_gateway_method.SearchMethod.http_method}${aws_api_gateway_resource.Search.path}",
    # Delete = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ApiGatewayApi.id}/*/${aws_api_gateway_method.DeleteMethod.http_method}${aws_api_gateway_resource.Delete.path}",
    # Remove = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ApiGatewayApi.id}/*/${aws_api_gateway_method.RemoveMethod.http_method}${aws_api_gateway_resource.Remove.path}"
  }
  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ObjectDetectionFunction.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_apigatewayv2_api.ApiGatewayApi.execution_arn}/*"
  # source_arn = each.value
}

resource "aws_lambda_function" "ObjectDetectionFunction" {
  # depends_on = [
  #   null_resource.ecr_image
  # ]
  function_name = var.function_name
  description   = var.function_name
  timeout       = 10
  memory_size   = 512
  role          = aws_iam_role.iam_for_lambda.arn
  image_uri     = "${aws_ecr_repository.docker_image.repository_url}@${data.aws_ecr_image.lambda_image.id}"
  package_type  = "Image"
}

# module "lambda_function_from_container_image" {
#   source = "../../"
#   role_name = aws_iam_role.iam_for_lambda.arn

#   function_name = var.function_name
#   description   = var.function_name

#   ##################
#   # Container Image
#   ##################
#   docker_build_root = "terraform-aws-app/../lambdaObjectDetection/src/dockerfile"
#   package_type = "Image"
# }


# for api gateway best to use the serverless module
# https://registry.terraform.io/modules/terraform-aws-modules/apigateway-v2/aws/latest
resource "aws_apigatewayv2_api" "ApiGatewayApi" {
  depends_on = [
    aws_lambda_function.ObjectDetectionFunction
  ]
  protocol_type = "HTTP"
  name          = "ApiGatewayApi"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 500
  }

}


resource "aws_apigatewayv2_integration" "UploadIntegration" {
  api_id                 = aws_apigatewayv2_api.ApiGatewayApi.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "Upload" {
  api_id    = aws_apigatewayv2_api.ApiGatewayApi.id
  route_key = "PUT /upload"

  target = "integrations/${aws_apigatewayv2_integration.UploadIntegration.id}"
}

resource "aws_apigatewayv2_integration" "DetectIntegration" {
  api_id                 = aws_apigatewayv2_api.ApiGatewayApi.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "Detect" {
  api_id    = aws_apigatewayv2_api.ApiGatewayApi.id
  route_key = "POST /detect"

  target = "integrations/${aws_apigatewayv2_integration.DetectIntegration.id}"
}


resource "aws_apigatewayv2_integration" "SearchIntegration" {
  api_id                 = aws_apigatewayv2_api.ApiGatewayApi.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "Search" {
  api_id    = aws_apigatewayv2_api.ApiGatewayApi.id
  route_key = "POST /search"

  target = "integrations/${aws_apigatewayv2_integration.SearchIntegration.id}"
}


resource "aws_apigatewayv2_integration" "DeleteIntegration" {
  api_id                 = aws_apigatewayv2_api.ApiGatewayApi.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "Delete" {
  api_id    = aws_apigatewayv2_api.ApiGatewayApi.id
  route_key = "POST /delete"

  target = "integrations/${aws_apigatewayv2_integration.DeleteIntegration.id}"
}

resource "aws_apigatewayv2_integration" "RemoveIntegration" {
  api_id                 = aws_apigatewayv2_api.ApiGatewayApi.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "Remove" {
  api_id    = aws_apigatewayv2_api.ApiGatewayApi.id
  route_key = "POST /remove"

  target = "integrations/${aws_apigatewayv2_integration.RemoveIntegration.id}"
}

resource "aws_apigatewayv2_integration" "HealthIntegration" {
  api_id                 = aws_apigatewayv2_api.ApiGatewayApi.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "Health" {
  api_id    = aws_apigatewayv2_api.ApiGatewayApi.id
  route_key = "GET /health"

  target = "integrations/${aws_apigatewayv2_integration.HealthIntegration.id}"
}


resource "aws_apigatewayv2_deployment" "APIDeployment" {
  api_id = aws_apigatewayv2_api.ApiGatewayApi.id
  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_apigatewayv2_route.Upload.id,
      aws_apigatewayv2_integration.UploadIntegration.id,
      aws_apigatewayv2_route.Detect.id,
      aws_apigatewayv2_integration.DetectIntegration.id,
      aws_apigatewayv2_route.Search.id,
      aws_apigatewayv2_integration.SearchIntegration.id,
      aws_apigatewayv2_route.Delete.id,
      aws_apigatewayv2_integration.DeleteIntegration.id,
      aws_apigatewayv2_route.Remove.id,
      aws_apigatewayv2_integration.RemoveIntegration.id,
      aws_apigatewayv2_route.Health.id,
      aws_apigatewayv2_integration.HealthIntegration.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "APIStageName" {
  api_id        = aws_apigatewayv2_api.ApiGatewayApi.id
  deployment_id = aws_apigatewayv2_deployment.APIDeployment.id
  name          = "prod"
}

# resource "aws_lambda_invocation" "LambdaTrigger" {
#   function_name = aws_lambda_function.ObjectDetectionFunction.function_name

#   triggers = {
#     redeployment = sha1(jsonencode([
#       aws_lambda_function.ObjectDetectionFunction.environment
#     ]))
#   }

#   input = jsonencode({
#     key1 = "value1"
#     key2 = "value2"
#   })
# }

# Build react app and upload to S3

resource "null_resource" "populateAPIEndpoint" {

  provisioner "local-exec" {
    command = <<EOF
            cd ../frontend
            sed -i -r 's|https.*.com|${aws_apigatewayv2_api.ApiGatewayApi.api_endpoint}|g' .env
            npm install
            npm run build
       EOF
  }
  # Map of String) A map of arbitrary strings that,
  # when changed, will force the null resource to be replaced, re-running any associated provisioners.
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "aws_s3_bucket" "ReactAppBucket" {
  depends_on = [
    null_resource.populateAPIEndpoint
  ]
  bucket        = "object-detection-react-app"
  force_destroy = true
}

# make the S3 bucket public
resource "aws_s3_bucket_acl" "ReactAppBucketACL" {
  bucket = aws_s3_bucket.ReactAppBucket.id
  acl    = "public-read"
}

# enable static website hosting for s3 bucket
resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.ReactAppBucket.bucket

  index_document {
    suffix = "index.html"
  }
}

# Upload react app to s3 bucket
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.ReactAppBucket.id
  key    = "index.html"

  source       = "../frontend/dist/index.html"
  etag         = file("../frontend/dist/index.html")
  acl          = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "main" {
  bucket = aws_s3_bucket.ReactAppBucket.id
  key    = "main.js"

  source = "../frontend/dist/main.js"
  etag   = filemd5("../frontend/dist/main.js")
  acl    = "public-read"
}
