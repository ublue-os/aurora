#!/usr/bin/bash

set -eoux pipefail

echo "::group:: ===Install dnf5==="
if [ "${FEDORA_MAJOR_VERSION}" -lt 41 ]; then
    rpm-ostree install --idempotent dnf5 dnf5-plugins
fi

echo "::endgroup::"

echo "::group:: Copy Files"

# Copy ISO list for `install-system-flatpaks`
install -Dm0644 -t /etc/ublue-os/ /ctx/iso_files/*.list

# Copy Files to Container
cp -r /ctx/just /tmp/just
cp /ctx/packages.json /tmp/packages.json
rsync -rvK /ctx/system_files/shared/ /

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_files/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl
export PATH="/tmp/scripts/helpers:$PATH"

echo "::endgroup::"

# Generate image-info.json
/ctx/build_files/base/00-image-info.sh

# Get COPR Repos
/ctx/build_files/base/02-install-copr-repos.sh

# Install Kernel and Akmods
/ctx/build_files/base/03-install-kernel-akmods.sh

# Install Additional Packages
/ctx/build_files/base/04-packages.sh

# Install Overrides and Fetch Install
/ctx/build_files/base/05-override-install.sh

# Base Image Changes
/ctx/build_files/base/07-base-image-changes.sh

# Get Firmare for Framework
/ctx/build_files/base/08-firmware.sh

# Make HWE changes
/ctx/build_files/base/09-hwe-additions.sh

# Beta
/ctx/build_files/base/10-beta.sh

## late stage changes

# Systemd and Remove Items
/ctx/build_files/base/17-cleanup.sh

# Run workarounds for lf (Likely not needed)
/ctx/build_files/base/18-workarounds.sh

# Regenerate initramfs
/ctx/build_files/base/19-initramfs.sh

# Clean Up
echo "::group:: Cleanup"
/ctx/build_files/shared/clean-stage.sh
mkdir -p /var/tmp &&
    chmod -R 1777 /var/tmp
ostree container commit
echo "::endgroup::"
