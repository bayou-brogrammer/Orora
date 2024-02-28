
# This stage is responsible for holding onto
# your config without copying it directly into
# the final image
FROM scratch as stage-config
COPY ./config /config

# Copy modules
# The default modules are inside blue-build/modules
# Custom modules overwrite defaults
FROM scratch as stage-modules
COPY --from=ghcr.io/blue-build/modules:latest /modules /modules
COPY ./modules /modules
FROM scratch as stage-akmods-asus
COPY --from=ghcr.io/ublue-os/akmods:asus-39 /rpms /rpms

# This stage is responsible for holding onto
# exports like the exports.sh
FROM docker.io/alpine as stage-exports
RUN printf "#!/usr/bin/env bash\n\nget_yaml_array() { \n  readarray -t \"\$1\" < <(echo \"\$3\" | yq -I=0 \"\$2\")\n} \n\nexport -f get_yaml_array\nexport OS_VERSION=\$(grep -Po '(?<=VERSION_ID=)\d+' /usr/lib/os-release)" >> /exports.sh && chmod +x /exports.sh

FROM ghcr.io/ublue-os/bluefin-dx-asus:latest

LABEL org.blue-build.build-id="03661d44-37cb-4e64-b813-ae234585baa5"
LABEL org.opencontainers.image.title="orora"
LABEL org.opencontainers.image.description="This is my personal OS image."
LABEL io.artifacthub.package.readme-url=https://raw.githubusercontent.com/blue-build/cli/main/README.md

ARG RECIPE=./config/recipe.yml
ARG IMAGE_REGISTRY=localhost
COPY cosign.pub /usr/share/ublue-os/cosign.pub

ARG CONFIG_DIRECTORY="/tmp/config"
ARG IMAGE_NAME="orora"
ARG BASE_IMAGE="ghcr.io/ublue-os/bluefin-dx-asus"

COPY --from=gcr.io/projectsigstore/cosign /ko-app/cosign /usr/bin/cosign
COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq
COPY --from=ghcr.io/blue-build/cli:latest-installer /out/bluebuild /usr/bin/bluebuild
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/script/script.sh \
  && source /tmp/exports.sh && /tmp/modules/script/script.sh '{"type":"script","scripts":["generate-image-info.sh"]}' \
  && ostree container commit
COPY ./system_files /
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-akmods-asus,src=/rpms,dst=/tmp/rpms,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/akmods/akmods.sh \
  && source /tmp/exports.sh && /tmp/modules/akmods/akmods.sh '{"type":"akmods","base":"asus","install":["ryzen-smu","zenergy"]}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/rpm-ostree/rpm-ostree.sh \
  && source /tmp/exports.sh && /tmp/modules/rpm-ostree/rpm-ostree.sh '{"type":"rpm-ostree","repos":null,"install":null,"remove":null}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/bling/bling.sh \
  && source /tmp/exports.sh && /tmp/modules/bling/bling.sh '{"type":"bling","install":["flatpaksync"]}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/default-flatpaks/default-flatpaks.sh \
  && source /tmp/exports.sh && /tmp/modules/default-flatpaks/default-flatpaks.sh '{"type":"default-flatpaks","notify":true,"system":{"install":null,"remove":null}}' \
  && ostree container commit
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/var \
  --mount=type=bind,from=stage-config,src=/config,dst=/tmp/config,rw \
  --mount=type=bind,from=stage-modules,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=stage-exports,src=/exports.sh,dst=/tmp/exports.sh \
  --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-orora-latest,sharing=locked \
  chmod +x /tmp/modules/signing/signing.sh \
  && source /tmp/exports.sh && /tmp/modules/signing/signing.sh '{"type":"signing"}' \
  && ostree container commit

# Added in case a user adds something else using the
# 'containerfile' module
RUN rm -fr /tmp/* /var/* && ostree container commit