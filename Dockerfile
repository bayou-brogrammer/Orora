# syntax=docker/dockerfile:1.3-labs

ARG IMAGE_NAME="orora"
ARG IMAGE_FLAVOR="asus"
ARG IMAGE_REGISTRY="ghcr.io"
ARG FEDORA_MAJOR_VERSION="40"
ARG BASE_IMAGE_NAME="silverblue"
ARG BASE_IMAGE="ghcr.io/bayou-brogrammer/silverblue-asus-main"

# ============================================================================================== #
# Config
# ============================================================================================== #

FROM scratch as stage-config
COPY ./config /config

# ============================================================================================== #
# Files
# ============================================================================================== #

FROM scratch as stage-files
COPY ./config/files/usr /usr

# ============================================================================================== #
# Modules
# ============================================================================================== #

# The default modules are inside ublue-os/bling
# Custom modules overwrite defaults
FROM scratch as stage-modules
COPY --from=ghcr.io/ublue-os/bling:latest /modules /modules
COPY ./modules /modules

# ============================================================================================== #
# AKMODS - akmods:asus-39
# ============================================================================================== #

FROM scratch as stage-akmods-asus
COPY --from=ghcr.io/ublue-os/akmods:asus-39 /rpms /rpms

# ============================================================================================== #
# Exports
# ============================================================================================== #

# This stage is responsible for holding onto
# exports like the exports.sh
FROM docker.io/alpine as stage-exports
RUN printf "#!/usr/bin/env bash\n\nget_yaml_array() { \n  readarray -t \"\$1\" < <(echo \"\$3\" | yq -I=0 \"\$2\")\n} \n\nexport -f get_yaml_array\nexport OS_VERSION=\$(grep -Po '(?<=VERSION_ID=)\d+' /usr/lib/os-release)" >> /exports.sh && chmod +x /exports.sh

# ============================================================================================== #
# Orora Image
# ============================================================================================== #

FROM ${BASE_IMAGE}:latest as orora

LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A starting point"
LABEL io.artifacthub.package.readme-url=https://raw.githubusercontent.com/blue-build/cli/main/README.md

ARG BASE_IMAGE
ARG IMAGE_NAME
ARG IMAGE_REGISTRY="localhost"
ARG RECIPE="./config/recipe.yml"
ARG CONFIG_DIRECTORY="/tmp/config"

COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq
COPY --from=gcr.io/projectsigstore/cosign /ko-app/cosign /usr/bin/cosign

RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/akmods/akmods.sh && \
  chmod +x /tmp/modules/rpm-ostree/rpm-ostree.sh && \
  chmod +x /tmp/modules/default-flatpaks/default-flatpaks.sh && \
  source /tmp/exports.sh && \
  /tmp/modules/akmods/akmods.sh '{"type":"akmods"}' && \
  /tmp/modules/rpm-ostree/rpm-ostree.sh '{"type":"rpm-ostree","repos":["https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-%OS_VERSION%/atim-starship-fedora-%OS_VERSION%.repo"],"install":["starship"],"remove":["firefox","firefox-langpacks"]}' && \
  /tmp/modules/default-flatpaks/default-flatpaks.sh '{"type":"default-flatpaks","notify":true,"system":{"repo-url":"https://dl.flathub.org/repo/flathub.flatpakrepo","repo-name":"flathub","install":null,"remove":null},"user":{"repo-url":"https://dl.flathub.org/repo/flathub.flatpakrepo","repo-name":"flathub"}}'

COPY --from=stage-files /usr /usr

RUN ostree container commit