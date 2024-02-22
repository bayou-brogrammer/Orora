# syntax=docker/dockerfile:labs

ARG IMAGE_NAME="orora"
ARG IMAGE_FLAVOR="asus"
ARG IMAGE_REGISTRY="ghcr.io"
ARG FEDORA_MAJOR_VERSION="39"
ARG BASE_IMAGE_NAME="silverblue"
ARG BASE_IMAGE="ghcr.io/ublue-os/silverblue-asus"

# ============================================================================================== #
# Config
# ============================================================================================== #

FROM scratch as stage-config
COPY ./config /config

# ============================================================================================== #
# Files
# ============================================================================================== #

FROM alpine as stage-files
ARG FEDORA_MAJOR_VERSION

RUN \
  mkdir -p /etc/yum.repos.d/ && \
  # Warp
  wget https://app.warp.dev/download?package=rpm -O /tmp/warp.rpm && \
  # Docker Compose
  wget https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -O /tmp/docker-compose && \
  install -c -m 0755 /tmp/docker-compose /usr/bin && \
  # Pyxis
  wget https://copr.fedorainfracloud.org/coprs/kylegospo/prompt/repo/fedora-${FEDORA_MAJOR_VERSION}/kylegospo-prompt-fedora-${FEDORA_MAJOR_VERSION}.repo?arch=x86_64 -O /etc/yum.repos.d/_copr_kylegospo-prompt.repo && \
  wget https://copr.fedorainfracloud.org/coprs/kylegospo/gnome-vrr/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-gnome-vrr-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo

COPY --from=docker.io/mikefarah/yq:latest /usr/bin/yq /usr/bin/yq
COPY --from=gcr.io/projectsigstore/cosign:latest /ko-app/cosign /usr/bin/cosign

COPY scripts /tmp/scripts
COPY packages.yml /tmp/packages.yml
COPY system_files/shared /system_files

# ============================================================================================== #
# Modules
# ============================================================================================== #

# The default modules are inside ublue-os/bling
# Custom modules overwrite defaults
FROM scratch as stage-modules
COPY --from=ghcr.io/ublue-os/bling:latest /modules /modules

# ============================================================================================== #
# AKMODS - akmods:asus-39
# ============================================================================================== #

FROM scratch as stage-akmods-asus
COPY --from=ghcr.io/ublue-os/akmods:asus-39 /rpms /rpms

# ============================================================================================== #
# Orora Image
# ============================================================================================== #

FROM ${BASE_IMAGE}:latest as orora

LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A starting point"
LABEL io.artifacthub.package.readme-url=https://raw.githubusercontent.com/blue-build/cli/main/README.md

ARG BASE_IMAGE
ARG IMAGE_NAME
ARG FEDORA_MAJOR_VERSION
ARG IMAGE_REGISTRY="localhost"
ARG RECIPE="./config/recipe.yml"
ARG CONFIG_DIRECTORY="/tmp/config"

COPY --from=stage-files /tmp /tmp
COPY --from=stage-files /usr/bin /usr/bin
COPY --from=stage-files /etc/yum.repos.d /etc/yum.repos.d

RUN \
  --mount=type=bind,from=stage-akmods-asus,src=/rpms,dst=/tmp/rpms,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=cache,dst=/var/lib/rpm-ostree,id=rpm-ostree-lib-orora-latest,sharing=locked \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  source /tmp/scripts/exports.sh && \
  # Setup firmware and asusctl for ASUS devices
  /tmp/scripts/install/firmware.sh && \
  # AKMods Section
  chmod +x /tmp/modules/akmods/akmods.sh && \
  /tmp/scripts/install/akmods.sh

# Apply IP Forwarding before installing Docker to prevent messing with LXC networking
RUN sysctl -p

# Install all packages and software
RUN \
  --mount=type=cache,dst=/var/lib/rpm-ostree,id=rpm-ostree-lib-orora-latest,sharing=locked \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  source /tmp/scripts/install/packages.sh && \
  # Gnome VRR, Pyxis, Warp
  /tmp/scripts/install/software.sh

# Copy atuin from bluefin-cli
COPY --from=ghcr.io/ublue-os/bluefin-cli /usr/bin/atuin /usr/bin/atuin
COPY --from=ghcr.io/ublue-os/bluefin-cli /usr/share/bash-prexec /usr/share/bash-prexec

# COPY FILES
COPY --from=stage-files /system_files /
COPY --from=stage-files /usr/share /usr/share

# WORKAROUNDS
RUN /tmp/scripts/workarounds.sh

# Cleanup and Commit
RUN rm -rf \
  /tmp/* \
  /var/* && \
  rm -f /etc/yum.repos.d/_copr_kylegospo-prompt.repo && \
  rm -f /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo && \
  mkdir -p /var/tmp && \
  chmod -R 1777 /var/tmp && \
  ostree container commit
