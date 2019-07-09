# Apache Spark Azure Deployemnt

Automate the deploy process for Standalone Apache Spark cluster on Azure with 1 master node and 2 slave nodes using terraform and ansible.


Apache Spark: https://spark.apache.org

Documentation for installing: https://spark.apache.org/docs/2.4.0/#launching-on-a-cluster

Note that this is intended to be a demonstration and it **does not** set up a production-quality, well-tuned and highly available environment. It is intended to be a demonstration and provide a quick-start
for anyone who wants to try the functionality of such a setup.

# Requirements
1. ansible and terraform have to be installed on the machine to run this code.
2. subcription details for Azure, this can be setup using the azure cli, when login to a device is done through the shell, only the subscription_id and client_id will be required to run the terraform scripts.
```
    subscription_id = "xxxxxxxx"
    client_id       = "xxxxxxxx"
```
3. ssh_keys - generate ssh keys for logging to the servers once they have been created
4. variables.tf - variables defined in this file are for testing purposes only and these can be changed.
5. ansible variables defined in `group_vars/all.yml` this include scala version, spark version to be installed and static ip being used for the master

# Tools
## 1. Terraform
Best practice are followed by separating the resources into different terraform files
1. main.tf - VMs to be deployed
2. variables.tf - variables used in creating the enviroment
3. security.tf - security rules being applied
4. storage.tf - storaged being used
5. network.tf - network components
6. output.tf - example output

This can be run separately. The provisioner component  in `main.tf` which executes the ansible scripts can be removed.

## 2. Ansible
After running the terraform, ansible scripts for installing the apache spark cluster(master and slaves) will be run on each server, a `hosts.ini` file is generated showing the ips for the master and slaves. The deploy.yml defines the roles in `roles` to be installed on either master or slave.

This can be run separately as below:
```
		ansible-playbook -i hosts.ini deploy.yml --private-key=ssh_keys/id_rsa --user sparkuser
```

# Apache Ambari

Apache ambari can be used to setup the cluster as well, This will be installed using ansible, the code base is in `ansible-ambari`
provisioner component in `main.tf` can be changed to point to the ambari ansible scripts. A `hosts.ini` file is generated showing the ips for the ambari master and agents. The apache spark cluster will then be setup using ambari.

This can be run separately as below:
```
		ansible-playbook -i hosts.ini site.yml --private-key=ssh_keys/id_rsa --user sparkuser
```


# Run the terraform

```
    terraform validate
    terraform init -input=false 
    terraform plan -out=tfplanefs 
    terraform apply -input=false tfplanefs 
```

# Missing tests
This is missing tests not built into the ansible code and terraform code
