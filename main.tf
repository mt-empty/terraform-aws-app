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
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

# locals cannot be changed at runtime
locals {
  example = "example"
}

locals {
  # resource = method
  paths = {
    "upload" = "PUT"
    "detect" = "POST"
    "remove" = "POST"
    "delete" = "POST"
    "search" = "POST"
    }
}


# resources can be physical, virtual or logical(ecs) such as heroku application
# 2 strings : resource type and resource name, these define the id of the resource
resource "aws_instance" "server" {
  count = 2
  ami             = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instances.name]
  tags = {
    Name = "Server ${count.index}"
  }
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World ${count.index}" > index.html
              python3 -m http.server 8080 &
              EOF
}

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

resource "aws_s3_bucket" "S3Bucket" {
  bucket = "fit5225-ass2-images-prod"
}

# resource "aws_s3_bucket_acl" "S3Bucket_acl" {
#   bucket = aws_s3_bucket.S3Bucket.id
#   acl    = "private"
# }

resource "aws_dynamodb_table" "imageDB" {
  name             = "images"
  hash_key         = "id"
  billing_mode = "PROVISIONED"
  read_capacity    = 10
  write_capacity   = 10
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "tagDB" {
  name             = "tags"
  hash_key         = "id"
  billing_mode = "PROVISIONED"
  read_capacity    = 10
  write_capacity   = 10
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

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "ObjectDetectionFunction" {
  function_name = "object_etection"
  role = aws_iam_role.iam_for_lambda.arn
  filename = "index.zip"
  handler = "index.html"
  runtime = "nodejs12.x"
}


resource "aws_api_gateway_rest_api" "ApiGatewayApi" {
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
  rest_api_id          = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id          = aws_api_gateway_resource.Upload.id
  http_method          = aws_api_gateway_method.UploadMethod.http_method
  type                 = "AWS_PROXY"
  integration_http_method = "POST"
  uri                  = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  timeout_milliseconds = 29000

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
  rest_api_id          = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id          = aws_api_gateway_resource.Detect.id
  http_method          = aws_api_gateway_method.DetectMethod.http_method
  type                 = "AWS_PROXY"
  integration_http_method = "POST"
  uri                  = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  timeout_milliseconds = 29000

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
  rest_api_id          = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id          = aws_api_gateway_resource.Search.id
  http_method          = aws_api_gateway_method.SearchMethod.http_method
  type                 = "AWS_PROXY"
  integration_http_method = "POST"
  uri                  = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  timeout_milliseconds = 29000

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
  rest_api_id          = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id          = aws_api_gateway_resource.Delete.id
  http_method          = aws_api_gateway_method.DeleteMethod.http_method
  type                 = "AWS_PROXY"
  integration_http_method = "POST"
  uri                  = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  timeout_milliseconds = 29000

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
  rest_api_id          = aws_api_gateway_rest_api.ApiGatewayApi.id
  resource_id          = aws_api_gateway_resource.Remove.id
  http_method          = aws_api_gateway_method.RemoveMethod.http_method
  type                 = "AWS_PROXY"
  integration_http_method = "POST"
  uri                  = aws_lambda_function.ObjectDetectionFunction.invoke_arn
  timeout_milliseconds = 29000

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



# example of handling sensetive data
resource "aws_db_instance" "db_instance" {
  allocated_storage   = 20
  storage_type        = "standard"
  engine              = "postgres"
  engine_version      = "12.5"
  instance_class      = "db.t2.micro"
  name                = var.db_name
  username            = var.db_user
  password            = var.db_pass
  skip_final_snapshot = true
}
