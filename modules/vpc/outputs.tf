output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "List of public subnet IDs (empty for now)"
  value       = []
}

output "private_subnets" {
  description = "List of private subnet IDs (empty for now)"
  value       = []
}
