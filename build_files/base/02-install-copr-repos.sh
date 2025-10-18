#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Add Staging repo
dnf5 -y copr enable ublue-os/staging

# Add Packages repo
dnf5 -y copr enable ublue-os/packages

# Add OpenRazer repo
# not available for f43 yet
if [[ "${UBLUE_IMAGE_TAG}" != "beta" ]]; then
dnf5 -y config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
fi

# Enable Terra repo
dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras}

# Enable sunshine repo
# not yet available for f43
if [[ "${UBLUE_IMAGE_TAG}" != "beta" ]]; then
dnf5 -y copr enable lizardbyte/beta
fi

# Enable ledifs kAirpods repo
dnf5 -y copr enable ledif/kairpods

# TODO: remove me on next flatpak release
dnf5 -y copr enable ublue-os/flatpak-test

echo "::endgroup::"
