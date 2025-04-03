output "master_ip" {
  value = aws_instance.master.public_ip
}

output "web_ip" {
  value = aws_instance.web.public_ip
}

output "k3s_token" {
  value = "cat /var/lib/rancher/k3s/server/node-token"
  description = "Token pentru join in cluster"
}
