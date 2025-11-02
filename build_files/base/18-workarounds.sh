#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Wait for driver loading to be complete before starting SDDM so that graphics work
# See https://github.com/sddm/sddm/issues/1917
sed -i '/^StartLimitBurst=2$/a # Wait for driver loading to be complete so that graphics work\n# (https://github.com/sddm/sddm/issues/1917)\nWants=systemd-udev-settle.service\nAfter=systemd-udev-settle.service' /usr/lib/systemd/system/sddm.service

# Current aurora systems have the bling.sh and bling.fish in their default locations
mkdir -p /usr/share/ublue-os/aurora-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/aurora-cli

# Try removing just docs (is it actually promblematic?)
rm -rf /usr/share/doc/just/README.*.md

echo "::endgroup::"
