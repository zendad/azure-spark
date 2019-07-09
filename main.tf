resource "azurerm_resource_group" "rg" {
  name     = "${var.project}"
  location = "${var.location}"

  tags = {
    environment = "${var.environment}"
    purpose = "${var.project}"
    technical_owner = "${var.tech_owner}"
    name = "${var.project}"
  }
}

#spark master
resource "azurerm_virtual_machine" "master" {
  name                  = "${var.vm_master_name}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  location              = "${azurerm_resource_group.rg.location}"
  vm_size               = "${var.vm_master_vm_size}"
  network_interface_ids = ["${azurerm_network_interface.master.id}"]
  depends_on            = ["azurerm_storage_account.master", "azurerm_network_interface.master", "azurerm_storage_container.master"]

  storage_image_reference {
    publisher = "${var.os_image_publisher}"
    offer     = "${var.os_image_offer}"
    sku       = "${var.os_version}"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.vm_master_os_disk_name}"
    vhd_uri       = "http://${azurerm_storage_account.master.name}.blob.core.windows.net/${azurerm_storage_container.master.name}/${var.vm_master_os_disk_name}.vhd"
    create_option = "FromImage"
    caching       = "ReadWrite"
  }

  os_profile {
    computer_name  = "${var.vm_master_name}"
    admin_username = "${var.vm_admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.vm_admin_username}/.ssh/authorized_keys"
      key_data = "${file("ssh_keys/id_rsa.pub")}"
    }
  }

  connection {
    type     = "ssh"
    host     = "${azurerm_public_ip.master.ip_address}"
    user     = "${var.vm_admin_username}"
    private_key = "${file("ssh_keys/id_rsa")}"
  }

  provisioner "local-exec" {
    command ="export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook  -i hosts.ini deploy.yml --private-key=ssh_keys/id_rsa.pub --user ${var.vm_admin_username}"
  }
}

#spark slaves
resource "azurerm_virtual_machine" "slave" {
  name                  = "${var.vm_slave_name_prefix}${count.index}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  location              = "${azurerm_resource_group.rg.location}"
  vm_size               = "${var.vm_slave_vm_size}"
  network_interface_ids = ["${element(azurerm_network_interface.slave.*.id, count.index)}"]
  count                 = "${var.vm_number_of_slaves}"
  availability_set_id   = "${azurerm_availability_set.slave.id}"
  depends_on            = ["azurerm_storage_account.slave", "azurerm_network_interface.slave", "azurerm_storage_container.slave"]

  storage_image_reference {
    publisher = "${var.os_image_publisher}"
    offer     = "${var.os_image_offer}"
    sku       = "${var.os_version}"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.vm_slave_os_disk_name_prefix}${count.index}"
    vhd_uri       = "http://${element(azurerm_storage_account.slave.*.name, count.index)}.blob.core.windows.net/${element(azurerm_storage_container.slave.*.name, count.index)}/${var.vm_slave_os_disk_name_prefix}.vhd"
    create_option = "FromImage"
    caching       = "ReadWrite"
  }

  os_profile {
    computer_name  = "${count.index}"
    admin_username = "${var.vm_admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.vm_admin_username}/.ssh/authorized_keys"
      key_data = "${file("ssh_keys/id_rsa.pub")}"
    }
  }

  connection {
    type     = "ssh"
    host     = "${element(azurerm_public_ip.slave.*.ip_address, count.index)}"
    user     = "${var.vm_admin_username}"
    private_key = "${file("ssh_keys/id_rsa")}"
  }

  tags = {
    environment = "${var.environment}"
    purpose = "${var.vm_master_name}"
    technical_owner = "${var.tech_owner}"
    name = "${var.vm_master_name}"
  }

  provisioner "local-exec" {
    command ="export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i hosts.ini deploy.yml --private-key=ssh_keys/id_rsa --user ${var.vm_admin_username}"
  }
}
