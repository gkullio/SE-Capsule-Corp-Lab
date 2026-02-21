output "instance_ids" {
  description = "List of CE EC2 instance IDs"
  value       = [for key, inst in aws_instance.ce : inst.id]
}
