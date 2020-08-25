#!/bin/sh

# ensure you're not running it on local machine
env


# docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
MY_IMAGE_NAME="caprover/netdata"
NETDATA_VERSION="v1.8.0"

echo "Deploying to Docker hub ..."

echo "$NETDATA_VERSION" > git-tag

export DOCKER_CLI_EXPERIMENTAL=enabled
docker buildx ls
docker buildx create --name mybuilder
docker buildx use mybuilder

# linux/arm/v7 changed to linux/arm to be more generic
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t $MY_IMAGE_NAME:latest -t $MY_IMAGE_NAME:$NETDATA_VERSION --push .