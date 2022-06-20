# defines what values I want to use/store

output "api_endpoint" {
  description = "Object detection endpoint of the API"
  value       = aws_apigatewayv2_api.ApiGatewayApi.api_endpoint
}
# output "db_instance_addr" {
#     value = aws_db_instance.db_instance.address
# }

output "web_endpoint" {
  description = "Web endpoint of s3 bucket"
  value       = aws_s3_bucket.ReactAppBucket.website_endpoint
}
