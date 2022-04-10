# defines what values I want to use/store

output "instance_ip_addr" {
  value = join(",", aws_instance.server[*].private_ip)
}

output "api_endpoint" {
  value = "https://${aws_api_gateway_rest_api.ApiGatewayApi.name}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.APIStageName.stage_name}/"
}
# output "db_instance_addr" {
#     value = aws_db_instance.db_instance.address
# }
