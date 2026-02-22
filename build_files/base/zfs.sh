#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# ZFS is only installed on coreos-stable

ZFS_RPMS=(
    /tmp/rpms/zfs/kmods/zfs/kmod-zfs-"${KERNEL}"-*.rpm
    /tmp/rpms/zfs/kmods/zfs/libnvpair[0-9]-*.rpm
    /tmp/rpms/zfs/kmods/zfs/libuutil[0-9]-*.rpm
    /tmp/rpms/zfs/kmods/zfs/libzfs[0-9]-*.rpm
    /tmp/rpms/zfs/kmods/zfs/libzpool[0-9]-*.rpm
    /tmp/rpms/zfs/kmods/zfs/python3-pyzfs-*.rpm
    /tmp/rpms/zfs/kmods/zfs/zfs-*.rpm
    pv
)

dnf -y install "${ZFS_RPMS[@]}"

# Depmod and autoload
depmod -a -v "${KERNEL}"
echo "zfs" >/usr/lib/modules-load.d/zfs.conf

echo "::endgroup::"
