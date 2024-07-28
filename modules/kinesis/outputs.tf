output "kinesis_stream_names" {
  description = "Name of the created Kinesis streams"
  value       = aws_kinesis_stream.this.name
}
