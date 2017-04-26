# Kubernetes Cluster Setup

Simple script to install and configure Kubernetes Cluster Basics

## Configuration

If you are running on the controller/master you just need to specify the IP of the controller and the IP array of the nodes

```bash
MASTER_IP="172.31.112.215"
declare -a MINIONS_IP=('172.31.121.60');
```

## Running

Just run the script on the controller or one of the nodes

```bash
# Run the script
./kube_install.sh

# Output should be similar to this
Configuring CONTROLLER Role
- Common Packages and Dependencies
-- Installing and configuring NTP
-- Configuring Repo
-- Installing Kube and Docker
-- Configuring etc/hosts
-- Kubernetes/config
-- Kubernetes/apiserver
-- Installing and Configuring ETCD
-- * Starting 4 Services *
-- * 4 Services Started *
Configuring MINION Role
- Minion 1
- Common Packages and Dependencies
-- Installing and configuring NTP
-- Configuring Repo
-- Installing Kube and Docker
-- Configuring etc/hosts
-- Kubernetes/config
-- Kubernetes/kubelet
-- * Starting Services *
OK - Kubernetes Setup Finished
```