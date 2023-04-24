#!/bin/bash

#get config info
source config

#get primary NIC info
for i in $(ls /sys/class/net); do
    NIC=$i
    MY_MAC=$(cat /sys/class/net/$i/address)
    if [ "$(cat /sys/class/net/$i/ifindex)" == '2' ]; then
        #setup the IP configuration for management NIC
        sed -i.bak "s/dhcp/none/g" /etc/sysconfig/network-scripts/ifcfg-$NIC
        sed -i "s/HWADDR/#HWADDR/g" /etc/sysconfig/network-scripts/ifcfg-$NIC
        sed -i "/#HWADDR/a HWADDR=\"$MY_MAC\"" /etc/sysconfig/network-scripts/ifcfg-$NIC
        sed -i "s/UUID/#UUID/g" /etc/sysconfig/network-scripts/ifcfg-$NIC
        echo "IPADDR=\"$THISHOST_IP\"" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
        echo "NETMASK=\"$THISHOST_NETMASK\"" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
        echo "GATEWAY=\"$THISHOST_GATEWAY\"" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
        echo "DNS1=\"$THISHOST_DNS\"" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
        mv /etc/sysconfig/network-scripts/ifcfg-$NIC.bak .
    fi
    if [ "$(cat /sys/class/net/$i/ifindex)" == '3' ]; then
        #create config file for External NIC
        echo "HWADDR=\"$MY_MAC\"" > /etc/sysconfig/network-scripts/ifcfg-$NIC
        echo "TYPE=\"Ethernet\"" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
        echo "BOOTPROTO=\"dhcp\"" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
        echo "IPV4_FAILURE_FATAL=\"no\"" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
        echo "NAME=\"$NIC\"" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
        echo "ONBOOT=\"yes\"" >> /etc/sysconfig/network-scripts/ifcfg-$NIC
    fi        
done

#setup hostname
echo "$THISHOST_NAME" > /etc/hostname
cp os.hosts /etc/hosts
