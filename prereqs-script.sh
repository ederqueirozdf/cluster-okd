#!/bin/bash

#https://docs.okd.io/3.11/install/prerequisites.html#install-config-network-using-firewalld       
systemctl stop firewalld && systemctl disable firewalld

#https://docs.okd.io/3.11/install/prerequisites.html#prereq-dns
echo -e "NM_CONTROLLED=yes" >> /etc/sysconfig/network-scripts/ifcfg-ens160
cat /etc/sysconfig/network-scripts/ifcfg-ens160
sleep 3

#https://docs.okd.io/3.11/install/host_preparation.html#installing-base-packages
yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
yum -y --enablerepo=epel install ansible pyOpenSSL

#https://docs.okd.io/3.11/install/host_preparation.html#installing-docker
yum install -y docker-1.13.1 && rpm -V docker-1.13.1 && docker version
sleep 3

#https://docs.okd.io/3.11/install/host_preparation.html#configuring-docker-thin-pool
echo -e "DEVS=/dev/sdb\nVG=docker-vg" > /etc/sysconfig/docker-storage-setup && docker-storage-setup
sleep 3
echo "Verificando docker-storage-setup"
cat /etc/sysconfig/docker-storage
echo -e "\n\n"
lvs
sleep 3
systemctl enable docker
systemctl start docker
systemctl is-active docker
