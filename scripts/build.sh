#!/bin/sh
set -e

# Configuration
MY_IMAGE_NAME="caprover/netdata"
NETDATA_VERSION="1.47.5"

# Safety check: only run in CI
if [ -z "$CI" ] || [ -z "$GITHUB_REF" ]; then
    echo "❌ Running on a local machine! Exiting!"
    exit 127
else
    echo "✅ Running on CI"
fi

# Enable Docker Buildx
export DOCKER_BUILDKIT=1
export DOCKER_CLI_EXPERIMENTAL=enabled

echo "=========================================="
echo "Building Netdata Docker Image"
echo "Version: ${NETDATA_VERSION}"
echo "Image: ${MY_IMAGE_NAME}"
echo "=========================================="

# Setup QEMU for multi-arch builds
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Create and use buildx builder
docker buildx create --name mybuilder --use || docker buildx use mybuilder

# Build and push multi-arch image
echo "Building for multiple architectures..."
docker buildx build \
  --platform linux/amd64,linux/arm/v7,linux/arm64,linux/386 \
  --progress=plain \
  --build-arg NETDATA_VERSION=${NETDATA_VERSION} \
  -t ${MY_IMAGE_NAME}:latest \
  -t ${MY_IMAGE_NAME}:${NETDATA_VERSION} \
  --push \
  .

echo "=========================================="
echo "✅ Build complete!"
echo "Images pushed:"
echo "  - ${MY_IMAGE_NAME}:latest"
echo "  - ${MY_IMAGE_NAME}:${NETDATA_VERSION}"
echo "=========================================="