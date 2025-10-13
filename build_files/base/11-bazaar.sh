#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

### Bazaar
echo "Installing Bazaar workarounds"

# Replace discover on Panel and Kickoff with bazaar
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:io.github.kolunmi.Bazaar.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml
sed -i '/<entry name="favorites" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.kate.desktop,org.gnome.Ptyxis.desktop,dev.getaurora.aurora-docs.desktop,io.github.kolunmi.Bazaar.desktop<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml

# Use Bazaar for Flatpak refs
echo "application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop" >> /usr/share/applications/mimeapps.list

# TODO: remove me when we fully switch to flatpak bazaar and are out of the transitionary period where we have both rpm and flatpak
cp -r /usr/share/ublue-os/bazaar /etc
sed -i 's|/usr/share/ublue-os/|/run/host/etc/|g' /etc/bazaar/config.yaml
