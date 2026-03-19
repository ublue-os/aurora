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

rm -f /usr/lib64/qt6/plugins/kf6/krunner/krunner_appstream.so

# Use Bazaar for Flatpak refs
# https://github.com/ublue-os/bazzite/pull/3620
echo "application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop" >> /usr/share/applications/mimeapps.list

rm -f /etc/profile.d/gnome-ssh-askpass.{csh,sh} # This shouldn't be pulled in

# Make Samba usershares work OOTB
mkdir -p /var/lib/samba/usershares
chown -R root:usershares /var/lib/samba/usershares
firewall-offline-cmd --service=samba --service=samba-client
setsebool -P samba_enable_home_dirs=1
setsebool -P samba_export_all_ro=1
setsebool -P samba_export_all_rw=1
sed -i '/^\[homes\]/,/^\[/{/^\[homes\]/d;/^\[/!d}' /etc/samba/smb.conf

# beta only quirk, remove when https://github.com/get-aurora-dev/common/pull/119 merged
sed -i "s/org.gnome.Ptyxis/org.kde.konsole/" /usr/share/kde-settings/kde-profile/default/xdg/kicker-extra-favoritesrc
sed -i "s/org.gnome.Ptyxis/org.kde.konsole/" /usr/share/plasma/look-and-feel/dev.getaurora.aurora.desktop/contents/layouts/org.kde.plasma.desktop-layout.js

echo "::endgroup::"
