#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Revert back to upstream defaults
dnf config-manager setopt keepcache=0
dnf versionlock clear

# This comes last because we can't *ever* afford to ship fedora flatpaks on the image
systemctl mask flatpak-add-fedora-repos.service
rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

rm -rf /.gitkeep

find /var/* -maxdepth 0 -type d \! -name cache -exec rm -fr {} \;
rm -rf /tmp/*
mkdir -p /var/tmp

# Needs to be here to make the main image build strict (no /opt there)
# This is for downstream images/stuff like k0s
rm -rf /opt && ln -s /var/opt /opt

echo "::endgroup::"
