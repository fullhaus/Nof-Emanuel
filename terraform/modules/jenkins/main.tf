# Create public IPs
resource "azurerm_public_ip" "jenkins_public_ip" {
  name                = "${var.project}-${var.environment}-jenkins-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  #
  tags = {
    Environment = var.environment
    Product     = var.project
  }
}

# Define a network security group
resource "azurerm_network_security_group" "jenkis_nsg" {
  name                = "${var.project}-${var.environment}-jenkins-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowJenkins"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "jenkins_nic" {
  name                = "${var.project}-${var.environment}-jenkins-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${var.project}_${var.environment}_jenkins_nic_configuration"
    subnet_id                     = var.vnet_jenkins_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "jenkins" {
  network_interface_id      = azurerm_network_interface.jenkins_nic.id
  network_security_group_id = azurerm_network_security_group.jenkis_nsg.id
}

# Data sources for current Azure details
data "azurerm_client_config" "current" {}

# Create a Key Vault to store SSH keys
resource "azurerm_key_vault" "key_vault" {
  name                        = "${var.environment}-jen-vault"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "Set", "Delete", "List"]
  }
}

locals {
  custom_data = <<CUSTOM_DATA
#!/bin/bash
# Update and install required packages
sudo apt-get update -y
sudo apt-get install -y docker.io git openjdk-17-jdk

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to Docker group
sudo usermod -aG docker ${var.admin_username}

# Add Jenkins repository and install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y && sudo apt-get install jenkins -y

# Run services
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Add jenkins user to Docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Add kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

CUSTOM_DATA
}

# Define a virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.project}-${var.environment}-jenkins"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_DS4_v2" #"Standard_DS1_v2"
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.jenkins_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
    #offer     = "UbuntuServer"
    #sku       = "18_04-lts-gen2"
    #version   = "18.04.202401161"
  }

  # Cloud-init script for Jenkins, Docker, and Git
  custom_data = base64encode(local.custom_data)

  tags = {
    environment = var.environment
  }

  lifecycle {
    ignore_changes = [
      custom_data
    ]
  }
}