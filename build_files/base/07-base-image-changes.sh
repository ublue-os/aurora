#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# Remove desktop entries
if [[ -f /usr/share/applications/gnome-system-monitor.desktop ]]; then
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/gnome-system-monitor.desktop
fi
if [[ -f /usr/share/applications/org.gnome.SystemMonitor.desktop ]]; then
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/org.gnome.SystemMonitor.desktop
fi

# Branding for Images
ln -sf ../places/distributor-logo.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg
ln -sf /usr/share/backgrounds/aurora/aurora-wallpaper-1/contents/images/15392x8616.jpg /usr/share/backgrounds/default.png
ln -sf /usr/share/backgrounds/aurora/aurora-wallpaper-1/contents/images/15392x8616.jpg /usr/share/backgrounds/default-dark.png
ln -sf /usr/share/backgrounds/aurora/aurora.xml /usr/share/backgrounds/default.xml

# Favorites in Kickoff
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:org.kde.discover.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml
sed -i '/<entry name="favorites" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.kate.desktop,org.gnome.Ptyxis.desktop,org.kde.discover.desktop<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml

# Ptyxis Terminal
sed -i 's@\[Desktop Action new-window\]@\[Desktop Action new-window\]\nX-KDE-Shortcuts=Ctrl+Alt+T@g' /usr/share/applications/org.gnome.Ptyxis.desktop
sed -i 's@Exec=ptyxis@Exec=kde-ptyxis@g' /usr/share/applications/org.gnome.Ptyxis.desktop
sed -i 's@Keywords=@Keywords=konsole;console;@g' /usr/share/applications/org.gnome.Ptyxis.desktop
cp /usr/share/applications/org.gnome.Ptyxis.desktop /usr/share/kglobalaccel/org.gnome.Ptyxis.desktop

# Plasma Discover
sed -i 's/^Exec=plasma-discover/& --backends flatpak-backend/' /usr/share/applications/org.kde.discover.desktop

rm -f /etc/profile.d/gnome-ssh-askpass.{csh,sh} # This shouldn't be pulled in

# Test aurora gschema override for errors. If there are no errors, proceed with compiling aurora gschema, which includes setting overrides.
mkdir -p /tmp/aurora-schema-test
find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/aurora-schema-test/ \;
cp /usr/share/glib-2.0/schemas/zz0-aurora-modifications.gschema.override /tmp/aurora-schema-test/
echo "Running error test for aurora gschema override. Aborting if failed."
glib-compile-schemas --strict /tmp/aurora-schema-test
echo "Compiling gschema to include aurora setting overrides"
glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null

# Watermark for Plymouth
cp /usr/share/plymouth/themes/spinner/{"$BASE_IMAGE_NAME"-,}watermark.png

# Make Samba usershares work OOTB
mkdir -p /var/lib/samba/usershares
chown -R root:usershares /var/lib/samba/usershares
firewall-offline-cmd --service=samba --service=samba-client
setsebool -P samba_enable_home_dirs=1
setsebool -P samba_export_all_ro=1
setsebool -P samba_export_all_rw=1
sed -i '/^\[homes\]/,/^\[/{/^\[homes\]/d;/^\[/!d}' /etc/samba/smb.conf

echo "::endgroup::"
