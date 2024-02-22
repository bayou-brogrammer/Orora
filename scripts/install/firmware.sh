#!/bin/bash

wget https://copr.fedorainfracloud.org/coprs/lukenukem/asus-linux/repo/fedora-"$(rpm -E %fedora)"/lukenukem-asus-linux-fedora-"$(rpm -E %fedora)".repo -O /etc/yum.repos.d/_copr_lukenukem-asus-linux.repo

rpm-ostree install \
  asusctl \
  asusctl-rog-gui

git clone https://gitlab.com/asus-linux/firmware.git --depth 1 /tmp/asus-firmware &&
  cp -rf /tmp/asus-firmware/* /usr/lib/firmware/ &&
  rm -rf /tmp/asus-firmware
