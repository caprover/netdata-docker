#!/bin/bash
set -e
DEBIAN_FRONTEND=noninteractive

# some mirrors have issues, i skipped httpredir in favor of an eu mirror, moved to bookworm, and they cause duplicates only.

# echo "deb http://deb.debian.org/debian/ bookworm main" > /etc/apt/sources.list
# echo "deb http://security.debian.org/debian-security bookworm-security main" >> /etc/apt/sources.list

# install dependencies for build
# source: https://learn.netdata.cloud/docs/agent/packaging/installer/methods/manual

apt-get update -qq && \
apt-get install -y ca-certificates git-man netcat-openbsd krb5-locales less libbrotli1 libbsd0 libcbor0.8 libcurl3-gnutls libcurl4 libedit2 liberror-perl libexpat1 libfido2-1 libgdbm-compat4 libgdbm6 libgssapi-krb5-2 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libldap-2.5-0 libldap-common libnghttp2-14 libperl5.36 libpsl5 librtmp1 libsasl2-2 libsasl2-modules libsasl2-modules-db libssh2-1 libssl3 libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 libxext6 libxmuu1 netbase openssh-client openssl patch nodejs perl perl-modules-5.36 publicsuffix xauth && \
apt-get install -y autoconf autoconf-archive autogen automake cmake curl g++ gcc git gzip libatomic1 libuuid1 libelf-dev libjson-c-dev libjudy-dev liblz4-dev libmnl-dev libssl-dev libsystemd-dev libuv1-dev libyaml-dev lm-sensors make pkg-config python3 python3-mysqldb python3-yaml tar uuid-dev zlib1g-dev libprotobuf-dev protobuf-compiler

# fetch netdata

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

# remove build dependencies

cd /
rm -rf /netdata.git

dpkg -P iproute2 libelf-dev libjudy-dev liblz4-dev libmnl-dev libprotobuf-dev libssl-dev libuv1-dev libyaml-dev lm-sensors make netcat-openbsd pkg-config protobuf-compiler python3-mysqldb python3-yaml uuid-dev zlib1g-dev

apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# symlink access log and error log to stdout/stderr

ln -sf /dev/stdout /var/log/netdata/access.log
ln -sf /dev/stdout /var/log/netdata/debug.log
ln -sf /dev/stderr /var/log/netdata/error.log