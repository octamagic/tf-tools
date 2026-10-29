output "name" {
  description = "Name of the table."
  value       = aws_dynamodb_table.this.name
}

output "arn" {
  description = "ARN of the table. Grant application roles access to this and, for index queries, to \"<arn>/index/*\"."
  value       = aws_dynamodb_table.this.arn
}

output "id" {
  description = "ID (name) of the table."
  value       = aws_dynamodb_table.this.id
}

output "stream_arn" {
  description = "ARN of the table stream, or null when streams are disabled."
  value       = aws_dynamodb_table.this.stream_arn
}
