#!/usr/bin/bash

set -eoux pipefail

echo "::group:: Copy Files"

# Copy ISO list for `install-system-flatpaks`
install -Dm0644 -t /etc/ublue-os/ /ctx/flatpaks/*.list

# We need to remove this package here because lots of files we add from `projectbluefin/common` override the rpm files and they also go away when you do `dnf remove`
# TODO: this can be removed whenever we stop doing FROM ublue-os/kinoite-main
dnf remove -y ublue-os-just ublue-os-signing ublue-os-udev-rules ublue-os-luks

# Copy Files to Container
rsync -rvKl /ctx/system_files/shared/ /

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_files/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl
export PATH="/tmp/scripts/helpers:$PATH"

echo "::endgroup::"

# Generate image-info.json, os-release
/ctx/build_files/base/00-image-info.sh

# Install Kernel and Akmods
/ctx/build_files/base/03-install-kernel-akmods.sh

# Install Additional Packages
/ctx/build_files/base/04-packages.sh

# Wallpapers/Apperance
/ctx/build_files/base/05-branding.sh

# Install Overrides and Fetch Install
/ctx/build_files/base/06-override-install.sh

# Get Firmare for Framework
/ctx/build_files/base/08-firmware.sh

# Beta
# /ctx/build_files/base/10-beta.sh

## late stage changes

# Systemd and Remove Items
/ctx/build_files/base/17-cleanup.sh

# Run workarounds for lf (Likely not needed)
/ctx/build_files/base/18-workarounds.sh

# Regenerate initramfs
/ctx/build_files/base/19-initramfs.sh

if [ "${IMAGE_FLAVOR}" == "dx" ] ; then
  # Now we build DX!
  /ctx/build_files/shared/build-dx.sh
fi

# Validate all repos are disabled before committing
/ctx/build_files/shared/validate-repos.sh

# Set filesystem properties for rechunker
/ctx/build_files/base/20-layer-definitions.sh

# Clean Up
/ctx/build_files/shared/clean-stage.sh

# Simple Tests
/ctx/build_files/base/21-tests.sh
