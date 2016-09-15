#!/bin/bash

#get the configuration info
source config

## BASICS
# may be useful (even later...)
yum -y install wget patch

#install ntp/chrony
yum -y install chrony
systemctl enable chronyd.service
sed -i 's/^server/#server/g' /etc/chrony.conf
sed -i 's/^#server\ 0/server\ 134.158.120.1\ iburst\n#server\ 0/g' /etc/chrony.conf
sed -i 's/^#allow/allow\ 10.0.0.0\/24\n#allow/' /etc/chrony.conf
systemctl start chronyd.service

#loosen things up
systemctl stop firewalld.service
systemctl disable firewalld.service

#openstack repos
yum -y install centos-release-openstack-liberty 
yum -y upgrade
yum -y install openstack-selinux python-openstackclient

#install database server
yum -y install mariadb mariadb-server MySQL-python

#edit /etc/my.cnf.d/mariadb_openstack.cnf
echo "[mysqld]\n\
bind-address = $CONTROLLER_IP\n\
default-storage-engine = innodb\n\
innodb_file_per_table\n\
collation-server = utf8_general_ci\n\
init-connect = 'SET NAMES utf8'\n\
character-set-server = utf8" > /etc/my.cnf.d/mariadb_openstack.cnf

#start database server
systemctl enable mariadb.service
systemctl start mariadb.service

#now run through the mysql_secure_installation
mysql_secure_installation

#install messaging service
yum -y install rabbitmq-server
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service
rabbitmqctl add_user openstack $SERVICE_PWD
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#create databases
echo 'Enter the new MySQL root password'
mysql -u root -p$SERVICE_PWD <<EOF
CREATE DATABASE nova;
CREATE DATABASE cinder;
CREATE DATABASE glance;
CREATE DATABASE keystone;
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$SERVICE_PWD';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$SERVICE_PWD';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$SERVICE_PWD';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$SERVICE_PWD';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$SERVICE_PWD';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$SERVICE_PWD';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$SERVICE_PWD';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$SERVICE_PWD';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$SERVICE_PWD';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$SERVICE_PWD';
FLUSH PRIVILEGES;
EOF

## KEYSTONE identity service

#install components
yum -y install openstack-keystone httpd mod_wsgi memcached python-memcached

#start memcached
systemctl enable memcached.service
systemctl start memcached.service

#edit /etc/keystone.conf
sed -i.liberty_orig "s/#admin_token = ADMIN/admin_token = $ADMIN_TOKEN/g" /etc/keystone/keystone.conf
sed -i "/^\[database\]/a \
connection = mysql://keystone:$SERVICE_PWD@$CONTROLLER_IP/keystone\n" /etc/keystone/keystone.conf
sed -i "/^\[memcache\]/a \
servers = localhost:11211\n" /etc/keystone/keystone.conf
sed -i "/^\[token\]/a \
provider = uuid\n\
driver = memcache\n" /etc/keystone/keystone.conf
sed -i "/^\[revoke\]/a \
driver = sql\n" /etc/keystone/keystone.conf

#populate identity database
su -s /bin/sh -c "keystone-manage db_sync" keystone

#configure httpd
sed -i "/^#ServerName\ www.example.com:80/a \
ServerName controller" /etc/httpd/conf/httpd.conf

cp os.wsgi-keystone.conf /etc/httpd/conf.d/wsgi-keystone.conf

#start keystone/httpd
systemctl enable httpd.service
systemctl start httpd.service

#create users and tenants
export OS_TOKEN=$ADMIN_TOKEN
export OS_URL=http://$CONTROLLER_IP:35357/v3
export OS_IDENTITY_API_VERSION=3
openstack service create --name keystone --description "OpenStack Identity" identity
openstack endpoint create --region RegionOne identity public http://$CONTROLLER_IP:5000/v2.0
openstack endpoint create --region RegionOne identity internal http://$CONTROLLER_IP:5000/v2.0
openstack endpoint create --region RegionOne identity admin http://$CONTROLLER_IP:35357/v2.0
openstack project create --domain default --description "Admin Project" admin
openstack user create --domain default --password $ADMIN_PWD admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password $USER_PWD user1
openstack user create --domain default --password $USER_PWD user2
openstack role create user
openstack role add --project demo --user user1 user
openstack role add --project demo --user user2 user

unset OS_TOKEN OS_URL OS_IDENTITY_API_VERSION

source admin-creds

## GLANCE image service

