#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Add Staging repo
dnf5 -y copr enable ublue-os/staging

# Add Switcheroo Repo
dnf5 -y copr enable sentry/switcheroo-control_discrete

# Add openrazer repo
curl -Lo /etc/yum.repos.d/hardware:razer.repo https://openrazer.github.io/hardware:razer.repo

# Enable Nerd fonts repo
dnf5 -y copr enable che/nerd-fonts


echo "::endgroup::"
