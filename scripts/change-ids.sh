#!/bin/bash

echo "Settings custom ids to cirros image and ext-net..."

source admin-creds

sql=/tmp/sql-dump.sql
newimage_id="00000000-1111-2222-3333-444444444444"
newpubnet_id="11111111-2222-3333-4444-555555555555"
image_id=$(nova image-list | awk '/cirros/{print $2}')
pubnet_id=$(neutron net-list | awk '/ext-net/{print $2}')

mv /var/lib/glance/images/$image_id /var/lib/glance/images/$newimage_id

mysqldump --all-databases -u root -pmisfcr > $sql
sed -i "s/$image_id/$newimage_id/g" $sql
sed -i "s/$pubnet_id/$newpubnet_id/g" $sql

mysql -u root -pmisfcr < $sql

rm $sql
