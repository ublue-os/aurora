ARG BASE_IMAGE_NAME="kinoite"
ARG FEDORA_MAJOR_VERSION="41"
ARG SOURCE_IMAGE="${BASE_IMAGE_NAME}-main"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG COMMON_IMAGE="ghcr.io/get-aurora-dev/common"
ARG COMMON_IMAGE_SHA=""

FROM ${COMMON_IMAGE}@${COMMON_IMAGE_SHA} AS common

FROM scratch AS ctx
COPY /system_files /system_files
COPY /build_files /build_files
COPY /iso_files /iso_files
COPY /just /just
COPY /flatpaks /flatpaks
COPY /brew /brew
COPY /logos /logos
# TODO: verify this with cosign on build
COPY --from=ghcr.io/get-aurora-dev/common:latest@sha256:f453d227cf908b8c4d0c65d7a843226736ea49cfa7e36875801346771282024d /wallpapers /system_files/shared

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

# Build, cleanup, lint.
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=secret,id=GITHUB_TOKEN \
    /ctx/build_files/shared/build.sh

RUN bootc container lint
