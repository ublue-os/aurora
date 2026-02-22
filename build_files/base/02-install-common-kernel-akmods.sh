#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Remove Existing Kernel
for pkg in kernel kernel{-core,-modules,-modules-core,-modules-extra,-tools-libs,-tools}; do
    rpm --erase $pkg --nodeps
done

# cleanup leftovers that are not covered by kernel-* packages for some reason
rm -rf /usr/lib/modules

# Install Kernel
# TODO: Figure out why akmods cache is pulling in akmods/kernel-devel
dnf5 -y install \
    /tmp/kernel-rpms/kernel-[0-9]*.rpm \
    /tmp/kernel-rpms/kernel-core-*.rpm \
    /tmp/kernel-rpms/kernel-modules-*.rpm \
    /tmp/kernel-rpms/kernel-devel-*.rpm

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra

dnf copr enable -y ublue-os/akmods

# RPMFUSION Dependent AKMODS
dnf -y install /tmp/akmods/kmods/*xone*.rpm /tmp/akmods/kmods/*openrazer*.rpm || true

dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
dnf5 -y install \
    v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm || true
dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release

mkdir -p /etc/pki/akmods/certs
ghcurl "https://github.com/ublue-os/akmods/raw/refs/heads/main/certs/public_key.der" --retry 3 -Lo /etc/pki/akmods/certs/akmods-ublue.der

# OpenRazer from hardware:razer repo (not a COPR)
dnf -y config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
dnf -y install openrazer-daemon || true
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/hardware:razer.repo

echo "::endgroup::"
