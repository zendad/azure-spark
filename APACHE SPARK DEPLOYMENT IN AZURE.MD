# Deploying Apache Spark on Azure
 
This document details how to setup and manage a High Available, production ready Apache Spark cluster on Azure. This explores strategies that can be followed without much techinical details, its more of a guidance. It will show deployment tools to be used, monitoring tools and alerts. 

Apache spark on azure can be deployed:
1. Directly on VMs
2. Using Azure HDInsight
3. On Azure Kubernetes Service

# Apache Spark High Availability

Having a single standalone master creates a single point of failure,since the Master is a single point of failure, Spark offers the ability to start another instance of a master which will be in standby until the active master disappears. When the standby master becomes the active master, the workers will reconnect to this master and existing applicatione will continue running without problem.This functionality relies on ZooKeeper to perform master election.

Zookeeper provides a mechanism for leader election where you can configure multiple masters in the cluster for HA purposes which will be connected to the same Zookeeper instance. One master instance will take the role of a master and others would be in the standby mode. If the current master dies, Zookeeper will elect another standby instance as a Master, recover the older Master's state and then resume the scheduling.Since the information has been persisted on the filesystem, including Worker, Driver and Application information, this only impacts the scheduling of the new jobs without impacting any current running jobs.

Components of a Highly available Apache Spark:
    1. Zookeeper
    2. Masters
    3. Slaves or worker nodes
    
# Running Apache spark on Azure VMs
## Zookeeper Cluster 
Zookeeper will be deployed in a cluster of nodes in an auto scaling set, with an ELB in front of the scale set. Nodes is a zookeeper cluster need to form a quorum.Quorum refers to the minimum number of nodes that need to agree on a transaction before it's committed. A quorum needs an odd number of nodes so that it can establish a majority. An even number of nodes may result in a tie, which would mean the nodes would not reach a majority or consensus. In a ZooKeeper cluster, if a leader dies the other remaining nodes will elect a leader among themselves.This will usually be very quick and there should be no visible outage to the clients. In a production environment, each ZooKeeper node should be run on a separate host. This prevents service disruption due to host hardware failure or reboots. This is an important and necessary architectural consideration for building a resilient and highly available distributed system. The clients that were connected to the leader that died will reconnect to one of the other nodes. A new node should be able to auto discover the other nodes already in the cluster, the same with existing nodes, existing nodes would periodically check if a new node has been added/removed updated the startup script and restart zookeeper. This would be configured using cloud init and scriptng. The will follow a rolling update process. Each node knows the state of the cluster.[installing zookeeper](https://zookeeper.apache.org/doc/r3.1.2/zookeeperStarted.html) - this process will be automated through ansible for application and terraform for the infrastructure

example of zoo.cfg configuration file to use:

```
        tickTime=2000
        dataDir=/data/zookeeper
        clientPort=2181
        maxClientCnxns=60
        initLimit=10
        syncLimit=5
        server.1=your_zookeeper_node_1:2888:3888
        server.2=your_zookeeper_node_2:2888:3888
        server.3=your_zookeeper_node_3:2888:3888
```

On each node create a unique zookeeper id and store it in the “myid” file that should be located under the directory that is specified by the “dataDir” in zoo.cfg.

`initLimit` specifies the time that the initial synchronization phase can take. This is the time within which each of the nodes in the quorum needs to connect to the leader. `syncLimit` specifies the time that can pass between sending a request and receiving an acknowledgment. This is the maximum time nodes can be out of sync from the leader. ZooKeeper nodes use a pair of ports, `:2888 and :3888`, for follower nodes to connect to the leader node and for leader election, respectively.

## Apache Spark Master
Master nodes  will be deployed independently, each with a static ip,Each master need to be connected to the same ZooKeeper url/ip/ELB.
In order to enable HA and recovery mode, create an `ha.conf`  using the following configuration:
```
            spark.deploy.recoveryMode Set to ZOOKEEPER to enable standby Master recovery mode (default: NONE)

            spark.deploy.zookeeper.url The ZooKeeper cluster url (e.g., n1a:5181,n2a:5181,n3a:5181).

            spark.deploy.zookeeper.dir The directory in ZooKeeper to store recovery state (default: /spark). This can be optional
```
Start multiple Master processes on different nodes with the same ZooKeeper configuration (ZooKeeper URL and directory).
example:
```
       start-master.sh -h localhost -p 7077 --webui-port 8080 --properties-file ha.conf
```
This process will be automated through ansible for application and terraform for the infrastructure

## Apache Spark Slaves
Spark slaves will be deployed in auto scaling sets, using a init config,intial set of 2 will be used, scaling based on cpu usage,memory. When starting the worker, you have to provide the reference to all the masters:
 example: 
 ```
    start-slave.sh spark://master1:7077,master2:7077,,master3:7077
 ```
 
 The same principle applies when submitting applications:
```
   spark-submit --master spark://master1:7077,master2:7077 
```
This process will be automated through ansible for application and terraform for the infrastructure

