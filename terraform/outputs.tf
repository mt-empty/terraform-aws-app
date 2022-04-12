# defines what values I want to use/store

output "instance_ip_addr" {
  value = join(",", aws_instance.server[*].private_ip)
}

output "api_endpoint" {
  description = "Ever green endpoint to the elastic beanstalk environment"
  value       = aws_apigatewayv2_api.ApiGatewayApi.api_endpoint
}
# output "db_instance_addr" {
#     value = aws_db_instance.db_instance.address
# }
