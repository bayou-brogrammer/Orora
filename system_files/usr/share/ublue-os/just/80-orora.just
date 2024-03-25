# Update Orora CLI
update-cli:
    #!/bin/bash
    echo "Updating Orora CLI"
    systemctl --user start orora-cli-update.service

# Connect home using WireGuard
connect-home:
    #!/bin/bash
    echo "Connecting to home"
    tailscale up --exit-node fw --operator=$USER

# Disconnect from home using WireGuard
disconnect-home:
    #!/bin/bash
    echo "Disconnecting from home"
    tailscale down

install-nix:
    #!/bin/bash
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
