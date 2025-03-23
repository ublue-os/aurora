#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Add Staging repo
dnf5 -y copr enable ublue-os/staging

# Add Packages repo
dnf5 -y copr enable ublue-os/packages

# Add OpenRazer repo
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
    echo "not enabling the openrazer repo for beta"
else
    dnf5 -y config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
fi

# Enable repo for scx-scheds
dnf5 -y copr enable bieszczaders/kernel-cachyos-addons

# Enable Terra repo
dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras}

echo "::endgroup::"
