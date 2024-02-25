# syntax=docker/dockerfile:labs

ARG IMAGE_NAME="orora"
ARG IMAGE_FLAVOR="asus"
ARG IMAGE_REGISTRY="ghcr.io"
ARG FEDORA_MAJOR_VERSION="39"
ARG BASE_IMAGE_NAME="silverblue"
ARG IMAGE_VENDOR="bayou-brogrammer"

# ============================================================================================== #
# Files
# ============================================================================================== #

FROM scratch as stage-files

COPY --from=docker.io/mikefarah/yq:latest /usr/bin/yq /usr/bin/yq
COPY --from=gcr.io/projectsigstore/cosign:latest /ko-app/cosign /usr/bin/cosign

# Copy atuin from bluefin-cli
COPY --from=ghcr.io/ublue-os/bluefin-cli /usr/bin/atuin /usr/bin/atuin
COPY --from=ghcr.io/ublue-os/bluefin-cli /usr/share/bash-prexec /usr/share/bash-prexec

COPY --from=cgr.dev/chainguard/ko:latest /usr/bin/ko /usr/bin/ko
COPY --from=cgr.dev/chainguard/dive:latest /usr/bin/dive /usr/bin/dive
COPY --from=cgr.dev/chainguard/flux:latest /usr/bin/flux /usr/bin/flux
COPY --from=cgr.dev/chainguard/helm:latest /usr/bin/helm /usr/bin/helm
COPY --from=cgr.dev/chainguard/minio-client:latest /usr/bin/mc /usr/bin/mc
COPY --from=cgr.dev/chainguard/kubectl:latest /usr/bin/kubectl /usr/bin/kubectl

COPY just /tmp/just
COPY scripts /tmp/scripts
COPY packages.json /tmp/packages.json
COPY system_files/shared system_files/${BASE_IMAGE_NAME} /

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

FROM ghcr.io/ublue-os/silverblue-asus:latest

LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A starting point"
LABEL io.artifacthub.package.readme-url=https://raw.githubusercontent.com/blue-build/cli/main/README.md

ARG IMAGE_NAME
ARG IMAGE_FLAVOR
ARG IMAGE_VENDOR
ARG BASE_IMAGE_NAME
ARG FEDORA_MAJOR_VERSION
ARG IMAGE_REGISTRY="localhost"
ARG RECIPE="./config/recipe.yml"
ARG CONFIG_DIRECTORY="/tmp/config"

COPY --from=stage-files /tmp /tmp
COPY --from=stage-files /usr/bin /usr/bin
COPY --from=stage-files /etc/yum.repos.d /etc/yum.repos.d

RUN \
  mkdir -p /etc/yum.repos.d && \
  # Warp
  wget -N --show-progress https://app.warp.dev/download?package=rpm -O /tmp/warp.rpm && \
  # Tailscale
  wget -N --show-progress https://pkgs.tailscale.com/stable/fedora/tailscale.repo -O /etc/yum.repos.d/tailscale.repo && \
  # Docker Compose
  wget -N --show-progress https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -O /tmp/docker-compose && \
  # Asus Linux
  wget -N --show-progress https://copr.fedorainfracloud.org/coprs/lukenukem/asus-linux/repo/fedora-${FEDORA_MAJOR_VERSION}/lukenukem-asus-linux-fedora-${FEDORA_MAJOR_VERSION}.repo -O /etc/yum.repos.d/_copr_lukenukem-asus-linux.repo && \
  # Pyxis
  wget -N --show-progress https://copr.fedorainfracloud.org/coprs/kylegospo/prompt/repo/fedora-${FEDORA_MAJOR_VERSION}/kylegospo-prompt-fedora-${FEDORA_MAJOR_VERSION}.repo?arch=x86_64 -O /etc/yum.repos.d/_copr_kylegospo-prompt.repo && \
  wget -N --show-progress https://copr.fedorainfracloud.org/coprs/kylegospo/gnome-vrr/repo/fedora-"${FEDORA_MAJOR_VERSION}"/kylegospo-gnome-vrr-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo && \
  # Nerd Fonts
  wget -N --show-progress https://copr.fedorainfracloud.org/coprs/che/nerd-fonts/repo/fedora-"${FEDORA_MAJOR_VERSION}"/che-nerd-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/_copr_che-nerd-fonts-"${FEDORA_MAJOR_VERSION}".repo && \
  # DX Groups
  wget -N --show-progress https://copr.fedorainfracloud.org/coprs/ganto/lxc4/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
  wget -N --show-progress https://copr.fedorainfracloud.org/coprs/karmab/kcli/repo/fedora-"${FEDORA_MAJOR_VERSION}"/karmab-kcli-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/karmab-kcli-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
  wget -N --show-progress https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-"${FEDORA_MAJOR_VERSION}"/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
  wget -N --show-progress https://copr.fedorainfracloud.org/coprs/atim/ubuntu-fonts/repo/fedora-"${FEDORA_MAJOR_VERSION}"/atim-ubuntu-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/atim-ubuntu-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo

