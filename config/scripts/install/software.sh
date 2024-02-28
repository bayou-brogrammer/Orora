#!/bin/bash

set -oue pipefail

# Docker Compose
install -c -m 0755 /tmp/docker-compose /usr/bin

# Pip / Python
pip install --prefix=/usr yafti topgrade

# Starship Shell Prompt
curl -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz" &&
  tar -xzf /tmp/starship.tar.gz -C /tmp &&
  install -c -m 0755 /tmp/starship /usr/bin &&
  echo "eval '$(starship init bash)'" >>/etc/bashrc

# Gnome VRR
rpm-ostree override replace --experimental --from repo=copr:copr.fedorainfracloud.org:kylegospo:gnome-vrr \
  mutter \
  mutter-common \
  gnome-control-center \
  gnome-control-center-filesystem

# Ptyxis
rpm-ostree override replace \
  --experimental \
  --from repo=copr:copr.fedorainfracloud.org:kylegospo:prompt \
  vte291 \
  vte-profile \
  libadwaita &&
  rpm-ostree install \
    ptyxis

# rpm-ostree install /tmp/warp.rpm

rpm-ostree install ublue-update
