# This stage is responsible for holding onto
# your config without copying it directly into
# the final image
FROM scratch as stage-config
COPY ./config /config

# Copy modules
# The default modules are inside blue-build/modules
# Custom modules overwrite defaults
FROM scratch as stage-modules
COPY --from=ghcr.io/blue-build/modules:latest /modules /modules
COPY ./modules /modules

# Bins to install
# These are basic tools that are added to all images.
# Generally used for the build process. We use a multi
# stage process so that adding the bins into the image
# can be added to the ostree commits.
FROM scratch as stage-bins

COPY --from=gcr.io/projectsigstore/cosign /ko-app/cosign /bins/cosign
COPY --from=docker.io/mikefarah/yq /usr/bin/yq /bins/yq
COPY --from=ghcr.io/blue-build/cli:latest-installer /out/bluebuild /bins/bluebuild

# Keys for pre-verified images
# Used to copy the keys into the final image
# and perform an ostree commit.
#
# Currently only holds the current image's
# public key.
FROM scratch as stage-keys
COPY cosign.pub /keys/orora.pub

FROM ghcr.io/ublue-os/bluefin-dx-asus:latest

LABEL org.blue-build.build-id="36166856-0c89-4d60-af39-7d8c6301077d"
LABEL org.opencontainers.image.title="orora"
LABEL org.opencontainers.image.description="This is my personal OS image."
LABEL io.artifacthub.package.readme-url=https://raw.githubusercontent.com/blue-build/cli/main/README.md

ARG RECIPE=./config/recipe.yml
ARG IMAGE_REGISTRY=localhost

ARG CONFIG_DIRECTORY="/tmp/config"
ARG MODULE_DIRECTORY="/tmp/modules"
ARG IMAGE_NAME="orora"
ARG BASE_IMAGE="ghcr.io/ublue-os/bluefin-dx-asus"

# Key RUN
RUN --mount=type=bind,from=stage-keys,src=/keys,dst=/tmp/keys \
  mkdir -p /usr/etc/pki/containers/ \
  && cp /tmp/keys/* /usr/etc/pki/containers/ \
  && ostree container commit

# Bin RUN
RUN --mount=type=bind,from=stage-bins,src=/bins,dst=/tmp/bins \
  mkdir -p /usr/bin/ \
  && cp /tmp/bins/* /usr/bin/ \
  && ostree container commit

# Module RUNs

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR}"
ARG AKMODS_FLAVOR="${AKMODS_FLAVOR}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

COPY ./system_files/base /
COPY ./system_files/river /

# Copy Bluefin CLI packages
COPY --from=ghcr.io/bayou-brogrammer/orora-cli /usr/bin/atuin /usr/bin/atuin
COPY --from=ghcr.io/bayou-brogrammer/orora-cli /usr/share/bash-prexec /usr/share/bash-prexec

RUN \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=ghcr.io/blue-build/cli:exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  echo "========== Start Script module ==========" \
  && chmod +x /tmp/modules/script/script.sh \
  && source /tmp/exports.sh \
  && /tmp/modules/script/script.sh '{"type":"script","scripts":["base/generate-image-info.sh"]}' \
  && echo "========== End Script module ==========" \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=ghcr.io/blue-build/cli:exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  echo "========== Start Rpm-ostree module ==========" \
  && chmod +x /tmp/modules/rpm-ostree/rpm-ostree.sh \
  && source /tmp/exports.sh \
  && /tmp/modules/rpm-ostree/rpm-ostree.sh '{"type":"rpm-ostree","repos":["https://copr.fedorainfracloud.org/coprs/varlad/helix/repo/fedora-%OS_VERSION%/varlad-helix-fedora-%OS_VERSION%.repo","https://copr.fedorainfracloud.org/coprs/agriffis/neovim-nightly/repo/fedora-%OS_VERSION%/agriffis-neovim-nightly-fedora-%OS_VERSION%.repo"],"install":["helix","neovim","rofi-wayland","xorg-x11-server-Xwayland","polkit","lxpolkit","xdg-user-dirs","dbus-tools","dbus-daemon","wl-clipboard","gnome-keyring","pavucontrol","playerctl","qt5-qtwayland","qt6-qtwayland","vulkan-validation-layers","vulkan-tools","google-noto-emoji-fonts","gnome-disk-utility","wireplumber","pipewire","pamixer","network-manager-applet","NetworkManager-openvpn","NetworkManager-openconnect","bluez","bluez-tools","blueman","thunar","thunar-archive-plugin","thunar-volman","xarchiver","imv","p7zip","unrar-free","slurp","grim","wlr-randr","wlsunset","grimshot","brightnessctl","swaylock","swayidle","kanshi","foot","dunst","mpv","adwaita-qt5","fontawesome-fonts-all","gnome-themes-extra","gnome-icon-theme","paper-icon-theme","breeze-icon-theme","papirus-icon-theme"]}' \
  && echo "========== End Rpm-ostree module ==========" \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=ghcr.io/blue-build/cli:exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  echo "========== Start Bling module ==========" \
  && chmod +x /tmp/modules/bling/bling.sh \
  && source /tmp/exports.sh \
  && /tmp/modules/bling/bling.sh '{"type":"bling","install":["1password","flatpaksync"]}' \
  && echo "========== End Bling module ==========" \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=ghcr.io/blue-build/cli:exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  echo "========== Start Rpm-ostree module ==========" \
  && chmod +x /tmp/modules/rpm-ostree/rpm-ostree.sh \
  && source /tmp/exports.sh \
  && /tmp/modules/rpm-ostree/rpm-ostree.sh '{"type":"rpm-ostree","install":["sddm","sddm-themes","qt5-qtgraphicaleffects","qt5-qtquickcontrols2","qt5-qtsvg"]}' \
  && echo "========== End Rpm-ostree module ==========" \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=ghcr.io/blue-build/cli:exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  echo "========== Start Rpm-ostree module ==========" \
  && chmod +x /tmp/modules/rpm-ostree/rpm-ostree.sh \
  && source /tmp/exports.sh \
  && /tmp/modules/rpm-ostree/rpm-ostree.sh '{"type":"rpm-ostree","install":["river","waybar","xdg-desktop-portal-wlr","xdg-desktop-portal-gtk"]}' \
  && echo "========== End Rpm-ostree module ==========" \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=ghcr.io/blue-build/cli:exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  echo "========== Start Script module ==========" \
  && chmod +x /tmp/modules/script/script.sh \
  && source /tmp/exports.sh \
  && /tmp/modules/script/script.sh '{"type":"script","scripts":["base/software.sh","base/just.sh","sddm/settheming.sh","sddm/setsddmtheming.sh"]}' \
  && echo "========== End Script module ==========" \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=ghcr.io/blue-build/cli:exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  echo "========== Start Signing module ==========" \
  && chmod +x /tmp/modules/signing/signing.sh \
  && source /tmp/exports.sh \
  && /tmp/modules/signing/signing.sh '{"type":"signing"}' \
  && echo "========== End Signing module ==========" \
  && ostree container commit

