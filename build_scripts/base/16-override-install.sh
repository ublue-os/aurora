#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Copy Files to Container
rsync -rvKl /ctx/system_files/shared/ /

# Footgun, See: https://github.com/ublue-os/main/issues/598
rm -f /usr/bin/chsh /usr/bin/lchsh

# Add linuxbrew to the list of paths usable by `sudo`
# not a sudoers.d override because we want to get updates from upstream and not break everything
sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers

# https://github.com/ublue-os/main/pull/334
ln -s "/usr/share/fonts/google-noto-sans-cjk-fonts" "/usr/share/fonts/noto-cjk"

# KDE Documentation is available online
rm -rf /usr/share/doc/HTML

rm -f /usr/lib64/qt6/plugins/kf6/krunner/krunner_appstream.so

# xdg-mime doesn't natively support using /usr/share/applications/mimeapps.list and would instead change /root/.config/mimeapps.list, so we do a little
# trickery to change default applications
XDG_CONFIG_HOME=/usr/share/applications xdg-mime default org.mozilla.thunderbird.desktop x-scheme-handler/mailto
XDG_CONFIG_HOME=/usr/share/applications xdg-mime default io.github.kolunmi.Bazaar.desktop application/vnd.flatpak.ref

rm -f /etc/profile.d/gnome-ssh-askpass.{csh,sh} # This shouldn't be pulled in

# Make Samba usershares work OOTB
mkdir -p /var/lib/samba/usershares
chown -R root:usershares /var/lib/samba/usershares
firewall-offline-cmd --service=samba --service=samba-client
setsebool -P samba_enable_home_dirs=1
setsebool -P samba_export_all_ro=1
setsebool -P samba_export_all_rw=1
sed -i '/^\[homes\]/,/^\[/{/^\[homes\]/d;/^\[/!d}' /etc/samba/smb.conf

# So we can bind offline docs to a shortcut
cp /usr/share/applications/dev.getaurora.offline-docs.desktop /usr/share/kglobalaccel/

echo "::endgroup::"
