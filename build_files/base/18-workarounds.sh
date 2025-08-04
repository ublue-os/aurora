#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
# Remember to leave a note with rationale/link to issue for each pin!
# Use dnf list --showduplicates package

# Workaround atheros-firmware regression
# see https://bugzilla.redhat.com/show_bug.cgi?id=2365882
dnf -y swap atheros-firmware atheros-firmware-20250311-1$(rpm -E %{dist})


# Current aurora systems have the bling.sh and bling.fish in their default locations
mkdir -p /usr/share/ublue-os/aurora-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/aurora-cli

# Try removing just docs (is it actually promblematic?)
rm -rf /usr/share/doc/just/README.*.md

### Bazaar
echo "Installing Bazaar workarounds"
# Downgrade libdex to 0.9.1 because 0.10 makes bazaar crash under VMs and PCs with low specs
dnf5 install -y libdex-0.9.1

# For new users, enable Bazaar in KRunner + disable Discover results
cat >> /usr/share/kde-settings/kde-profile/default/xdg/krunnerrc << 'EOF'
[Plugins]
krunner_appstreamEnabled=false
bazaarrunnerEnabled=true
EOF

# Workaround for Bazaar on Nvidia systems
if jq -e '.["image-flavor"] | test("nvidia")' /usr/share/ublue-os/image-info.json >/dev/null; then
  sed -i 's|^Exec=bazaar window --auto-service$|Exec=env GSK_RENDERER=opengl bazaar window --auto-service|' /usr/share/applications/io.github.kolunmi.Bazaar.desktop
fi

# Hide Discover entries by renaming them (allows for easy re-enabling)
discover_apps=(
  "org.kde.discover.desktop"
  "org.kde.discover-flatpak.desktop"
  "org.kde.discover.notifier.desktop"
  "org.kde.discover.urlhandler.desktop"
)

for app in "${discover_apps[@]}"; do
  if [ -f "/usr/share/applications/${app}" ]; then
    mv "/usr/share/applications/${app}" "/usr/share/applications/${app}.disabled"
  fi
done

# Replace discover on Panel and Kickoff with bazaar
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:io.github.kolunmi.Bazaar.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml
sed -i '/<entry name="favorites" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.kate.desktop,org.gnome.Ptyxis.desktop,io.github.kolunmi.Bazaar.desktop<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml

# Use Bazaar for Flatpak refs
echo "application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop" >> /usr/share/applications/mimeapps.list


echo "::endgroup::"
