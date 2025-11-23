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
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:io.github.kolunmi.Bazaar.desktop,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

# Generate Logos from source SVGs
mkdir -p /usr/share/icons/hicolor/scalable/{apps,places}
mkdir -p /usr/share/pixmaps
cp /ctx/logos/distributor-logo.svg /usr/share/icons/hicolor/scalable

cp \
  /ctx/logos/auroralogo-white.svg \
  /ctx/logos/distributor-logo-symbolic.svg \
  /ctx/logos/auroralogo-circle-symbolic.svg \
  /ctx/logos/auroralogo-pride.svg \
  /ctx/logos/auroralogo-pride-trans.svg \
  /usr/share/icons/hicolor/scalable/places/

cp /ctx/logos/aurora-banner.svg /usr/share/pixmaps/
ln -sr /usr/share/pixmaps/aurora-banner.svg /usr/share/pixmaps/fedora-logo.svg

# Banner, keep the Fedora stuff for compatibility
magick -background none /ctx/logos/aurora-banner.svg -quality 90 -resize $((400-10*2))x100 -gravity center -extent 400x100 /usr/share/pixmaps/fedora-logo.png
magick -background none /ctx/logos/aurora-banner.svg -quality 90 -resize $((128-3*2))x32 -gravity center -extent 128x32 /usr/share/pixmaps/fedora-logo-small.png
magick -background none /ctx/logos/aurora-banner.svg -quality 90 -resize $((200-5*2))x50 -gravity center -extent 200x100 /usr/share/pixmaps/fedora_logo_med.png

# "A" Logo
magick -background none /ctx/logos/distributor-logo.svg -quality 90 -resize 256x256! /usr/share/pixmaps/system-logo.png
magick -background none /ctx/logos/distributor-logo.svg -quality 90 -resize 128x128! /usr/share/pixmaps/fedora-logo-sprite.png
magick -background none /ctx/logos/distributor-logo.svg -quality 90 -resize 256x256! /usr/share/pixmaps/system-logo-white.png

ln -sr /usr/share/pixmaps/aurora-banner.svg /usr/share/pixmaps/fedora_whitelogo.svg
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo.svg /usr/share/pixmaps/fedora-logo-sprite.svg
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo.svg /usr/share/icons/hicolor/scalable/places/distributor-logo.svg
ln -sr /usr/share/icons/hicolor/scalable/distributor-logo.svg /usr/share/icons/hicolor/scalable/places/auroralogo-gradient.svg
ln -sr /usr/share/icons/hicolor/scalable/places/distributor-logo-symbolic.svg /usr/share/icons/hicolor/scalable/places/auroralogo-symbolic.svg
ln -sr /usr/share/icons/hicolor/scalable/places/distributor-logo-symbolic.svg /usr/share/icons/hicolor/scalable/places/distributor-logo-white.svg
ln -sr /usr/share/icons/hicolor/scalable/places/distributor-logo-symbolic.svg /usr/share/icons/hicolor/scalable/places/start-here.svg
ln -sr /usr/share/icons/hicolor/scalable/places/distributor-logo-symbolic.svg /usr/share/icons/hicolor/scalable/apps/start-here.svg

# the themes read from relative directories
mkdir -p /usr/share/plasma/look-and-feel/dev.getaurora.aurora.desktop/contents/splash/images/
gzip -c /usr/share/icons/hicolor/scalable/distributor-logo.svg > /usr/share/plasma/look-and-feel/dev.getaurora.aurora.desktop/contents/splash/images/aurora_logo.svgz

ln -sr /usr/share/icons/hicolor/scalable/places/distributor-logo.svg /usr/share/sddm/themes/01-breeze-aurora/default-logo.svg

# generate plymouth logos
mkdir -p /usr/share/plymouth/themes/spinner/
magick -background none /usr/share/pixmaps/aurora-banner.svg -quality 90 -resize $((128-3*2))x32 -gravity center -extent 128x32 /usr/share/plymouth/themes/spinner/watermark.png
cp /usr/share/plymouth/themes/spinner/watermark.png /usr/share/plymouth/themes/spinner/kinoite-watermark.png

echo "::endgroup::"
