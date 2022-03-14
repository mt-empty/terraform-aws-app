terraform {
  # required_providers {
  #   aws = {
  #     bucket         = "learnterraform"
  #     source         = "hashicorp/aws"
  #     region         = "ap-southeast-2"
  #     dynamodb_table = "terraform-state-locking"
  #     encrypt        = true
  #     version        = "~> 3.27"
  #   }
  # }
  required_version = ">= 0.14.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    null = {
      version = "~> 3.0.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
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


# resources can be physical, virtual or logical(ecs) such as heroku application
# 2 strings : resource type and resource name, these define the id of the resource
resource "aws_security_group" "instances" {
  name = "instance-security-group"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instances.id

  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_instance" "server" {
  count           = 2
  ami             = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instances.name]
  tags = {
    Name = "Server ${count.index}"
  }
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World ${count.index}" > index.html
              python3 -m http.server 8080 &
              EOF
}


resource "aws_s3_bucket" "S3Bucket" {
  bucket = var.bucket_name
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

# resource "aws_dynamodb_table" "tagDB" {
#   name             = "tags"
#   hash_key         = "id"
#   billing_mode = "PROVISIONED"
#   read_capacity    = 10
#   write_capacity   = 10
#   attribute {
#     name = "id"
#     type = "S"
#   }

#   lifecycle {
#     # this can help avoid zero time down time
#     create_before_destroy = false
#     # prevents terraform from trying to revert metadata being set elsewhere
#     ignore_changes = [
#       # some resource have metadata
#       # modified automaticall outside
#       # of terraform
#       tags
#     ]
#     # this will prevent terraform from running a plan that destroys this resource
#     prevent_destroy = false
#   }
# }


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
    src_hash = sha1(join("", [for f in fileset("${path.module}/lambdaObjectDetection/src/", "**") : filesha1("${path.module}/lambdaObjectDetection/src/${f}")]))
    #  docker_file = filemd5("${path.module}/lambdaObjectDetection/git_client/Dockerfile")
  }

  # this will be exucted on local machine
  provisioner "local-exec" {
    command = <<EOF
           aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${local.region}.amazonaws.com
           docker build -t ${aws_ecr_repository.docker_image.repository_url}:${local.ecr_image_tag} ${path.module}/lambdaObjectDetection/src/
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

#
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
data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "CreateCloudWatchLogs"
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${local.prefix}-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json
}


# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  for_each = {
    Upload = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.ApiGatewayApi.id}/*/${aws_api_gateway_method.UploadMethod.http_method}${aws_api_gateway_resource.Upload.path}",
    Detect = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.ApiGatewayApi.id}/*/${aws_api_gateway_method.DetectMethod.http_method}${aws_api_gateway_resource.Detect.path}",
    Search = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.ApiGatewayApi.id}/*/${aws_api_gateway_method.SearchMethod.http_method}${aws_api_gateway_resource.Search.path}",
    Delete = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.ApiGatewayApi.id}/*/${aws_api_gateway_method.DeleteMethod.http_method}${aws_api_gateway_resource.Delete.path}",
    Remove = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.ApiGatewayApi.id}/*/${aws_api_gateway_method.RemoveMethod.http_method}${aws_api_gateway_resource.Remove.path}"
  }
  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ObjectDetectionFunction.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  # source_arn = "${aws_api_gateway_rest_api.ApiGatewayApi.execution_arn}/*/*/*"
  source_arn = each.value
  }


resource "aws_lambda_function" "ObjectDetectionFunction" {
  depends_on = [
    null_resource.ecr_image
  ]
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
#   docker_build_root = "terraform-aws-app/lambdaObjectDetection/src/dockerfile"
#   package_type = "Image"
# }


# for api gateway best to use the serverless module
# https://registry.terraform.io/modules/terraform-aws-modules/apigateway-v2/aws/latest
resource "aws_api_gateway_rest_api" "ApiGatewayApi" {
  depends_on = [
    aws_lambda_function.ObjectDetectionFunction
  ]
  name = "ApiGatewayApi"

}

resource "aws_api_gateway_resource" "Upload" {
  rest_api_id = aws_api_gateway_rest_api.ApiGatewayApi.id
  parent_id   = aws_api_gateway_rest_api.ApiGatewayApi.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_method" "UploadMethod" {
  rest_api_id   = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id   = aws_api_gateway_resource.Upload.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "UploadIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id             = aws_api_gateway_resource.Upload.id
  http_method             = aws_api_gateway_method.UploadMethod.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  timeout_milliseconds    = 29000

  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/xml" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}


resource "aws_api_gateway_resource" "Detect" {
  rest_api_id = aws_api_gateway_rest_api.ApiGatewayApi.id
  parent_id   = aws_api_gateway_rest_api.ApiGatewayApi.root_resource_id
  path_part   = "detect"
}

resource "aws_api_gateway_method" "DetectMethod" {
  rest_api_id   = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id   = aws_api_gateway_resource.Detect.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "DetectIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id             = aws_api_gateway_resource.Detect.id
  http_method             = aws_api_gateway_method.DetectMethod.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  timeout_milliseconds    = 29000

  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/xml" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}


resource "aws_api_gateway_resource" "Search" {
  rest_api_id = aws_api_gateway_rest_api.ApiGatewayApi.id
  parent_id   = aws_api_gateway_rest_api.ApiGatewayApi.root_resource_id
  path_part   = "search"
}

resource "aws_api_gateway_method" "SearchMethod" {
  rest_api_id   = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id   = aws_api_gateway_resource.Search.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "SearchIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id             = aws_api_gateway_resource.Search.id
  http_method             = aws_api_gateway_method.SearchMethod.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  timeout_milliseconds    = 29000

  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/xml" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}


resource "aws_api_gateway_resource" "Delete" {
  rest_api_id = aws_api_gateway_rest_api.ApiGatewayApi.id
  parent_id   = aws_api_gateway_rest_api.ApiGatewayApi.root_resource_id
  path_part   = "delete"
}

resource "aws_api_gateway_method" "DeleteMethod" {
  rest_api_id   = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id   = aws_api_gateway_resource.Delete.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "DeleteIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id             = aws_api_gateway_resource.Delete.id
  http_method             = aws_api_gateway_method.DeleteMethod.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  timeout_milliseconds    = 29000

  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/xml" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}


resource "aws_api_gateway_resource" "Remove" {
  rest_api_id = aws_api_gateway_rest_api.ApiGatewayApi.id
  parent_id   = aws_api_gateway_rest_api.ApiGatewayApi.root_resource_id
  path_part   = "remove"
}

resource "aws_api_gateway_method" "RemoveMethod" {
  rest_api_id   = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id   = aws_api_gateway_resource.Remove.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "RemoveIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id             = aws_api_gateway_resource.Remove.id
  http_method             = aws_api_gateway_method.RemoveMethod.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  timeout_milliseconds    = 29000

  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/xml" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}
resource "aws_api_gateway_deployment" "APIDeployment" {
  rest_api_id = aws_api_gateway_rest_api.ApiGatewayApi.id
  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.Upload.id,
      aws_api_gateway_method.UploadMethod.id,
      aws_api_gateway_integration.UploadIntegration.id,
      aws_api_gateway_resource.Detect.id,
      aws_api_gateway_method.DetectMethod.id,
      aws_api_gateway_integration.DetectIntegration.id,
      aws_api_gateway_resource.Search.id,
      aws_api_gateway_method.SearchMethod.id,
      aws_api_gateway_integration.SearchIntegration.id,
      aws_api_gateway_resource.Delete.id,
      aws_api_gateway_method.DeleteMethod.id,
      aws_api_gateway_integration.DeleteIntegration.id,
      aws_api_gateway_resource.Remove.id,
      aws_api_gateway_method.RemoveMethod.id,
      aws_api_gateway_integration.RemoveIntegration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "APIStageName" {
  deployment_id = aws_api_gateway_deployment.APIDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.ApiGatewayApi.id
  stage_name    = "prod"
}

resource "aws_lambda_invocation" "LambdaTrigger" {
  function_name = aws_lambda_function.ObjectDetectionFunction.function_name

  triggers = {
    redeployment = sha1(jsonencode([
      aws_lambda_function.ObjectDetectionFunction.environment
    ]))
  }

  input = jsonencode({
    key1 = "value1"
    key2 = "value2"
  })
}


# example of handling sensetive data
# resource "aws_db_instance" "db_instance" {
#   allocated_storage   = 20
#   storage_type        = "standard"
#   engine              = "mysql"
#   engine_version      = "5.7"
#   instance_class      = "db.t2.micro"
#   name                = var.db_name
#   username            = var.db_user
#   password            = var.db_pass
#   skip_final_snapshot = true
# }
