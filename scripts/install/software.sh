#!/bin/bash

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

ls -la /tmp

# rpm-ostree install \
# /tmp/warp.rpm
