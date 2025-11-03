#!/bin/bash

echo "::group:: ===$(basename "$0")==="

# Branding for Images

# Set default wallpaper
# sddm theme.conf uses .jxl for the background!
# default-dark currently point to the same file
ln -sf /usr/share/backgrounds/aurora/aurora-wallpaper-7/contents/images/3840x2160.jxl /usr/share/backgrounds/default.jxl
ln -sf /usr/share/backgrounds/aurora/aurora-wallpaper-7/contents/images/3840x2160.jxl /usr/share/backgrounds/default-dark.jxl
ln -sf /usr/share/backgrounds/aurora/aurora.xml /usr/share/backgrounds/default.xml

# sets default/pinned applications on the taskmanager applet on the panel, there is no nice way to do this
# https://bugs.kde.org/show_bug.cgi?id=511560
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:org.kde.discover.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

# we use our own theme
# we can't remove plasma-lookandfeel-fedora package because it is a dependency for plasma-desktop
rm -rf /usr/share/plasma/look-and-feel/org.fedoraproject.fedora.desktop/

echo "::endgroup::"
