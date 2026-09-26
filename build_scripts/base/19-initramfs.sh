#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

KERNEL_VERSION=$(rpm -q --queryformat="%{evr}.%{arch}" kernel-core)
INITRAMFS="/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"

# https://github.com/ublue-os/aurora/issues/2568
# these strings change with every build
TMP_OS_RELEASE=$(mktemp --tmpdir 'os-release-XXXXXXXXXX')
OS_RELEASE="/usr/lib/os-release"
cp "${OS_RELEASE}" "${TMP_OS_RELEASE}"
sed -Ei -e '/^((OSTREE_)?(IMAGE_)?VERSION|PRETTY_NAME|BUILD_ID)=/d' "${OS_RELEASE}"

DRACUT_NO_XATTR=1 /usr/bin/dracut \
  --no-hostonly \
  --kver "${KERNEL_VERSION}" \
  --reproducible \
  --verbose \
  --force \
  "${INITRAMFS}"

# mv causes permissions to change
cp "${TMP_OS_RELEASE}" "${OS_RELEASE}"
rm "${TMP_OS_RELEASE}"

chmod 0600 "${INITRAMFS}"

# for reproducibility
touch -a -m -d "1970-01-01T00:00:00Z" "${INITRAMFS}"

# for debugging
sha256sum "${INITRAMFS}"

echo "::endgroup::"
