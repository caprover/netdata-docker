#!/bin/bash
set -e
DEBIAN_FRONTEND=noninteractive

# some mirrors have issues, i skipped httpredir in favor of an eu mirror

echo "deb http://ftp.nl.debian.org/debian/ buster main" > /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list

# install dependencies for build
# source: https://learn.netdata.cloud/docs/agent/packaging/installer/methods/manual

apt-get -qq update
apt-get -y install zlib1g-dev uuid-dev libuv1-dev liblz4-dev libssl-dev libyaml-dev libelf-dev libmnl-dev libprotobuf-dev protobuf-compiler gcc g++ make git autoconf autoconf-archive autogen automake pkg-config curl python cmake netcat-openbsd jq lm-sensors nodejs python-mysqldb python-yaml libjudydebian1 libuv1 liblz4-1 openssl msmtp msmtp-mta apcupsd fping
apt-get clean

# fetch netdata

git clone https://github.com/firehol/netdata.git /netdata.git
cd /netdata.git
TAG=$(</git-tag)
if [ ! -z "$TAG" ]; then
	echo "Checking out tag: $TAG"
	git checkout tags/$TAG
else
	echo "No tag, using master"
fi

# fix for https://github.com/netdata/netdata/issues/11652

git submodule update --init --recursive

# use the provided installer

./netdata-installer.sh --dont-wait --dont-start-it --disable-telemetry

# removed hack on 2017/1/3
#chown root:root /usr/libexec/netdata/plugins.d/apps.plugin
#chmod 4755 /usr/libexec/netdata/plugins.d/apps.plugin

# remove build dependencies

cd /
rm -rf /netdata.git

dpkg -P zlib1g-dev uuid-dev libmnl-dev make git autoconf autogen automake pkg-config libuv1-dev liblz4-dev libjudy-dev libssl-dev cmake libelf-dev libprotobuf-dev protobuf-compiler g++
apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# symlink access log and error log to stdout/stderr

ln -sf /dev/stdout /var/log/netdata/access.log
ln -sf /dev/stdout /var/log/netdata/debug.log
ln -sf /dev/stderr /var/log/netdata/error.log