RUN \
  --mount=type=bind,from=stage-akmods-asus,src=/rpms,dst=/tmp/rpms,rw \
  # --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=cache,dst=/var/lib/rpm-ostree,id=rpm-ostree-lib-orora-latest,sharing=locked \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  source /tmp/scripts/exports.sh && \
  # Setup firmware and asusctl for ASUS devices
  /tmp/scripts/install/firmware.sh && \
  # AKMods Section
  /tmp/scripts/install/akmods.sh

# Apply IP Forwarding before installing Docker to prevent messing with LXC networking
RUN sysctl -p

# Install all packages and software
RUN \
  --mount=type=cache,dst=/var/lib/rpm-ostree,id=rpm-ostree-lib-orora-latest,sharing=locked \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  /tmp/scripts/install/packages.sh && \
  /tmp/scripts/install/packages.sh && \
  /tmp/scripts/install/software.sh && \
  /tmp/scripts/generate-image-info.sh && \
  /tmp/scripts/fetch-quadlets.sh

COPY --from=stage-files / /

# Set up services
RUN \
  # BASE
  systemctl enable tuned.service && \
  systemctl enable ublue-update.timer && \
  systemctl enable tailscaled.service && \
  systemctl enable dconf-update.service && \
  systemctl enable ublue-system-setup.service && \
  systemctl enable rpm-ostree-countme.service && \
  systemctl enable ublue-system-flatpak-manager.service && \
  systemctl --global enable ublue-user-setup.service && \
  systemctl --global enable ublue-user-flatpak-manager.service && \
  # DX
  systemctl enable docker.socket && \
  systemctl enable podman.socket && \
  systemctl enable orora-dx-groups.service && \
  systemctl enable swtpm-workaround.service && \
  systemctl disable pmie.service && \
  systemctl disable pmlogger.service

RUN \
  fc-cache -f /usr/share/fonts/inter && \
  fc-cache -f /usr/share/fonts/ubuntu && \
  find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just && \
  echo "Hidden=true" >> /usr/share/applications/fish.desktop && \
  echo "Hidden=true" >> /usr/share/applications/htop.desktop && \
  echo "Hidden=true" >> /usr/share/applications/nvtop.desktop && \
  echo "Hidden=true" >> /usr/share/applications/gnome-system-monitor.desktop && \
  sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
  sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf && \
  sed -i '/^PRETTY_NAME/s/Silverblue/Orora/' /usr/lib/os-release

# WORKAROUNDS
RUN /tmp/scripts/workarounds.sh

# Cleanup and Commit
RUN rm -rf /tmp/* /var/* && \
  rm -f /etc/yum.repos.d/charm.repo && \
  rm -f /etc/yum.repos.d/vscode.repo && \
  rm -f /etc/yum.repos.d/docker-ce.repo && \
  rm -f /etc/yum.repos.d/tailscale.repo && \
  rm -f /etc/yum.repos.d/fedora-cisco-openh264.repo && \
  rm -f /etc/yum.repos.d/_copr_kylegospo-prompt.repo && \
  rm -f /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo && \
  rm -f /etc/yum.repos.d/ganto-lxc4-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
  rm -f /etc/yum.repos.d/karmab-kcli-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
  rm -f /etc/yum.repos.d/_copr_che-nerd-fonts-"${FEDORA_MAJOR_VERSION}".repo && \
  rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo && \
  rm -f /etc/yum.repos.d/ublue-os-staging-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
  rm -f /etc/yum.repos.d/atim-ubuntu-fonts-fedora-"${FEDORA_MAJOR_VERSION}".repo && \
  mkdir -p /var/tmp && \
  chmod -R 1777 /var/tmp && \
  ostree container commit
