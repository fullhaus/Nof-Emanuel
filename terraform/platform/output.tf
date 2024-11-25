output "jenkins_url" {
  value = module.jenkins.jenkins_url
  description = "URL to access Jenkins server"
}

output "jenkins_ssh_private_key" {
  value = nonsensitive(module.jenkins.jenkins_ssh_private_key)
  description = "Generated SSH private key"
}