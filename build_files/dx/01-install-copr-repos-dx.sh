#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

#incus, lxc

if [[ "${FEDORA_MAJOR_VERSION}" -lt "42" ]]; then
    dnf5 -y copr enable ganto/lxc4
fi

#umoci
dnf5 -y copr enable ganto/umoci

#ublue-os staging
dnf5 -y copr enable ublue-os/staging

#ublue-os packages
dnf5 -y copr enable ublue-os/packages

#karmab-kcli
dnf5 -y copr enable karmab/kcli

# Kvmfr module
dnf5 -y copr enable hikariknight/looking-glass-kvmfr

# Podman-bootc
dnf5 -y copr enable gmaglione/podman-bootc

# Enable Terra repo
dnf5 -y config-manager setopt "terra".enabled=true

echo "::endgroup::"
