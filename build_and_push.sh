#!/bin/sh

MY_IMAGE_NAME="caprover/netdata"
NETDATA_VERSION="v1.8.0"

# ensure you're not running it on local machine
if [ -z "$CI" ] || [ -z "$GITHUB_REF" ]; then
    echo "Running on a local machine! Exiting!"
    exit 127
else
    echo "Running on CI"
fi

docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

echo "Deploying to Docker hub ..."

echo "$NETDATA_VERSION" > git-tag

export DOCKER_CLI_EXPERIMENTAL=enabled
docker buildx ls
docker buildx create --name mybuilder
docker buildx use mybuilder

# REMOVED linux/arm64 as debie:jessie isn't built for linux/arm64
docker buildx build --platform linux/amd64,linux/arm,linux/arm64 -t $MY_IMAGE_NAME:latest -t $MY_IMAGE_NAME:$NETDATA_VERSION --push .
