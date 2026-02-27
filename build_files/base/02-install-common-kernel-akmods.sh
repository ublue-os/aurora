#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Remove Existing Kernel
for pkg in kernel kernel{-core,-modules,-modules-core,-modules-extra,-tools-libs,-tools}; do
    rpm --erase "${pkg}" --nodeps
done

# cleanup leftovers that are not covered by kernel-* packages for some reason
rm -rf /usr/lib/modules

# Install Kernel
dnf5 -y install \
    /tmp/kernel-rpms/kernel-[0-9]*.rpm \
    /tmp/kernel-rpms/kernel-core-*.rpm \
    /tmp/kernel-rpms/kernel-modules-*.rpm

if [[ "${IMAGE_FLAVOR}" == "dx" ]]; then
  dnf -y install /tmp/kernel-rpms/kernel-devel-*.rpm
fi

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra

dnf -y install /tmp/rpms/{common,kmods}/*xone*.rpm /tmp/rpms/{common,kmods}/*openrazer*.rpm || true

dnf -y install /tmp/rpms/{kmods,common}/*v4l2loopback*.rpm || true

mkdir -p /etc/pki/akmods/certs
ghcurl "https://github.com/ublue-os/akmods/raw/refs/heads/main/certs/public_key.der" --retry 3 -Lo /etc/pki/akmods/certs/akmods-ublue.der

# OpenRazer from hardware:razer repo (not a COPR)
dnf -y config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
dnf -y install openrazer-daemon || true
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/hardware:razer.repo

echo "::endgroup::"
