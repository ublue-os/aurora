#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Force Ptyxis version opened via dbus (e.g., keyboard shortcut) to use the proper shim
# https://github.com/ublue-os/bazzite/pull/3620
sed -i 's@Exec=/usr/bin/ptyxis@Exec=/usr/bin/kde-ptyxis@g' /usr/share/dbus-1/services/org.gnome.Ptyxis.service

echo "::endgroup::"
