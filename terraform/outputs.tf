output "web_server_elastic_ip_node1" {
  value = aws_eip.node1.public_ip
}

output "node1_private_ip_webserver" {
  value = module.node1.private_ip
}

output "node2_private_ip_ansible" {
  value = module.node2.private_ip
}

output "node3_private_ip_monitoring" {
  value = module.node3.private_ip
}

output "ssm_command_node1_webserver" {
  value = "aws ssm start-session --target ${module.node1.id}"
}

output "ssm_command_node2_ansible" {
  value = "aws ssm start-session --target ${module.node2.id}"
}

output "ssm_command_node3_monitoring" {
  value = "aws ssm start-session --target ${module.node3.id}"
}

output "ecr_repository_url" {
  description = "ECR repository URL for the application"
  value       = aws_ecr_repository.app.repository_url
}