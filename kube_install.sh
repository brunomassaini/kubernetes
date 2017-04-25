#!/bin/bash

# Specify Server Role
# controller or minion
ROLE="controller"

# Master and Minions IP / DNS
MASTER_IP="172.31.112.215"
declare -a MINIONS_IP=('172.31.121.60');
MASTER_DNS="centos-master"
MINIONS_DNS="centos-minion"

# Yum Repo
RELEASE="virt7-docker-common-release"
REPO_FILE="/etc/yum.repos.d/"$RELEASE".repo"
REPO="["$RELEASE"]"
BASEURL="http://cbs.centos.org/repos/"$RELEASE"/x86_64/os/"
GPGCHECK="0"

# Installation
echo "Common Packages and Dependencies"

echo "- Installing and configuring NTP"
{
  sudo yum install -y ntp
  sudo systemctl enable ntpd && systemctl start ntpd
} &> /dev/null

echo "- Configuring Repo"
if [ -f $REPO_FILE ]; then
   > $REPO_FILE
fi
sudo echo $REPO >> $REPO_FILE
sudo echo name=$RELEASE >> $REPO_FILE
sudo echo baseurl=$BASEURL >> $REPO_FILE
sudo echo gpgcheck=$GPGCHECK >> $REPO_FILE
sudo yum update &> /dev/null

echo "- Installing Kube and Docker"
sudo yum install -y --enablerepo=$RELEASE kubernetes docker &> /dev/null

echo "- Configuring etc/hosts"
sudo sed -i '/$MASTER_DNS/d' /etc/hosts
sudo sed -i '/$MINIONS_DNS/d' /etc/hosts
echo $MASTER_IP $MASTER_DNS >> /etc/hosts
for i in ${!MINIONS_IP[@]} ; do
  echo ${MINIONS_IP[$i]} $MINIONS_DNS`expr $i + 1` >> /etc/hosts
done

if [ $ROLE = "controller" ]; then
  echo "Configuring CONTROLLER Role"

  echo "- Kubernetes/config"
  sudo sed -i '/KUBE_MASTER/c\KUBE_MASTER="--master=http://'"${MASTER_DNS}"':8080"' /etc/kubernetes/config
  echo 'KUBE_ETCD_SERVERS="--etcd-servers=http://'"${MASTER_DNS}"':2379"' >> /etc/kubernetes/config
  
  echo "- Kubernetes/apiserver"
  sudo sed -i '/KUBE_API_ADDRESS/c\KUBE_API_ADDRESS="--address=0.0.0.0"' /etc/kubernetes/apiserver
  sudo sed -i '/KUBELET_PORT/c\KUBELET_PORT="--kubelet-port=10250"' /etc/kubernetes/apiserver
  sudo sed -i '/KUBE_ADMISSION_CONTROL/d' /etc/kubernetes/apiserver
  
  echo "- Installing and Configuring ETCD"
  sudo yum -y install etcd &> /dev/null
  sudo sed -i '/ETCD_LISTEN_CLIENT_URLS/c\ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"' /etc/etcd/etcd.conf
  sudo sed -i '/ETCD_ADVERTISE_CLIENT_URLS/c\ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379"' /etc/etcd/etcd.conf
  
  echo "* Starting 4 Services *"
  sudo systemctl enable etcd kube-apiserver kube-controller-manager kube-scheduler &> /dev/null
  sudo systemctl start etcd kube-apiserver kube-controller-manager kube-scheduler
  echo "*" `systemctl status etcd kube-apiserver kube-controller-manager kube-scheduler | grep "(running)" | wc -l` "Services Started *" 

  echo "Configuring MINION Role"
  for i in ${!MINIONS_IP[@]} ; do
    echo "- Minion" $1
    echo "-- "
    ssh $MINIONS_DNS`expr $i + 1` << EOF
      echo "I was here" >> ~/teste
EOF
  done

fi

if [ $ROLE = "minion" ]; then
  echo "Configuring MINION Role"
fi

echo "OK - Kubernetes Setup Finished"