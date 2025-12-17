#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -oue pipefail

KERNEL_VERSION=$(rpm -q --queryformat="%{evr}.%{arch}" kernel-core)

# Ensure Initramfs is generated
export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible -v --add "ostree fido2 tpm2-tss pkcs11 pcsc" -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 "/lib/modules/${KERNEL_VERSION}/initramfs.img"

echo "::endgroup::"
