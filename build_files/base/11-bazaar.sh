#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

### Bazaar
echo "Installing Bazaar workarounds"

# Use Bazaar for Flatpak refs
echo "application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop" >> /usr/share/applications/mimeapps.list

# TODO: remove me when we fully switch to flatpak bazaar and are out of the transitionary period where we have both rpm and flatpak
cp -r /usr/share/ublue-os/bazaar /etc
sed -i 's|/usr/share/ublue-os/|/run/host/etc/|g' /etc/bazaar/config.yaml
