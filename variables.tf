provider "azurerm" {
    subscription_id = "bfc354ee-7eef-4a2c-9455-958c92cbef48"
    client_id       = "4b79b699-6a0c-476a-8f2d-7f9e9488abdb"
}

variable "project" {
  description = "This prefix is used to identify and tag resources linked to this project"
  default = "sparkdemo"
}

variable "environment" {
  description = " identify the enviroment which resources are created for"
  default = "demo"
}

variable "location" {
  description = "The location/region where project and resources are to be created. Changing this forces a new resource to be created."
  default     = "southcentralus"
}

variable "storage_master_account_tier" {
  description = "Storage Tier that is used for master Spark node. This storage account is used to store VM disks. Allowed values are Standard and Premium."
  default     = "Standard"
}

variable "storage_master_replication_type" {
  description = "Storage Tier that is used for master Spark node. This storage account is used to store VM disks. Possible values include LRS and GRS."
  default     = "LRS"
}

variable "storage_slave_account_tier" {
  description = "Storage type that is used for each of the slave Spark node. This storage account is used to store VM disks. Allowed values are Standard and Premium."
  default     = "Standard"
}

variable "storage_slave_replication_type" {
  description = "Storage type that is used for each of the slave Spark node. This storage account is used to store VM disks. Possible values include LRS and GRS."
  default     = "LRS"
}

variable "vm_master_vm_size" {
  description = "VM size for master Spark node.  This VM can be sized smaller. Allowed values: Standard_D1_v2, Standard_D2_v2, Standard_D3_v2, Standard_D4_v2, Standard_D5_v2, Standard_D11_v2, Standard_D12_v2, Standard_D13_v2, Standard_D14_v2, Standard_A8, Standard_A9, Standard_A10, Standard_A11"
  default     = "Standard_D1_v2"
}

variable "vm_number_of_slaves" {
  description = "Number of VMs to create to support the slaves.  Each slave is created on it's own VM.  Minimum of 2 & Maximum of 20 VMs. min = 2, max = 20"
  default     = 2
}

variable "vm_slave_vm_size" {
  description = "VM size for slave Spark nodes.  This VM should be sized based on workloads. Allowed values: Standard_D1_v2, Standard_D2_v2, Standard_D3_v2, Standard_D4_v2, Standard_D5_v2, Standard_D11_v2, Standard_D12_v2, Standard_D13_v2, Standard_D14_v2, Standard_A8, Standard_A9, Standard_A10, Standard_A11"
  default     = "Standard_D3_v2"
}

variable "vm_admin_username" {
  description = "Specify an admin username that should be used to login to the VM. Min length: 1"
  default = "sparkuser"
}

variable "os_image_publisher" {
  description = "name of the publisher of the image (az vm image list)"
  default     = "Canonical"
}

variable "os_image_offer" {
  description = "the name of the offer (az vm image list)"
  default     = "UbuntuServer"
}

variable "os_version" {
  description = "version of the image to apply (az vm image list)"
  default     = "16.04-LTS"
}

variable "vnet_spark_prefix" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "vnet_spark_master_subnet_name" {
  description = "The name used for the Master subnet."
  default     = "sparkmaster"
}

variable "vnet_spark_master_subnet_prefix" {
  description = "The address prefix to use for the Master subnet."
  default     = "10.0.0.0/24"
}

variable "vnet_spark_slave_subnet_name" {
  description = "The name used for the slave/agent subnet."
  default     = "sparkslaves"
}

variable "vnet_spark_slave_subnet_prefix" {
  description = "The address prefix to use for the slave/agent subnet."
  default     = "10.0.1.0/24"
}

variable "nsg_spark_master_name" {
  description = "The name of the network security group for Spark's Master"
  default     = "nsg-spark-master"
}

variable "nsg_spark_slave_name" {
  description = "The name of the network security group for Spark's slave/agent nodes"
  default     = "nsg-spark-slave"
}

variable "nic_master_name" {
  description = "The name of the network interface card for Master"
  default     = "nic-master"
}

variable "nic_master_node_ip" {
  description = "The private IP address used by the Master's network interface card"
  default     = "10.0.0.5"
}

variable "nic_slave_name_prefix" {
  description = "The prefix used to constitute the slave/agents' names"
  default     = "nic-slave-"
}

variable "nic_slave_node_ip_prefix" {
  description = "The prefix of the private IP address used by the network interface card of the slave/agent nodes"
  default     = "10.0.1."
}

variable "public_ip_master_name" {
  description = "The name of the master node's public IP address"
  default     = "public-ip-master"
}

variable "public_ip_slave_name_prefix" {
  description = "The prefix to the slave/agent nodes' IP address names"
  default     = "public-ip-slave-"
}

variable "vm_master_name" {
  description = "The name of Spark's Master virtual machine"
  default     = "spark-master"
}

variable "vm_master_os_disk_name" {
  description = "The name of the os disk used by Spark's Master virtual machine"
  default     = "vmMasterOSDisk"
}

variable "vm_master_storage_account_container_name" {
  description = "The name of the storage account container used by Spark's master"
  default     = "vhds"
}

variable "vm_slave_name_prefix" {
  description = "The name prefix used by Spark's slave/agent nodes"
  default     = "spark-slave-"
}

variable "vm_slave_os_disk_name_prefix" {
  description = "The prefix used to constitute the names of the os disks used by the slave/agent nodes"
  default     = "vmSlaveOSDisk-"
}

variable "vm_slave_storage_account_container_name" {
  description = "The name of the storage account container used by the slave/agent nodes"
  default     = "vhds"
}

variable "availability_slave_name" {
  description = "The name of the availability set for the slave/agent machines"
  default     = "availability-slave"
}

