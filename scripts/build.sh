#!/bin/bash
set -e
DEBIAN_FRONTEND=noninteractive

# some mirrors have issues, i skipped httpredir in favor of an eu mirror

echo "deb http://deb.debian.org/debian/ bullseye main" > /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bullseye-security main" >> /etc/apt/sources.list

# install dependencies for build
# source: https://learn.netdata.cloud/docs/agent/packaging/installer/methods/manual

apt-get -qq update
apt-get -y install apcupsd autoconf autoconf-archive autogen automake cmake curl fping g++ gcc git jq libelf-dev libjudy-dev libjudydebian1 liblz4-1 liblz4-dev libmnl-dev libprotobuf-dev libssl-dev libuv1 libuv1-dev libyaml-dev lm-sensors make msmtp msmtp-mta netcat-openbsd nodejs openssl pkg-config protobuf-compiler python3-yaml python3-mysqldb openssl python3 uuid-dev zlib1g-dev
apt-get auto-clean -y

# fetch netdata
git config --global advice.detachedHead false

git clone https://github.com/netdata/netdata.git /netdata.git
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

dpkg -P zlib1g-dev uuid-dev libmnl-dev libyaml-dev make git autoconf autogen automake pkg-config libuv1-dev liblz4-dev libjudy-dev libssl-dev cmake libelf-dev libprotobuf-dev protobuf-compiler g++
apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# symlink access log and error log to stdout/stderr

ln -sf /dev/stdout /var/log/netdata/access.log
ln -sf /dev/stdout /var/log/netdata/debug.log
ln -sf /dev/stderr /var/log/netdata/error.log
