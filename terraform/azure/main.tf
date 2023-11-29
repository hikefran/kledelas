resource "azurerm_resource_group" "web" {
  name     = "VAIPALEMEIRAS"
  location = "East US"
}

# Create a virtual network
resource "azurerm_virtual_network" "web" {
  name                = "virtual-network-name"
  address_space       = ["172.0.0.0/16"]
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
}

# Create a subnet
resource "azurerm_subnet" "web" {
  name                 = "main-subnet"
  resource_group_name  = azurerm_resource_group.web.name
  virtual_network_name = azurerm_virtual_network.web.name
  address_prefixes     = ["172.0.2.0/24"]
}

# Create a Network Security Group and rule
resource "azurerm_network_security_group" "web" {
  name                = "network-security-group-name"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG to subnet
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# Public IP address for the Load Balancer
resource "azurerm_public_ip" "web" {
  name                = "public-ip"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "web_vm" {
  name                = "public-ip-vm"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Dynamic"
  domain_name_label = "staticsite-vm"
}

# Load Balancer
resource "azurerm_lb" "web" {
  name                = "load-balancer"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  frontend_ip_configuration {
    name                 = "public-ip"
    public_ip_address_id = azurerm_public_ip.web.id
  }
}

# Load Balancer Backend Address Pool
resource "azurerm_lb_backend_address_pool" "web" {
  loadbalancer_id = azurerm_lb.web.id
  name            = "backend-pool"
}

# Load Balancer Rule for HTTP Traffic.
resource "azurerm_lb_rule" "web" {
  name                           = "HTTP"
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public-ip"
  probe_id                       = azurerm_lb_probe.web.id
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.web.id,
  ]
}

# Load Balancer Health Probe for HTTP Traffic

data "template_file" "cloud_init" {
  template = file("./init/cloud_init.sh")
}
resource "azurerm_lb_probe" "web" {
  name                = "health-probe"
  loadbalancer_id     = azurerm_lb.web.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Azure Virtual Machine - Instance 1
resource "azurerm_virtual_machine" "web_instance_1" {
  name                = "web-instance-root-1"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  vm_size             = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.web_nic_1.id]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "staticsite-vm-disk-1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "staticsite-vm-1"
    admin_username = "vmuser"
    admin_password = "Password1234!"
    custom_data    = base64encode(data.template_file.cloud_init.rendered)
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  // public ip
}

# Create network interface for the VMs
resource "azurerm_public_ip" "nic_1" {
  name                = "public-ip-address-name1"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "web_nic_1" {
  name                = "web-nic-1"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  ip_configuration {
    name                          = "ip-configuration1"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.nic_1.id
  }
}

# Network Interface Back-end Address Pool Association
resource "azurerm_network_interface_backend_address_pool_association" "web_nic1_association" {
  network_interface_id    = azurerm_network_interface.web_nic_1.id
  ip_configuration_name   = "ip-configuration1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}

# Output the IP address of the Load Balancer
output "lb_ip_address" {
  value = azurerm_public_ip.web.ip_address
}


//create second vm
resource "azurerm_public_ip" "nic_2" {
  name                = "public-ip-address-name2"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "web_nic_2" {
  name                = "web-nic-2"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name

  ip_configuration {
    name                          = "ip-configuration2"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.nic_2.id
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "web_nic2_association" {
  network_interface_id    = azurerm_network_interface.web_nic_2.id
  ip_configuration_name   = "ip-configuration2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}