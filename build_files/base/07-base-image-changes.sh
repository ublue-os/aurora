#!/usr/bin/bash

set -ouex pipefail

# Restore x11 for Nvidia Images
if [[ "${FEDORA_MAJOR_VERSION}" -eq "40" ]]; then
    rpm-ostree install plasma-workspace-x11
fi

# Branding for Images
ln -sf ../places/distributor-logo.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg
ln -sf /usr/share/wallpapers/aurora-wallpaper-1/contents/images/15392x8616.jpg /usr/share/backgrounds/default.png
ln -sf /usr/share/wallpapers/aurora-wallpaper-1/contents/images/15392x8616.jpg /usr/share/backgrounds/default-dark.png
ln -sf aurora.xml /usr/share/backgrounds/default.xml

# Favorites in Kickoff
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:org.kde.discover.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml
sed -i '/<entry name="favorites" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.kate.desktop,org.gnome.Ptyxis.desktop,org.kde.discover.desktop<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml

# Ptyxis Terminal
sed -i 's@\[Desktop Action new-window\]@\[Desktop Action new-window\]\nX-KDE-Shortcuts=Ctrl+Alt+T@g' /usr/share/applications/org.gnome.Ptyxis.desktop
sed -i 's@Exec=ptyxis@Exec=kde-ptyxis@g' /usr/share/applications/org.gnome.Ptyxis.desktop
sed -i 's@Keywords=@Keywords=konsole;console;@g' /usr/share/applications/org.gnome.Ptyxis.desktop
cp /usr/share/applications/org.gnome.Ptyxis.desktop /usr/share/kglobalaccel/org.gnome.Ptyxis.desktop

rm -f /etc/profile.d/gnome-ssh-askpass.{csh,sh} # This shouldn't be pulled in

# Get Default Font since font fallback doesn't work
curl --retry 3 --output-dir /tmp -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
mkdir -p /usr/share/fonts/fira-nf
unzip /tmp/FiraCode.zip -d /usr/share/fonts/fira-nf
fc-cache -f /usr/share/fonts/fira-nf

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
