#!/bin/bash

set -oue pipefail

rpm-ostree install \
  asusctl \
  asusctl-rog-gui

git clone https://gitlab.com/asus-linux/firmware.git --depth 1 /tmp/asus-firmware &&
  cp -rf /tmp/asus-firmware/* /usr/lib/firmware/ &&
  rm -rf /tmp/asus-firmware