#create keystone entries for glance
openstack user create --domain default --password $SERVICE_PWD glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image service" image
openstack endpoint create --region RegionOne image public http://$CONTROLLER_IP:9292
openstack endpoint create --region RegionOne image internal http://$CONTROLLER_IP:9292
openstack endpoint create --region RegionOne image admin http://$CONTROLLER_IP:9292

#install glance
yum -y install openstack-glance python-glanceclient python-glance

#edit /etc/glance/glance-api.conf
sed -i.liberty_orig "/^\[database\]/a \
connection = mysql://glance:$SERVICE_PWD@$CONTROLLER_IP/glance\n" /etc/glance/glance-api.conf

sed -i "/^\[keystone_authtoken\]/a \
auth_uri = http://$CONTROLLER_IP:5000\n\
auth_url = http://$CONTROLLER_IP:35357\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
project_name = service\n\
username = glance\n\
password = $SERVICE_PWD\n" /etc/glance/glance-api.conf

sed -i "/^\[paste_deploy\]/a \
flavor = keystone\n" /etc/glance/glance-api.conf

sed -i "/^\[glance_store\]/a \
default_store = file\n\
filesystem_store_datadir = /var/lib/glance/images/\n" /etc/glance/glance-api.conf

sed -i "/^\[DEFAULT\]/a \
notification_driver = noop\n" /etc/glance/glance-api.conf

#edit /etc/glance/glance-registry.conf
sed -i.liberty_orig "/^\[database\]/a \
connection = mysql://glance:$SERVICE_PWD@$CONTROLLER_IP/glance\n" /etc/glance/glance-registry.conf

sed -i "/^\[keystone_authtoken\]/a \
auth_uri = http://$CONTROLLER_IP:5000\n\
auth_url = http://$CONTROLLER_IP:35357\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
project_name = service\n\
username = glance\n\
password = $SERVICE_PWD\n" /etc/glance/glance-registry.conf

sed -i "/^\[paste_deploy\]/a \
flavor = keystone\n" /etc/glance/glance-registry.conf

sed -i "/^\[DEFAULT\]/a \
notification_driver = noop\n" /etc/glance/glance-registry.conf

#start glance
su -s /bin/sh -c "glance-manage db_sync" glance
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service

#upload the cirros image to glance
wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
glance image-create --name "cirros-0.3.4-x86_64" --file cirros-0.3.4-x86_64-disk.img \
  --disk-format qcow2 --container-format bare --visibility public --progress

## NOVA compute service

#create the keystone entries for nova
openstack user create --domain default --password $SERVICE_PWD nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne compute public http://$CONTROLLER_IP:8774/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://$CONTROLLER_IP:8774/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://$CONTROLLER_IP:8774/v2/%\(tenant_id\)s

#install the nova controller components
yum -y install openstack-nova-api openstack-nova-cert openstack-nova-conductor \
  openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler \
  python-novaclient

#edit /etc/nova/nova.conf
sed -i.liberty_orig "/^\[database\]/a \
connection = mysql://nova:$SERVICE_PWD@$CONTROLLER_IP/nova\n" /etc/nova/nova.conf

sed -i "/^\[DEFAULT\]/a \
rpc_backend = rabbit\n\
my_ip = $CONTROLLER_IP\n\
network_api_class = nova.network.neutronv2.api.API\n\
security_group_api = neutron\n\
linuxnet_interface_driver = nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver\n\
firewall_driver = nova.virt.firewall.NoopFirewallDriver\n\
enabled_apis=osapi_compute,metadata\n\
auth_strategy = keystone\n" /etc/nova/nova.conf

sed -i "/^\[oslo_messaging_rabbit\]/a \
rabbit_host = $CONTROLLER_IP\n\
rabbit_userid = openstack\n\
rabbit_password = $SERVICE_PWD\n" /etc/nova/nova.conf

sed -i "/^\[keystone_authtoken\]/a \
auth_uri = http://$CONTROLLER_IP:5000\n\
auth_url = http://$CONTROLLER_IP:35357\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
project_name = service\n\
username = nova\n\
password = $SERVICE_PWD\n" /etc/nova/nova.conf

sed -i "/^\[vnc\]/a \
vncserver_listen = \$my_ip\n\
vncserver_proxyclient_address = \$my_ip\n" /etc/nova/nova.conf

sed -i "/^\[glance\]/a \
host = $CONTROLLER_IP\n" /etc/nova/nova.conf

sed -i "/^\[oslo_concurrency\]/a \
lock_path = /var/lib/nova/tmp\n" /etc/nova/nova.conf

#start nova
su -s /bin/sh -c "nova-manage db sync" nova

