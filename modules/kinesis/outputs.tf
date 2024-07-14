output "kinesis_stream_names" {
  description = "Names of the created Kinesis streams"
  value       = [for k, v in aws_kinesis_stream.kinesis_streams : v.name]
}
