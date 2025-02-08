#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Add Staging repo
dnf5 -y copr enable ublue-os/staging

# Add Ubuntu Fonts
dnf5 -y copr enable atim/ubuntu-fonts

# Add Switcheroo Repo
dnf5 -y copr enable sentry/switcheroo-control_discrete

# Add OpenRazer repo
curl -Lo /etc/yum.repos.d/hardware:razer.repo https://openrazer.github.io/hardware:razer.repo

# Enable Nerd fonts repo
dnf5 -y copr enable che/nerd-fonts

# Enable repo for scx-scheds
dnf5 -y copr enable bieszczaders/kernel-cachyos-addons

# Enable fw-fanctrl repo
dnf5 -y copr enable tulilirockz/fw-fanctrl


echo "::endgroup::"
