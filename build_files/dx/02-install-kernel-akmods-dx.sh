#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Fetch AKMODS & Kernel RPMS
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/
# NOTE: kernel-rpms should auto-extract into correct location

# For stable images with coreos kernel always replace the kernel
# kernel-tools is not cached in akmods, so install from repos
# only install kernel-tools on dx
# kernel-headers version that matches coreos doesn't exist, install the ungated version from repos instead
if [ "$AKMODS_FLAVOR" = "coreos-stable" ]; then
  dnf5 -y install /tmp/kernel-rpms/kernel{,-core,-modules,-modules-core,-modules-extra,-devel,-devel,-devel-matched}-"${KERNEL}".rpm kernel-{tools,tools-libs}-"$KERNEL"
fi

# Only touch latest kernel when we need to pin it because of some super bad regression
# so only replace the latest kernel with the one from akmods when the ublue-os/main kernel differs from ublue-os/akmods, so we pin in Aurora/Bluefin but not in main
# we don't cache kernel-tools from the latest fedora so install from repos instead
if [[ "$AKMODS_FLAVOR" = "main" && "$KERNEL" -ne $(rpm -q --queryformat="%{evr}.%{arch}" kernel-core) ]]; then
  dnf5 -y install /tmp/kernel-rpms/kernel{,-core,-modules,-modules-core,-modules-extra,-devel}-"${KERNEL}".rpm kernel-{tools,tools-libs}-"$KERNEL"
fi

# Prevent kernel stuff from upgrading again
dnf5 versionlock add kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}

# Install RPMS
dnf5 -y install /tmp/akmods/kmods/*kvmfr*.rpm

echo "::endgroup::"
