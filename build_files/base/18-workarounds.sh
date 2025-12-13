#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Current aurora systems have the bling.sh and bling.fish in their default locations
mkdir -p /usr/share/ublue-os/aurora-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/aurora-cli

# Force Ptyxis version opened via dbus (e.g., keyboard shortcut) to use the proper shim
# https://github.com/ublue-os/bazzite/pull/3620
sed -i 's@Exec=/usr/bin/ptyxis@Exec=/usr/bin/kde-ptyxis@g' /usr/share/dbus-1/services/org.gnome.Ptyxis.service

echo "::endgroup::"
