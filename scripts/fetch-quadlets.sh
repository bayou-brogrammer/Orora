#!/bin/bash

# Make Directory
mkdir -p /usr/etc/containers/systemd/users

# orora-cli
wget --output-document="/usr/etc/containers/systemd/users/orora-cli.container" --quiet https://raw.githubusercontent.com/bayou-brogrammer/orora-toolboxes/main/quadlets/orora-cli/orora-cli.container
cat /usr/share/ublue-os/orora-cli/ptyxis-integration >>/usr/etc/containers/systemd/users/orora-cli.container
printf "\n\n[Install]\nWantedBy=orora-cli.target" >>/usr/etc/containers/systemd/users/orora-cli.container
sed -i '/AutoUpdate.*/ s/^#*/#/' /usr/etc/containers/systemd/users/orora-cli.container
sed -i 's/ContainerName=orora/ContainerName=orora-cli/' /usr/etc/containers/systemd/users/orora-cli.container

# wolfi-toolbox
wget --output-document="/usr/etc/containers/systemd/users/wolfi-toolbox.container" --quiet https://raw.githubusercontent.com/bayou-brogrammer/toolboxes/main/quadlets/wolfi-toolbox/wolfi-distrobox-quadlet.container
cat /usr/share/ublue-os/orora-cli/ptyxis-integration >>/usr/etc/containers/systemd/users/wolfi-toolbox.container
printf "\n\n[Install]\nWantedBy=wolfi-toolbox.target" >>/usr/etc/containers/systemd/users/wolfi-toolbox.container
sed -i '/AutoUpdate.*/ s/^#*/#/' /usr/etc/containers/systemd/users/wolfi-toolbox.container
sed -i 's/ContainerName=wolfi-quadlet/ContainerName=wolfi-toolbox/' /usr/etc/containers/systemd/users/wolfi-toolbox.container

# wolfi-dx-toolbox
wget --output-document="/usr/etc/containers/systemd/users/wolfi-dx-toolbox.container" --quiet https://raw.githubusercontent.com/bayou-brogrammer/orora-toolboxes/main/quadlets/wolfi-toolbox/wolfi-dx-distrobox-quadlet.container
cat /usr/share/ublue-os/orora-cli/ptyxis-integration >>/usr/etc/containers/systemd/users/wolfi-dx-toolbox.container
printf "\n\n[Install]\nWantedBy=wolfi-dx-toolbox.target" >>/usr/etc/containers/systemd/users/wolfi-dx-toolbox.container
sed -i '/AutoUpdate.*/ s/^#*/#/' /usr/etc/containers/systemd/users/wolfi-dx-toolbox.container
sed -i 's/ContainerName=wolfi-quadlet/ContainerName=wolfi-dx-toolbox/' /usr/etc/containers/systemd/users/wolfi-dx-toolbox.container

# Make systemd targets and restart services for topgrade
mkdir -p /usr/lib/systemd/user
mkdir -p /usr/share/ublue-os/orora-cli
QUADLET_TARGETS=(
  "orora-cli"
  "wolfi-toolbox"
  "wolfi-dx-toolbox"
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
