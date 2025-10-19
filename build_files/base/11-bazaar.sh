#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

### Bazaar
echo "Installing Bazaar workarounds"

# Hide Discover entries by renaming them (allows for easy re-enabling)
discover_apps=(
  "org.kde.discover.desktop"
  "org.kde.discover.flatpak.desktop"
  "org.kde.discover.notifier.desktop"
  "org.kde.discover.urlhandler.desktop"
)

for app in "${discover_apps[@]}"; do
  if [ -f "/usr/share/applications/${app}" ]; then
    mv "/usr/share/applications/${app}" "/usr/share/applications/${app}.disabled"
  fi
done

# These notifications are useless and confusing
rm /etc/xdg/autostart/org.kde.discover.notifier.desktop

# Replace discover on Panel and Kickoff with bazaar
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:io.github.kolunmi.Bazaar.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

# Symlink Discover to Bazaar
ln -s /usr/share/applications/io.github.kolunmi.Bazaar.desktop /usr/share/applications/org.kde.discover.desktop

# Use Bazaar for Flatpak refs
echo "application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop" >> /usr/share/applications/mimeapps.list

# TODO: remove me when we fully switch to flatpak bazaar and are out of the transitionary period where we have both rpm and flatpak
cp -r /usr/share/ublue-os/bazaar /etc
sed -i 's|/usr/share/ublue-os/|/run/host/etc/|g' /etc/bazaar/config.yaml
