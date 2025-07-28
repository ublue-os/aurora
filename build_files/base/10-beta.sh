#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

if ! jq -e '.["image-tag"] | test("beta")' /usr/share/ublue-os/image-info.json >/dev/null; then
    echo "Skipping beta for non-beta image"
    exit 0
fi

dnf5 install -y bazaar krunner-bazaar

# Downgrade libdex to 0.9.1 because 0.10 makes bazaar crash under VMs and PCs with low specs
dnf5 install -y libdex-0.9.1

# For new users, enable Bazaar in KRunner + disable Discover results
cat >> /usr/share/kde-settings/kde-profile/default/xdg/krunnerrc << 'EOF'
[Plugins]
krunner_appstreamEnabled=false
bazaarrunnerEnabled=true
EOF

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


# install sudo-rs
dnf5 -y install sudo-rs
ln -sf /usr/bin/su-rs /usr/bin/su
ln -sf /usr/bin/sudo-rs /usr/bin/sudo
ln -sf /usr/bin/visudo-rs /usr/bin/visudo

echo "::endgroup::"