systemctl enable openstack-nova-api.service openstack-nova-cert.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service openstack-nova-cert.service \
  openstack-nova-consoleauth.service openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service

## NEURTON network service

#create keystone entries for neutron
openstack user create --domain default --password $SERVICE_PWD neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://$NETWORK_IP:9696
openstack endpoint create --region RegionOne network internal http://$NETWORK_IP:9696
openstack endpoint create --region RegionOne network admin http://$NETWORK_IP:9696

#configure nova to use neutron
sed -i "/^\[neutron\]/a \
url = http://$NETWORK_IP:9696\n\
auth_url = http://$CONTROLLER_IP:35357\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
region_name = RegionOne\n\
project_name = service\n\
username = neutron\n\
password = $SERVICE_PWD\n\
service_metadata_proxy = True\n\
metadata_proxy_shared_secret = $META_PWD\n" /etc/nova/nova.conf

systemctl restart openstack-nova-api.service

## HORIZON dashboard
yum -y install openstack-dashboard

#edit /etc/openstack-dashboard/local_settings
sed -i.liberty_orig "s/ALLOWED_HOSTS = \['horizon.example.com', 'localhost'\]/ALLOWED_HOSTS = ['*', ]/" /etc/openstack-dashboard/local_settings
sed -i 's/OPENSTACK_HOST = "127.0.0.1"/OPENSTACK_HOST = "'"$CONTROLLER_IP"'"/' /etc/openstack-dashboard/local_settings
sed -i "s/LocMemCache',/LocMemCache',\n        'LOCATION': '127.0.0.1:11211',/" /etc/openstack-dashboard/local_settings
sed -i 's/django.core.cache.backends.locmem.LocMemCache/django.core.cache.backends.memcached.MemcachedCache/g' /etc/openstack-dashboard/local_settings
sed -i 's/_member_/user/' /etc/openstack-dashboard/local_settings
#sed -i 's/#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/g' /etc/openstack-dashboard/local_settings

echo 'OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "volume": 2,
}' >> /etc/openstack-dashboard/local_settings

sed -i "s/'enable_ipv6': True,/'enable_ipv6': False,/" /etc/openstack-dashboard/local_settings
sed -i 's/^TIME_ZONE = "UTC"/TIME_ZONE = "Europe\/Paris"/' /etc/openstack-dashboard/local_settings

#start dashboard
systemctl enable httpd.service memcached.service
systemctl restart httpd.service memcached.service

## CINDER block storage service

#create keystone entries for cinder
openstack user create --domain default --password $SERVICE_PWD cinder
openstack role add --project service --user cinder admin
openstack service create --name cinder --description "OpenStack Block Storage" volume
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack endpoint create --region RegionOne volume public http://$CONTROLLER_IP:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volume internal http://$CONTROLLER_IP:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volume admin http://$CONTROLLER_IP:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 public http://$CONTROLLER_IP:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://$CONTROLLER_IP:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://$CONTROLLER_IP:8776/v2/%\(tenant_id\)s

#install cinder controller
yum -y install openstack-cinder python-cinderclient

#edit /etc/cinder/cinder.conf
sed -i.liberty_orig "/^\[database\]/a \
connection = mysql://cinder:$SERVICE_PWD@$CONTROLLER_IP/cinder" /etc/cinder/cinder.conf

sed -i "/^\[DEFAULT\]/a \
rpc_backend = rabbit\n\
auth_strategy = keystone\n\
my_ip = $CONTROLLER_IP" /etc/cinder/cinder.conf

sed -i "/^\[oslo_messaging_rabbit\]/a \
rabbit_host = $CONTROLLER_IP\n\
rabbit_userid = openstack\n\
rabbit_password = $SERVICE_PWD\n" /etc/cinder/cinder.conf 

sed -i "/^\[keystone_authtoken\]/a \
auth_uri = http://$CONTROLLER_IP:5000\n\
auth_url = http://$CONTROLLER_IP:35357\n\
auth_plugin = password\n\
project_domain_id = default\n\
user_domain_id = default\n\
project_name = service\n\
username = cinder\n\
password = $SERVICE_PWD\n" /etc/cinder/cinder.conf

sed -i "/^\[oslo_concurrency\]/a \
lock_path = /var/lib/cinder/tmp\n" /etc/cinder/cinder.conf

#configure nova to use cinder
sed -i "/^\[cinder\]/a \
os_region_name = RegionOne\n" /etc/nova/nova.conf

#start cinder controller
su -s /bin/sh -c "cinder-manage db sync" cinder
systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl restart openstack-nova-api.service

#EOF
