#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

apt-get -y install gawk

ipaddr=$(ip addr show dev enp0s8 | awk 'match($0, /inet ([0-9.]*)\/24/, m) { print m[1] }')

#
# Install telegraf
#

curl -sL https://repos.influxdata.com/influxdb.key | apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
apt-get update && apt-get -y install telegraf
install -c -m 0644 /vagrant/consul/telegraf.conf /etc/telegraf
systemctl enable telegraf
systemctl restart telegraf

#
# Install Consul server
#

cd /tmp
apt-get -y install unzip
unzip -o /vagrant/consul*.zip -d /tmp
install -c -m 0755 /tmp/consul /usr/local/sbin
install -c -m 0644 /vagrant/consul/consul.service /etc/systemd/system
install -d -m 0755 -o vagrant /data/consul /etc/consul.d
sed -e "s/@@BIND_ADDR@@/${ipaddr}/" < /vagrant/consul/server.json.tmpl > /etc/consul.d/server.json

systemctl daemon-reload
systemctl enable consul
systemctl restart consul
