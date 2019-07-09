# Deployment strategy for Apache Spark on Azure
 
This document details how to setup and manage a High Availability Apache Spark cluster. Having a single standalone master creates a single point of failure,since the Master is a single point of failure, Spark offers the ability to start another instance of a master which will be in standby until the active master disappears. When the standby master becomes the active master, the workers will reconnect to this master and existing applicatione will continue running without problem.This functionality relies on ZooKeeper to perform master election.

Zookeeper provides a mechanism for leader election where you can configure multiple masters in the cluster for HA purposes which will be connected to the same Zookeeper instance. One master instance will take the role of a master and others would be in the standby mode. If the current master dies, Zookeeper will elect another standby instance as a Master, recover the older Master's state and then resume the scheduling.Since the information has been persisted on the filesystem, including Worker, Driver and Application information, this only impacts the scheduling of the new jobs without impacting any current running jobs.

Below are 3 strategies that can be followed
1. Directly on VMs 
2. Azure HDInsight
3. On Azure Kubernetes Service

# Running Apache spark on VMs

## Zookeeper Cluster 
Zookeeper will be deployed in a cluster of 3 nodes in an auto scaling set, with an ELB in front of the scale set.In a ZooKeeper cluster, if a leader dies the other remaining nodes will elect a leader among themselves. This will usually be very quick and there should be no visible outage to the clients. The clients that were connected to the leader that died will reconnect to one of the other nodes. A new node should be able to auto discover the other nodes already in the cluster, the same with existing nodes, existing nodes would periodically check if a new node has been added/removed updated the startup script and restart zookeeper. This would be configured using cloud init. The will follow a rolling update process. Each node knows the state of the cluster.

## Apache Spark Master
3 Apache masters will be deployed independently, each with a static ip,Each master need to be connected to same ZooKeeper url/ip/ELB.
In order to enable this recovery mode, create an `ha.conf`  using the following configuration:
```
            spark.deploy.recoveryMode Set to ZOOKEEPER to enable standby Master recovery mode (default: NONE)

            spark.deploy.zookeeper.url The ZooKeeper cluster url (e.g., n1a:5181,n2a:5181,n3a:5181).

            spark.deploy.zookeeper.dir The directory in ZooKeeper to store recovery state (default: /spark). This can be optional
```
Start multiple Master processes on different nodes with the same ZooKeeper configuration (ZooKeeper URL and directory).
## Apache Spark Slaves
Spark slaves will be deployed in auto scaling sets, using a init config,intial set of 2 will be used, scale based on cpu usage,When starting the worker, you now have to provide the reference to all the masters:
 example: 
 ```
    start-slave.sh spark://master1:7077,master2:7077,,master3:7077
 ```

# Running Apache spark on Azure HDInsight
 Apache Spark in Azure HDInsight is the Microsoft implementation of Apache Spark in the cloud

# Deployment  Tools
All the 3 can be deployed using terraform  or/and with ansible for automation and configuration maintainance.

# Overview
The 3 strageties work depending on the following:
1. work load -  this determines the number slaves which have to carry the work load/processes and how many of these have to run simulteneously
2. resource usage
3. cost implications
4. support strategies

