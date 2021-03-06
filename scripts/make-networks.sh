#!/bin/bash
source admin-creds

# Create ext-net (public)
neutron net-create ext-net --shared --router:external True \
--provider:physical_network external --provider:network_type flat

# Create ext-subnet (public)
neutron subnet-create ext-net --name ext-subnet \
--allocation-pool start=172.16.117.50,end=172.16.117.99 \
--disable-dhcp --gateway 172.16.117.2 172.16.117.0/24

# only for admin user
neutron net-create admin-net

neutron subnet-create admin-net --name admin-subnet \
--dns-nameserver 172.16.117.2 \
--gateway 10.0.2.2 10.0.2.0/24

neutron router-create admin-router

neutron router-interface-add admin-router admin-subnet

neutron router-gateway-set admin-router ext-net

# for the demo tenant
source demo-creds
neutron net-create demo-net

neutron subnet-create demo-net --name demo-subnet \
--dns-nameserver 172.16.117.2 \
--gateway 192.168.1.1 192.168.1.0/24

neutron router-create demo-router

neutron router-interface-add demo-router demo-subnet

neutron router-gateway-set demo-router ext-net
