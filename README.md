# Kubernetes Cluster Setup

Simple script to install and configure Kubernetes Cluster Basics

## Prerequisites

You should have `ssh` access to all servers and also be able to sudo without asking for password.

To export the key of the controller server to all servers just run:
```bash
ssh-copy-id IP_OF_NODE1
ssh-copy-id IP_OF_NODE2
```

## Configuration

If you are running on the controller/master you just need to specify the IP of the controller and the IP array of the nodes on a `config.json` file

```json
{
    "MASTER_IP": "172.16.0.1",
    "MINIONS_IP": [
        "172.16.0.2",
        "172.16.0.3"
    ]
}
```

## Running

Just run the script on the controller or one of the nodes

```bash
# Run the script
sudo ./kube_install.sh

# Output should be similar to this
Loading Config
- MASTER IP: 172.16.0.1
- MINIONS IP: ( '172.16.0.2' '172.16.0.3')
----------
Configuring CONTROLLER Role
- Common Packages and Dependencies
-- Installing and configuring NTP
-- Configuring Repo
-- Installing Kube and Docker
-- Configuring etc/hosts
- Controller Specifics
-- Kubernetes/config
-- Kubernetes/apiserver
-- Installing and Configuring ETCD
-- * Starting 4 Services *
-- * 4 Services Started *
----------
Configuring MINION Role
- Minion 1
- Common Packages and Dependencies
-- Installing and configuring NTP
-- Configuring Repo
-- Installing Kube and Docker
-- Configuring etc/hosts
- Minion Specifics
-- Kubernetes/config
-- Kubernetes/kubelet
-- * Starting Services *
----------
- Minion 2
- Common Packages and Dependencies
-- Installing and configuring NTP
-- Configuring Repo
-- Installing Kube and Docker
-- Configuring etc/hosts
- Minion Specifics
-- Kubernetes/config
-- Kubernetes/kubelet
-- * Starting Services *
----------
OK - Kubernetes Setup Finished
```
