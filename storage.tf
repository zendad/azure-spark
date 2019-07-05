resource "azurerm_storage_account" "master" {
  name                     = "master${var.project}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${var.storage_master_account_tier}"
  account_replication_type = "${var.storage_master_replication_type}"

  tags = {
    environment = "${var.environment}"
    purpose = "master${var.project}"
    technical_owner = "${var.tech_owner}"
    name = "master${var.project}"
  }
}

resource "azurerm_storage_container" "master" {
  name                  = "${var.vm_master_storage_account_container_name}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.master.name}"
  container_access_type = "private"
  depends_on            = ["azurerm_storage_account.master"]
}

resource "azurerm_storage_account" "slave" {
  name                     = "slave${var.project}${count.index}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  count                    = "${var.vm_number_of_slaves}"
  account_tier             = "${var.storage_slave_account_tier}"
  account_replication_type = "${var.storage_slave_replication_type}"

  tags = {
    environment = "${var.environment}"
    purpose = "slave${var.project}${count.index}"
    technical_owner = "${var.tech_owner}"
    name = "slave${var.project}${count.index}"
  }
}

resource "azurerm_storage_container" "slave" {
  name                  = "${var.vm_slave_storage_account_container_name}${count.index}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${element(azurerm_storage_account.slave.*.name, count.index)}"
  container_access_type = "private"
  depends_on            = ["azurerm_storage_account.slave"]
}