## Deployment Process
Terraform will used to deploy the infrastructure and ansible for the application and configuration management. A custom image will be deployed with packer, it will contain spark and other customised scripts to manage the state of the VM, a timer will used to check git for any changes to the scripts.
1. customised script to manage zookeeper - at start up zookeeper cluster needs to know the number other machines in the cluster, this script coupled with ansible state configurations will maintain the zookeeper cluster 
2. customised script to maintain the number of master nodes and run a azure template to create a new master if any of the existing ones are destroyed. This will be deployed thought terraform and ansible.
3. Another way to setup the apache sprk cluster is to use [Apache Ambari](https://ambari.apache.org/), terraform will used to setup the infrastructure, installation will follow procedures as defined on [[Apache Ambari] website](https://cwiki.apache.org/confluence/display/AMBARI/Installation+Guide+for+Ambari+2.7.3)

# Running Apache Cluster Spark on Azure HDInsight
 Apache Spark in Azure HDInsight is the Microsoft implementation of Apache Spark in the cloud. HDInsight makes it easier to create and configure a Spark cluster in Azure. Spark clusters in HDInsight are compatible with Azure Storage and Azure Data Lake Storage

As a managed service there re many are advantages of deploying apache spark this way:
1. Scalability - Azure allows you to make changes to the cluster without loss to data
2. SLA - comes with microsoft support
3. comes with other preloaded features

source: [Azure HDInsight site](https://docs.microsoft.com/en-us/azure/hdinsight/spark/apache-spark-overview)

## Deployment Process
[basic example on Azure](https://docs.microsoft.com/en-us/azure/hdinsight/spark/apache-spark-jupyter-spark-sql-use-portal)
This can easily be deployed using the terraform azurerm_hdinsight_cluster module or templates that would specify the size instances and storage to be used in the cluster.

# Running Apache Spark Cluster on Azure Kubernetes Service
Spark can run on clusters managed by Kubernetes. This feature makes use of native Kubernetes scheduler that has been added to Spark. The kubernetes nodes should be a minimum of size of Standard_D3_v2 in Azure. Procedures for doing this can be found on the [Apache Spark Website](https://spark.apache.org/docs/latest/running-on-kubernetes.html)

## Deployment Process
The kubernetes will be deployed with terraform as defined [here](https://docs.microsoft.com/en-us/azure/terraform/terraform-create-k8s-cluster-with-tf-and-aks) and [can follow this examples for deploying AKS](https://github.com/terraform-providers/terraform-provider-azurerm/tree/master/examples/kubernetes). The apache spark cluster itself will be deployed using helm charts run through ansible.

# Apache Spark Monitoring
1. [Datadog](https://docs.datadoghq.com/integrations/spark/) & [Opsgenie](https://www.atlassian.com/software/opsgenie/datadog) - datadog is managed on cloud monitoring tool that provides an agent and configurations which has to be installed on the cluster that can properly monitor an apache spark cluster including jobs and processes. It can generate alerts which can be integrated with opsgenie for alerting, on call rotation management and escalations 
2. [Prometheus][https://prometheus.io/]  - a prometheus monitoring cluster can be used to monitor the apache spark cluster. This can be inside the kubernetes cluster or on separate VMs when the cluster in deployed through hdinsight or on VMs. Prometheus provides metrics and alerts for the cluster, graphs can be built using grafana showing perfomance on different areas of the cluster.
3. [Apache Ambari](https://ambari.apache.org/) - The Apache Ambari project is aimed at making Hadoop management simpler by developing software for provisioning, managing, and monitoring Apache Hadoop clusters. Ambari provides an intuitive, easy-to-use Hadoop management web UI backed by its RESTful APIs
      ```
    Ambari enables System Administrators to:
    Provision a Hadoop Cluster
    Ambari provides a step-by-step wizard for installing Hadoop services across any number of hosts.
    Ambari handles configuration of Hadoop services for the cluster.
    Manage a Hadoop Cluster
    Ambari provides central management for starting, stopping, and reconfiguring Hadoop services across the entire cluster.
    Monitor a Hadoop Cluster
    Ambari provides a dashboard for monitoring health and status of the Hadoop cluster.
    Ambari leverages Ambari Metrics System for metrics collection.
    Ambari leverages Ambari Alert Framework for system alerting and will notify you when your attention is needed (e.g., a node goes down, remaining disk space is low, etc).
    Ambari enables Application Developers and System Integrators to:

    Easily integrate Hadoop provisioning, management, and monitoring capabilities to their own applications with the Ambari REST APIs.
      ```
source: [Apache Ambari Website](https://ambari.apache.org/)
[installation guide for Ambari including setting up a cluster for monitoring](https://cwiki.apache.org/confluence/display/AMBARI/Installation+Guide+for+Ambari+2.7.3)

# Summary
When deciding how to deploy apache spark cluster, the following has to be considered:
1. work loads 
2. resource usage
3. cost implications
4. support strategies

Looking at the 3 ways of deploying apache spark cluster, the best will be to use Azure HDInsight where the budget permits. A managed service is easy to manage,scalable, provides additional feature and easy to deploy, comes with SLA, but gives little control over the costs associated with infrastructure that comes with it. In this case I favor deploying on VMs using my own tools, it give me control o f the tools to deploy, infrastructure costs and monitoring tools to use.


