#!/bin/bash

set -oue pipefail

sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
wget https://negativo17.org/repos/fedora-multimedia.repo -O /etc/yum.repos.d/negativo17-fedora-multimedia.repo

rpm-ostree install \
  /tmp/rpms/kmods/*openrazer*.rpm \
  /tmp/rpms/kmods/*ryzen-smu*.rpm \
  /tmp/rpms/kmods/*v4l2loopback*.rpm \
  /tmp/rpms/kmods/*wl*.rpm \
  /tmp/rpms/kmods/*xone*.rpm \
  /tmp/rpms/kmods/*xpadneo*.rpm \
  /tmp/rpms/kmods/*zenergy*.rpm

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo
