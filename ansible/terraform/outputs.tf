output "server1_public_ip" {
  value       = aws_instance.servers[0].public_ip
  description = "Public IP of the first server"
}

output "server2_public_ip" {
  value       = aws_instance.servers[1].public_ip
  description = "Public IP of the second server"
}
