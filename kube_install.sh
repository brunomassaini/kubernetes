#!/bin/bash

# SSH info
SSHKEY="/home/user/.ssh/id_rsa"
SSHUSER="user"

# Specify Server Role
# controller or minion
CONTROLLER="true"

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
if [ $CONTROLLER = "true" ]; then
  echo "Configuring CONTROLLER Role"
else
  echo "Configuring MINION Role"
fi

echo "- Common Packages and Dependencies"

echo "-- Installing and configuring NTP"
{
  yum install -y ntp
  systemctl enable ntpd && systemctl start ntpd
} &> /dev/null

echo "-- Configuring Repo"
if [ -f $REPO_FILE ]; then
   > $REPO_FILE
fi
echo $REPO >> $REPO_FILE
echo name=$RELEASE >> $REPO_FILE
echo baseurl=$BASEURL >> $REPO_FILE
echo gpgcheck=$GPGCHECK >> $REPO_FILE
yum update &> /dev/null

echo "-- Installing Kube and Docker"
yum install -y --enablerepo=$RELEASE kubernetes docker &> /dev/null

echo "-- Configuring etc/hosts"
sed -i '/$MASTER_DNS/d' /etc/hosts
sed -i '/$MINIONS_DNS/d' /etc/hosts
echo $MASTER_IP $MASTER_DNS >> /etc/hosts
for i in ${!MINIONS_IP[@]} ; do
  echo ${MINIONS_IP[$i]} $MINIONS_DNS`expr $i + 1` >> /etc/hosts
done

if [ $CONTROLLER = "true" ]; then

  echo "- Controller Specifics"
  echo "-- Kubernetes/config"
  sed -i '/KUBE_MASTER/c\KUBE_MASTER="--master=http://'"${MASTER_DNS}"':8080"' /etc/kubernetes/config
  echo 'KUBE_ETCD_SERVERS="--etcd-servers=http://'"${MASTER_DNS}"':2379"' >> /etc/kubernetes/config

  echo "-- Kubernetes/apiserver"
  sed -i '/KUBE_API_ADDRESS/c\KUBE_API_ADDRESS="--address=0.0.0.0"' /etc/kubernetes/apiserver
  sed -i '/KUBELET_PORT/c\KUBELET_PORT="--kubelet-port=10250"' /etc/kubernetes/apiserver
  sed -i '/KUBE_ADMISSION_CONTROL/d' /etc/kubernetes/apiserver

  echo "-- Installing and Configuring ETCD"
  yum -y install etcd &> /dev/null
  sed -i '/ETCD_LISTEN_CLIENT_URLS/c\ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"' /etc/etcd/etcd.conf
  sed -i '/ETCD_ADVERTISE_CLIENT_URLS/c\ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379"' /etc/etcd/etcd.conf

  echo "-- * Starting 4 Services *"
  systemctl enable etcd kube-apiserver kube-controller-manager kube-scheduler &> /dev/null
  systemctl start etcd kube-apiserver kube-controller-manager kube-scheduler
  echo "-- *" `systemctl status etcd kube-apiserver kube-controller-manager kube-scheduler | grep "(running)" | wc -l` "Services Started *"

  echo "Configuring MINION Role"
  for i in ${!MINIONS_IP[@]} ; do
    echo "- Minion" `expr $i + 1`

    ssh -T -i $SSHKEY $SSHUSER@$MINIONS_DNS`expr $i + 1` << EOF

      echo "- Common Packages and Dependencies"
      sudo su

      echo "-- Installing and configuring NTP"
      {
        yum install -y ntp
        systemctl enable ntpd && systemctl start ntpd
      } &> /dev/null

      echo "-- Configuring Repo"
      if [ -f $REPO_FILE ]; then
         > $REPO_FILE
      fi
      echo $REPO >> $REPO_FILE
      echo name=$RELEASE >> $REPO_FILE
      echo baseurl=$BASEURL >> $REPO_FILE
      echo gpgcheck=$GPGCHECK >> $REPO_FILE
      yum update &> /dev/null

      echo "-- Installing Kube and Docker"
      yum install -y --enablerepo=$RELEASE kubernetes docker &> /dev/null

      echo "-- Configuring etc/hosts"
      sed -i '/$MASTER_DNS/d' /etc/hosts
      sed -i '/$MINIONS_DNS/d' /etc/hosts
      echo $MASTER_IP $MASTER_DNS >> /etc/hosts
      for i in ${!MINIONS_IP[@]} ; do
        echo ${MINIONS_IP[$i]} $MINIONS_DNS`expr $i + 1` >> /etc/hosts
      done

      echo "- Minion Specifics"
      echo "-- Kubernetes/config"
      sed -i '/KUBE_MASTER/c\KUBE_MASTER="--master=http://'"${MASTER_DNS}"':8080"' /etc/kubernetes/config
      echo 'KUBE_ETCD_SERVERS="--etcd-servers=http://'"${MASTER_DNS}"':2379"' >> /etc/kubernetes/config

      echo "-- Kubernetes/kubelet"
      sed -i '/KUBELET_ADDRESS/c\KUBELET_ADDRESS="--address=0.0.0.0"' /etc/kubernetes/kubelet
      sed -i '/KUBELET_PORT/c\KUBELET_PORT="--port=10250"' /etc/kubernetes/kubelet
      sed -i '/KUBELET_HOSTNAME/c\KUBELET_HOSTNAME="--hostname-override='"${MINIONS_DNS}"'`expr $i + 1`"' /etc/kubernetes/kubelet
      sed -i '/KUBELET_API_SERVER/c\KUBELET_API_SERVER="--api-servers='"${MASTER_DNS}"':8080"' /etc/kubernetes/kubelet
      sed -i '/KUBELET_POD_INFRA_CONTAINER/d' /etc/kubernetes/kubelet

      echo "-- * Starting Services *"
      systemctl enable kube-proxy kubelet docker &> /dev/null
      systemctl start kube-proxy kubelet docker &> /dev/null

      exit
EOF

  done

fi

echo "OK - Kubernetes Setup Finished"