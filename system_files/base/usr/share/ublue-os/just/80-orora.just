# Connect home using WireGuard
connect-home:
    #!/bin/bash
    echo "Connecting to home"
    tailscale up --exit-node fw --operator=$USER --ssh

# Disconnect from home using WireGuard
disconnect-home:
    #!/bin/bash
    echo "Disconnecting from home"
    tailscale down

install-nix:
    #!/bin/bash
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

install-rust:
    #!/bin/bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Configure Orora-CLI Terminal Experience
orora-cli:
    @/usr/libexec/enable-orora-cli.sh

# Update Orora CLI
update-cli:
    #!/bin/bash
    echo "Updating Orora CLI"
    systemctl --user start orora-cli-update.service
