#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Offline Aurora documentation
ghcurl "https://github.com/ublue-os/aurora-docs/releases/download/0.1/aurora.pdf" --retry 3 -o /tmp/aurora.pdf
install -Dm0644 -t /usr/share/doc/aurora/ /tmp/aurora.pdf
cp /usr/share/applications/dev.getaurora.aurora-docs.desktop /usr/share/kglobalaccel/

# Starship Shell Prompt
ghcurl "https://github.com/starship/starship/releases/latest/download/starship-$(uname -m)-unknown-linux-gnu.tar.gz" --retry 3 -o /tmp/starship.tar.gz
ghcurl "https://github.com/starship/starship/releases/latest/download/starship-$(uname -m)-unknown-linux-gnu.tar.gz.sha256" --retry 3 -o /tmp/starship.tar.gz.sha256

echo "$(cat /tmp/starship.tar.gz.sha256) /tmp/starship.tar.gz" | sha256sum --check
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >>/etc/bashrc

# Nerdfont symbols
# to fix motd and prompt atleast temporarily
ghcurl "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip" --retry 3 -o /tmp/nerdfontsymbols.zip
unzip /tmp/nerdfontsymbols.zip -d /tmp
mkdir -p /usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly/
mv /tmp/SymbolsNerdFont*.ttf /usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly/

# Bash Prexec v0.6.0
ghcurl https://raw.githubusercontent.com/rcaloras/bash-preexec/b73ed5f7f953207b958f15b1773721dded697ac3/bash-preexec.sh --retry 3 -Lo /usr/share/bash-prexec

# Caps
setcap 'cap_net_raw+ep' /usr/libexec/ksysguard/ksgrd_network_helper

# ######
# BASE IMAGE CHANGES
# ######

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
echo "application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop" >> /usr/share/applications/mimeapps.list

# Ptyxis Terminal
sed -i 's@\[Desktop Action new-window\]@\[Desktop Action new-window\]\nX-KDE-Shortcuts=Ctrl+Alt+T@g' /usr/share/applications/org.gnome.Ptyxis.desktop
sed -i 's@Exec=ptyxis@Exec=kde-ptyxis@g' /usr/share/applications/org.gnome.Ptyxis.desktop
sed -i 's@Keywords=@Keywords=konsole;console;@g' /usr/share/applications/org.gnome.Ptyxis.desktop
# GTK 4.20 changed how it handles input methods; see https://github.com/ghostty-org/ghostty/discussions/8899#discussioncomment-14717979
desktop-file-edit --set-key=Exec --set-value='env GTK_IM_MODULE=ibus kde-ptyxis' /usr/share/applications/org.gnome.Ptyxis.desktop
cp /usr/share/applications/org.gnome.Ptyxis.desktop /usr/share/kglobalaccel/

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
