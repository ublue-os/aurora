ARG BASE_IMAGE_NAME="kinoite"
ARG FEDORA_MAJOR_VERSION="43"
ARG SOURCE_IMAGE="${BASE_IMAGE_NAME}"
ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/${SOURCE_IMAGE}"
ARG COMMON_IMAGE="ghcr.io/get-aurora-dev/common:latest"
ARG COMMON_IMAGE_SHA=""
ARG BREW_IMAGE="ghcr.io/ublue-os/brew:latest"
ARG BREW_IMAGE_SHA=""

FROM ${COMMON_IMAGE}@${COMMON_IMAGE_SHA} AS common
FROM ${BREW_IMAGE}@${BREW_IMAGE_SHA} AS brew

FROM scratch AS ctx
COPY /build_files /build_files

# https://github.com/get-aurora-dev/common
COPY --from=common /logos /system_files/shared
COPY --from=common /system_files /system_files
COPY --from=common /wallpapers /system_files/shared

# https://github.com/ublue-os/brew
COPY --from=brew /system_files /system_files/shared

# Overwrite files from common if necessary
COPY /system_files /system_files

## aurora image section
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS base

ARG AKMODS_FLAVOR="coreos-stable"
ARG BASE_IMAGE_NAME="kinoite"
ARG FEDORA_MAJOR_VERSION="41"
ARG IMAGE_NAME="aurora"
ARG IMAGE_VENDOR="ublue-os"
ARG KERNEL="6.14.4-200.fc41.x86_64"
ARG SHA_HEAD_SHORT="dedbeef"
ARG UBLUE_IMAGE_TAG="stable"
ARG VERSION=""
ARG IMAGE_FLAVOR=""

# Prep
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    /ctx/build_files/shared/build.sh

# so ghcurl wrapper is available to all later RUNs
ENV PATH="/tmp/scripts/helpers:${PATH}"

# Generate image-info.json, os-release
RUN --network=none \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/base/00-image-info.sh

# Install Kernel and Akmods
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=secret,id=GITHUB_TOKEN \
    /ctx/build_files/base/03-install-kernel-akmods.sh

# Install Additional Packages
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    /ctx/build_files/base/04-packages.sh

# Wallpapers/Apperance
RUN --network=none \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/base/05-branding.sh

# Install Overrides and Fetch Install
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=secret,id=GITHUB_TOKEN \
    /ctx/build_files/base/06-override-install.sh

# Get Firmare for Framework
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    /ctx/build_files/base/08-firmware.sh

# Beta
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    if [ "${UBLUE_IMAGE_TAG}" == "beta" ] ; then \
      /ctx/build_files/base/10-beta.sh; \
    fi

# Enable systemd services and Remove Items
RUN --network=none \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    /ctx/build_files/base/17-cleanup.sh

RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    /ctx/build_files/base/18-workarounds.sh

# Regenerate initramfs
RUN --network=none \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/base/19-initramfs.sh

# Aurora-DX
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=secret,id=GITHUB_TOKEN \
    if [ "${IMAGE_FLAVOR}" == "dx" ] ; then \
      /ctx/build_files/shared/build-dx.sh; \
    fi

RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=secret,id=GITHUB_TOKEN \
    if [ "${IMAGE_FLAVOR}" == "dx" ] ; then \
      /ctx/build_files/dx/00-dx.sh; \
    fi

RUN --network=none \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/shared/validate-repos.sh

RUN --network=none \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/shared/clean-stage.sh

# Sanity checks
RUN --network=none \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/base/20-tests.sh

RUN --network=none \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    if [ "${IMAGE_FLAVOR}" == "dx" ] ; then \
      /ctx/build_files/dx/10-tests-dx.sh; \
    fi

# Needs to be here to make the main image build strict (no /opt there)
# This is for downstream images/stuff like k0s
RUN rm -rf /opt && ln -s /var/opt /opt

CMD ["/sbin/init"]

RUN bootc container lint
