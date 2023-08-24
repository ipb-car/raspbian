#!/bin/bash -e

echo "interface eth0" >>/etc/dhcpcd.conf
echo "static ip_address=192.168.1.200/24" >>/etc/dhcpcd.conf
echo "static routers=192.168.1.1" >>/etc/dhcpcd.conf
echo "static domain_name_servers=192.168.1.1" >>/etc/dhcpcd.conf
echo "denyinterfaces eth0" >>/etc/dhcpcd.conf
