#!/bin/bash

set -euo pipefail

IMAGE_INFO="/usr/share/ublue-os/image-info.json"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"

case $FEDORA_MAJOR_VERSION in
38)
  IMAGE_TAG="gts"
  ;;
*)
  IMAGE_TAG="$FEDORA_MAJOR_VERSION"
  ;;
esac

cat >$IMAGE_INFO <<EOF
{
  "image-tag":"$IMAGE_TAG",
  "image-ref": "$IMAGE_REF",
  "image-name": "$IMAGE_NAME",
  "image-flavor": "$IMAGE_FLAVOR",
  "image-vendor": "$IMAGE_VENDOR",
  "base-image-name": "$BASE_IMAGE_NAME",
  "fedora-version": "$FEDORA_MAJOR_VERSION"
}
EOF
