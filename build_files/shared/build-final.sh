#!/usr/bin/bash

set -eoux pipefail

echo "::group:: Copy Final Files"

# Apply the complete overlay after package removals so replacement files remain.
rsync -rvKl /ctx/system_files/shared/ /

setfattr -n user.component -v "aurora-wallpapers" /usr/share/backgrounds/aurora
setfattr -n user.update-interval -v "monthly" /usr/share/backgrounds/aurora

setfattr -n user.component -v "aurora-assets" /usr/share/plasma/avatars/{echo,lumina,scope,tina,vincent}.png
setfattr -n user.component -v "aurora-assets" /etc/bazaar/*.jxl
setfattr -n user.update-interval -v "quarterly" /etc/bazaar/*.jxl

setfattr -n user.component -v "aurora-plasma-theme" /usr/share/plasma/look-and-feel/dev.getaurora.aurora{,light}.desktop
setfattr -n user.update-interval -v "quarterly" /usr/share/plasma/look-and-feel/dev.getaurora.aurora{,light}.desktop

setfattr -n user.component -v "aurora-config" /usr/share/ublue-os
setfattr -n user.component -v "homebrew" /usr/share/homebrew.tar.zst

echo "::endgroup::"
