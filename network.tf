#vnet 
resource "azurerm_virtual_network" "spark" {
  name                = "vnet-spark"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  address_space       = ["${var.vnet_spark_prefix}"]
}

#subnets
resource "azurerm_subnet" "master" {
  name                      = "${var.vnet_spark_subnet1_name}"
  virtual_network_name      = "${azurerm_virtual_network.spark.name}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  address_prefix            = "${var.vnet_spark_subnet1_prefix}"
  network_security_group_id = "${azurerm_network_security_group.master.id}"
  depends_on                = ["azurerm_virtual_network.spark"]
}

resource "azurerm_subnet" "slave" {
  name                 = "${var.vnet_spark_subnet2_name}"
  virtual_network_name = "${azurerm_virtual_network.spark.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${var.vnet_spark_subnet2_prefix}"
}

#public ips
resource "azurerm_public_ip" "master" {
  name                         = "${var.public_ip_master_name}"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  allocation_method = "Static"
}

resource "azurerm_public_ip" "slave" {
  name                         = "${var.public_ip_slave_name_prefix}${count.index}"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  allocation_method = "Static"
  count                        = "${var.vm_number_of_slaves}"
}

#network interface
resource "azurerm_network_interface" "master" {
  name                      = "${var.nic_master_name}"
  location                  = "${azurerm_resource_group.rg.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.master.id}"
  depends_on                = ["azurerm_virtual_network.spark", "azurerm_public_ip.master", "azurerm_network_security_group.master"]

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet1.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.nic_master_node_ip}"
    public_ip_address_id          = "${azurerm_public_ip.master.id}"
  }
}

resource "azurerm_network_interface" "slave" {
  name                      = "${var.nic_slave_name_prefix}${count.index}"
  location                  = "${azurerm_resource_group.rg.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.slave.id}"
  count                     = "${var.vm_number_of_slaves}"
  depends_on                = ["azurerm_virtual_network.spark", "azurerm_public_ip.slave", "azurerm_network_security_group.slave"]

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet2.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.nic_slave_node_ip_prefix}${5 + count.index}"
    public_ip_address_id          = "${element(azurerm_public_ip.slave.*.id, count.index)}"
  }
}

#availability set
resource "azurerm_availability_set" "slave" {
  name                         = "${var.availability_slave_name}"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  platform_update_domain_count = 5
  platform_fault_domain_count  = 2
}
