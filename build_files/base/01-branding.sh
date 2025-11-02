#!/bin/bash

echo "::group:: ===$(basename "$0")==="

# Branding for Images

ln -sf /usr/share/backgrounds/aurora/aurora-wallpaper-7/contents/images/3840x2160.jxl /usr/share/backgrounds/default.png
ln -sf /usr/share/backgrounds/aurora/aurora-wallpaper-7/contents/images/3840x2160.jxl /usr/share/backgrounds/default-dark.png
ln -sf /usr/share/backgrounds/aurora/aurora.xml /usr/share/backgrounds/default.xml

# /usr/share/sddm/themes/01-breeze-fedora/theme.conf uses default.jxl for the background
# We are lying about the extension
ln -sf /usr/share/backgrounds/default.png /usr/share/backgrounds/default.jxl
ln -sf /usr/share/backgrounds/default-dark.png /usr/share/backgrounds/default-dark.jxl

echo "::endgroup::"
