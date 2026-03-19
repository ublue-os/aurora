#!/usr/bin/bash

set -eoux pipefail

echo "::group:: Copy Files"

# Speeds up local builds
dnf config-manager setopt keepcache=1

# We need to remove this package here because lots of files we add from `{projectbluefin,get-aurora-dev}/common` override the rpm files
# they go away when you do dnf remove
# Keep *-logos in RPM DB for downstream package installations
# We are not allowed to ship an empty fedora-logos package
dnf -y swap fedora-logos generic-logos
rpm --erase --nodeps --nodb generic-logos

# Copy Files to Container
rsync -rvKl /ctx/system_files/shared/ /

setfattr -n user.component -v "aurora-wallpapers" /usr/share/backgrounds/aurora
setfattr -n user.component -v "aurora-assets" /usr/share/plasma/avatars/{echo,lumina,scope,tina,vincent}.png
setfattr -n user.component -v "aurora-assets" /etc/bazaar
setfattr -n user.component -v "aurora-plasma-theme" /usr/share/plasma/look-and-feel/dev.getaurora.aurora{,light}.desktop
setfattr -n user.component -v "aurora-config" /usr/share/ublue-os
setfattr -n user.component -v "homebrew" /usr/share/homebrew.tar.zst

if [[ "${IMAGE_FLAVOR}" == "dx" ]]; then
  /ctx/build_files/shared/build-dx.sh
fi

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_files/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl

echo "::endgroup::"
