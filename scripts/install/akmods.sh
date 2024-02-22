#!/bin/bash

sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

rpm-ostree install \
  /tmp/rpms/kmods/*xpadneo*.rpm \
  /tmp/rpms/kmods/*xone*.rpm \
  /tmp/rpms/kmods/*openrazer*.rpm \
  /tmp/rpms/kmods/*v4l2loopback*.rpm \
  /tmp/rpms/kmods/*wl*.rpm

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo
