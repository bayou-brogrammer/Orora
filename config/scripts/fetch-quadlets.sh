#!/bin/bash

set -euo pipefail

CONTAINER_PATH="/usr/etc/containers/systemd/users"

# Make Directory
mkdir -p "${CONTAINER_PATH}"

QUADLET_TARGETS=(
  "orora-cli"
)

# orora-cli
wget --output-document="${CONTAINER_PATH}/orora-cli.container" --quiet https://raw.githubusercontent.com/bayou-brogrammer/orora-toolboxes/main/quadlets/orora-cli/orora-cli.container
cat /usr/share/ublue-os/orora-cli/ptyxis-integration >>${CONTAINER_PATH}/orora-cli.container
printf "\n\n[Install]\nWantedBy=orora-cli.target" >>${CONTAINER_PATH}/orora-cli.container
sed -i '/AutoUpdate.*/ s/^#*/#/' ${CONTAINER_PATH}/orora-cli.container
sed -i 's/ContainerName=orora/ContainerName=orora-cli/' ${CONTAINER_PATH}/orora-cli.container

# Make systemd targets and restart services for topgrade
mkdir -p /usr/lib/systemd/user
mkdir -p /usr/share/ublue-os/orora-cli

QUADLET_TARGETS=(
  "orora-cli"
)

for i in "${QUADLET_TARGETS[@]}"; do
  cat >"/usr/lib/systemd/user/${i}.target" <<EOF
[Unit]
Description=${i}"target for ${i} quadlet

[Install]
WantedBy=default.target
EOF
  cat >"/usr/lib/systemd/user/${i}-update.service" <<EOF
[Unit]
Description=Restart ${i}.service to rebuild container

[Service]
Type=oneshot
ExecStart=-/usr/bin/podman pull ghcr.io/ublue-os/${i}:latest
ExecStart=-/usr/bin/systemctl --user restart ${i}.service
EOF

  cat >"/usr/share/ublue-os/orora-cli/${i}.sh" <<EOF
#!/bin/sh 
 
if test -n "\$PS1" && test ! -f "/run/.containerenv" && test ! -f "/run/user/\${UID}/container-entry" && test \$(podman ps --all --filter name=$i | grep -q " $i\$") ; then  
    touch "/run/user/\${UID}/container-entry"  
    exec /usr/bin/distrobox-enter $i 
fi
EOF
done
