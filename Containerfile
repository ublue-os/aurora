ARG BASE_IMAGE_ORG="${BASE_IMAGE_ORG}:-quay.io/fedora-ostree-desktops"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}:-kinoite"
ARG BASE_IMAGE="${BASE_IMAGE_ORG}/${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}:-43"
ARG COMMON_IMAGE="${COMMON_IMAGE}:-ghcr.io/get-aurora-dev/common:latest"
ARG COMMON_IMAGE_SHA=""
ARG BREW_IMAGE="${BREW_IMAGE}:-ghcr.io/ublue-os/brew:latest"
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
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION=""
ARG IMAGE_NAME="aurora"
ARG IMAGE_VENDOR="ublue-os"
ARG KERNEL=""
ARG SHA_HEAD_SHORT="dedbeef"
ARG UBLUE_IMAGE_TAG="stable"
ARG VERSION=""
ARG IMAGE_FLAVOR=""

# so ghcurl wrapper is available to all later RUNs
ENV PATH="/tmp/scripts/helpers:${PATH}"

# Copy files from common/from system_files
# Install Packages, miscellaneous things that need a network
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/var \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=secret,id=GITHUB_TOKEN \
    /ctx/build_files/shared/build.sh && \
    /ctx/build_files/base/01-packages.sh && \
    /ctx/build_files/base/02-install-kernel-akmods.sh && \
    /ctx/build_files/base/03-fetch.sh

# Everything that can be done offline after things are in place should be done here
RUN --network=none \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/run \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    /ctx/build_files/base/16-override-install.sh && \
    /ctx/build_files/base/17-cleanup.sh && \
    /ctx/build_files/base/18-image-info.sh && \
    /ctx/build_files/base/19-initramfs.sh && \
    /ctx/build_files/shared/validate-repos.sh && \
    /ctx/build_files/shared/clean-stage.sh && \
    /ctx/build_files/base/20-tests.sh

# Needs to be here to make the main image build strict (no /opt there)
# This is for downstream images/stuff like k0s
RUN rm -rf /opt && ln -s /var/opt /opt

CMD ["/sbin/init"]

RUN bootc container lint
