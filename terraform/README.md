<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 4.6.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.6.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_apigatewayv2_api.ApiGatewayApi](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_deployment.APIDeployment](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_deployment) | resource |
| [aws_apigatewayv2_integration.DeleteIntegration](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.DetectIntegration](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.HealthIntegration](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.RemoveIntegration](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.SearchIntegration](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration.UploadIntegration](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.Delete](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.Detect](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.Health](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.Remove](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.Search](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route.Upload](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.APIStageName](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/apigatewayv2_stage) | resource |
| [aws_dynamodb_table.imageDB](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/dynamodb_table) | resource |
| [aws_ecr_repository.docker_image](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/ecr_repository) | resource |
| [aws_iam_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/iam_policy) | resource |
| [aws_iam_role.iam_for_lambda](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/iam_role_policy) | resource |
| [aws_instance.server](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/instance) | resource |
| [aws_lambda_function.ObjectDetectionFunction](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/lambda_function) | resource |
| [aws_lambda_invocation.LambdaTrigger](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/lambda_invocation) | resource |
| [aws_lambda_permission.apigw_lambda](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.S3Bucket](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/s3_bucket) | resource |
| [aws_security_group.instances](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/security_group) | resource |
| [aws_security_group_rule.allow_http_inbound](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/resources/security_group_rule) | resource |
| [null_resource.ecr_image](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current_identity](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/data-sources/caller_identity) | data source |
| [aws_ecr_image.lambda_image](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/data-sources/ecr_image) | data source |
| [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/4.6.0/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami"></a> [ami](#input\_ami) | Amazon machine image for ec2 instance | `string` | `"ami-00abf0511a7f4cee5"` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | s3 bucket name | `string` | `"object-detection-images-prod"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | name for database | `string` | `"server_db"` | no |
| <a name="input_db_pass"></a> [db\_pass](#input\_db\_pass) | password for database | `string` | n/a | yes |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | username for database | `string` | n/a | yes |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | object detection | `string` | `"object_detection"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | ec2 instance type | `string` | `"t2.micro"` | no |
| <a name="input_region"></a> [region](#input\_region) | Amazon region | `string` | `"ap-southeast-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | Ever green endpoint to the elastic beanstalk environment |
| <a name="output_instance_ip_addr"></a> [instance\_ip\_addr](#output\_instance\_ip\_addr) | n/a |
<!-- END_TF_DOCS -->