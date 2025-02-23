#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Add Staging repo
dnf5 -y copr enable ublue-os/staging

# Add Packages repo
dnf5 -y copr enable ublue-os/packages

# Add Switcheroo Repo
dnf5 -y copr enable sentry/switcheroo-control_discrete

# Add OpenRazer repo
dnf5 -y config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo

# Enable Nerd fonts repo
dnf5 -y copr enable che/nerd-fonts

# Enable repo for scx-scheds
dnf5 -y copr enable bieszczaders/kernel-cachyos-addons

# Enable fw-fanctrl repo
dnf5 -y copr enable tulilirockz/fw-fanctrl


echo "::endgroup::"
