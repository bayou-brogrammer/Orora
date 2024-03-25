#!/bin/bash

set -euo pipefail

# Mullvad
# mkdir -p /tmp/mullvad
# curl -Lo /tmp/mullvad/mullvad-vpn.rpm https://mullvad.net/en/download/app/rpm/latest --max-redirs 1
# rpm-ostree install /tmp/mullvad/mullvad-vpn.rpm

# mkdir -p /tmp/warp
# curl -Lo /tmp/warp/warp.rpm https://app.warp.dev/download?package=rpm --max-redirs 1
# rpm-ostree install -y /tmp/warp/warp.rpm
# wget -c https://app.warp.dev/download?package=rpm -O /tmp/warp/warp.rpm &&
# 	rpm-ostree install -y /tmp/warp.rpm
