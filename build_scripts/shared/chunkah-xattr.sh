# See: https://github.com/coreos/chunkah#customizing-the-layers
#!/usr/bin/env bash

set -eoux pipefail

setfattr -n user.component -v "aurora-wallpapers" /usr/share/backgrounds/aurora
setfattr -n user.update-interval -v "monthly" /usr/share/backgrounds/aurora

setfattr -n user.component -v "aurora-assets" /usr/share/plasma/avatars/{echo,lumina,scope,tina,vincent}.png
setfattr -n user.component -v "aurora-assets" /etc/bazaar/*.jxl
setfattr -n user.update-interval -v "quarterly" /etc/bazaar/*.jxl

setfattr -n user.component -v "aurora-plasma-theme" /usr/share/plasma/look-and-feel/dev.getaurora.aurora{,light}.desktop
setfattr -n user.update-interval -v "quarterly" /usr/share/plasma/look-and-feel/dev.getaurora.aurora{,light}.desktop

setfattr -n user.component -v "aurora-config" /usr/share/ublue-os
setfattr -n user.component -v "homebrew" /usr/share/homebrew.tar.zst

setfattr -n user.component -v "aurora-offline-docs" /usr/share/doc/aurora/aurora.pdf

setfattr -n user.component -v "nerdfonts" /usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly
setfattr -n user.update-interval -v "yearly" /usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly

setfattr -n user.component -v "aurora-config" /usr/lib/systemd/system-generators/coreos-sulogin-force-generator

setfattr -n user.component -v "aurora-config" /usr/share/bash-preexec
