#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Footgun, See: https://github.com/ublue-os/main/issues/598
rm -f /usr/bin/chsh /usr/bin/lchsh

# Add linuxbrew to the list of paths usable by `sudo`
# not a sudoers.d override because we want to get updates from upstream and not break everything
sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers

# https://github.com/ublue-os/main/pull/334
ln -s "/usr/share/fonts/google-noto-sans-cjk-fonts" "/usr/share/fonts/noto-cjk"

# KDE Documentation is available online
rm -rf /usr/share/doc/HTML

# ######
# BASE IMAGE CHANGES
# ######

# sets default/pinned applications on the taskmanager applet on the panel, there is no nice way to do this
# https://bugs.kde.org/show_bug.cgi?id=511560
# TODO: KDE 6.6 dropped this file, find out some other way to set these
PANEL_CONF="/usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml"

if [[ -f "${PANEL_CONF}" ]]; then
  sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:io.github.kolunmi.Bazaar.desktop,preferred:\/\/filemanager<\/default>/' "${PANEL_CONF}"
fi

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

# Use Bazaar for Flatpak refs
# https://github.com/ublue-os/bazzite/pull/3620
echo "application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop" >> /usr/share/applications/mimeapps.list

rm -f /etc/profile.d/gnome-ssh-askpass.{csh,sh} # This shouldn't be pulled in

# Test aurora gschema override for errors. If there are no errors, proceed with compiling aurora gschema, which includes setting overrides.
mkdir -p /tmp/aurora-schema-test
find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/aurora-schema-test/ \;
cp /usr/share/glib-2.0/schemas/zz0-aurora-modifications.gschema.override /tmp/aurora-schema-test/
echo "Running error test for aurora gschema override. Aborting if failed."
glib-compile-schemas --strict /tmp/aurora-schema-test
echo "Compiling gschema to include aurora setting overrides"
glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null

# Make Samba usershares work OOTB
mkdir -p /var/lib/samba/usershares
chown -R root:usershares /var/lib/samba/usershares
firewall-offline-cmd --service=samba --service=samba-client
setsebool -P samba_enable_home_dirs=1
setsebool -P samba_export_all_ro=1
setsebool -P samba_export_all_rw=1
sed -i '/^\[homes\]/,/^\[/{/^\[homes\]/d;/^\[/!d}' /etc/samba/smb.conf

echo "::endgroup::"
