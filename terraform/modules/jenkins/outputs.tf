output "jenkins_url" {
  value = "http://${azurerm_public_ip.jenkins_public_ip.ip_address}:8080"
  description = "URL to access Jenkins server"
}

output "jenkins_ssh_private_key" {
  value       = nonsensitive(tls_private_key.ssh_key.private_key_pem)
  description = "Generated SSH private key"
}

output "jenkins_ssh_public_key" {
  value       = tls_private_key.ssh_key.public_key_openssh
  description = "Generated SSH public key"
}