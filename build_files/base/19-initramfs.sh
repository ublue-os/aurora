#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# https://github.com/ublue-os/aurora/issues/2568
TMP_OS_RELEASE=$(mktemp --tmpdir 'os-release-XXXXXXXXXX')
cp /usr/lib/os-release "${TMP_OS_RELEASE}"
sed -Ei -e '/^((OSTREE_)?(IMAGE_)?VERSION|PRETTY_NAME|BUILD_ID)=/d' /usr/lib/os-release

KERNEL_VERSION=$(rpm -q --queryformat="%{evr}.%{arch}" kernel-core)

DRACUT_NO_XATTR=1 /usr/bin/dracut \
  --no-hostonly \
  --kver "${KERNEL_VERSION}" \
  --reproducible \
  --verbose \
  --force \
  "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"

cp "${TMP_OS_RELEASE}" /usr/lib/os-release
rm "${TMP_OS_RELEASE}"

chmod 0600 "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"

echo "::endgroup::"
