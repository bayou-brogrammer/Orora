# just for local development

set shell := ["bash", "-uc"]

IMAGE_NAME  := "orora-cli"

default:
  just --list

setup-registry:
  #!/usr/bin/bash
  grep -Eq "registry.dev.local" /etc/hosts || \
    echo -e "\n# Container registry\n127.0.0.1 registry.dev.local" | sudo tee -a /etc/hosts

  if ! [ -f "/etc/containers/registries.conf.d/ublue-dev.conf" ]; then
    sudo touch "/etc/containers/registries.conf.d/ublue-dev.conf"
    echo '\n[[registry]]\nlocation = "registry.dev.local:5000"\ninsecure = true' | sudo tee -a /etc/containers/registries.conf.d/ublue-dev.conf
  fi

  podman container exists registry.dev.local || podman run -d --name registry.dev.local -p 5000:5000 docker.io/library/registry:latest

# ================================
# Building
# ================================

build *FLAGS='':
  buildah bud -t {{IMAGE_NAME}}:latest {{FLAGS}} --layers -v /var/cache/rpm-ostree:/var/cache/rpm-ostree:O
build-no-cache:
	just build --no-cache

build-dev *FLAGS='':
  buildah bud {{FLAGS}} -t registry.dev.local:5000/{{IMAGE_NAME}}:dev --layers -v /var/cache/rpm-ostree:/var/cache/rpm-ostree:O
  buildah push --tls-verify=false registry.dev.local:5000/{{IMAGE_NAME}}:dev

# ================================
# DistroBox
# ================================

create-container:
  distrobox create -i registry.dev.local:5000/{{IMAGE_NAME}}:dev -n {{IMAGE_NAME}}

construct:
  just teardown
  just create-container
  distrobox-enter {{IMAGE_NAME}}

teardown :
  distrobox-rm -f {{IMAGE_NAME}}