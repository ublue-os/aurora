#!/usr/bin/bash

# to reduce the indiviual layer size we put big files that are not shipped with RPMs in their own layers
# See: https://coreos.github.io/rpm-ostree/build-chunked-oci/

set -eoux pipefail

# Enable all this when fixed: https://github.com/coreos/rpm-ostree/issues/5545
# For now just hardcode the big files manually, keep the non-rpm layer amount static
# use systemd-escape -p
#setfattr -n user.component -v usr-share-doc-aurora-aurora.pdf /usr/share/doc/aurora/aurora.pdf
#setfattr -n user.component -v usr-share-homebrew.tar.zst /usr/share/homebrew.tar.zst
#setfattr -n user.component -v usr-bin-starhsip /usr/bin/starship
#setfattr -n user.component -v usr-share-backgrounds-aurora-aurora\x2dwallpaper\x2d3-contents-images-3840x2160.png /usr/share/backgrounds/aurora/aurora-wallpaper-3/contents/images/3840x2160.png
#setfattr -n user.component -v usr-share-backgrounds-aurora-aurora\x2dwallpaper\x2d4-contents-images-3840x2160.png /usr/share/backgrounds/aurora/aurora-wallpaper-4/contents/images/3840x2160.png
#setfattr -n user.component -v usr-share-backgrounds-aurora-aurora\x2dwallpaper\x2d2-contents-images-3840x2160.png /usr/share/backgrounds/aurora/aurora-wallpaper-2/contents/images/3840x2160.png
#setfattr -n user.component -v usr-share-backgrounds-aurora-aurora\x2dwallpaper\x2d7-contents-images-3840x2160.jxl /usr/share/backgrounds/aurora/aurora-wallpaper-7/contents/images/3840x2160.jxl
#setfattr -n user.component -v usr-lib-firmware-intel\x2ducode-06\x2dad\x2d01 /usr/lib/firmware/intel-ucode/06-ad-01
#setfattr -n user.component -v usr-share-fonts-nerd\x2dfonts-NerdFontsSymbolsOnly-SymbolsNerdFontMono\x2dRegular.ttf /usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf
#setfattr -n user.component -v usr-share-fonts-nerd\x2dfonts-NerdFontsSymbolsOnly-SymbolsNerdFont\x2dRegular.ttf /usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly/SymbolsNerdFont-Regular.ttf
#setfattr -n user.component -v usr-share-backgrounds-aurora-greg\x2drakozy\x2daurora-contents-images-5616x3744.jxl /usr/share/backgrounds/aurora/greg-rakozy-aurora/contents/images/5616x3744.jxl
#setfattr -n user.component -v usr-lib-firmware-asihpi-dsp8900.bin /usr/lib/firmware/asihpi/dsp8900.bin
#setfattr -n user.component -v usr-lib-firmware-intel\x2ducode-06\x2daf\x2d03 /usr/lib/firmware/intel-ucode/06-af-03
#setfattr -n user.component -v usr-share-backgrounds-aurora-aurora\x2dwallpaper\x2d8-contents-images-3840x2160.jxl /usr/share/backgrounds/aurora/aurora-wallpaper-8/contents/images/3840x2160.jxl
#setfattr -n user.component -v usr-share-backgrounds-aurora-jonatan\x2dpie\x2daurora-contents-images-3944x2770.jxl /usr/share/backgrounds/aurora/jonatan-pie-aurora/contents/images/3944x2770.jxl
#setfattr -n user.component -v usr-lib-firmware-intel\x2ducode-06\x2d8f\x2d08 /usr/lib/firmware/intel-ucode/06-8f-08
#setfattr -n user.component -v usr-share-sddm-themes-01\x2dbreeze\x2daurora-preview.png /usr/share/sddm/themes/01-breeze-aurora/preview.png
#setfattr -n user.component -v usr-share-color-icc-colord-framework16.icc /usr/share/color/icc/colord/framework16.icc
#setfattr -n user.component -v usr-share-color-icc-colord-framework13.icc /usr/share/color/icc/colord/framework13.icc
#setfattr -n user.component -v usr-share-plasma-avatars-lumina.png /usr/share/plasma/avatars/lumina.png
#setfattr -n user.component -v usr-share-backgrounds-aurora-aurora\x2dwallpaper\x2d6-contents-images-3840x2160.jxl /usr/share/backgrounds/aurora/aurora-wallpaper-6/contents/images/3840x2160.jxl
#setfattr -n user.component -v usr-lib-firmware-mixart-miXart8.elf /usr/lib/firmware/mixart/miXart8.elf
#setfattr -n user.component -v usr-share-plasma-avatars-vincent.png /usr/share/plasma/avatars/vincent.png
#setfattr -n user.component -v usr-lib-firmware-asihpi-dsp6200.bin /usr/lib/firmware/asihpi/dsp6200.bin
#setfattr -n user.component -v usr-share-backgrounds-aurora-xe_space_needle-contents-images-6000x4000.jxl /usr/share/backgrounds/aurora/xe_space_needle/contents/images/6000x4000.jxl
#setfattr -n user.component -v usr-share-plasma-avatars-echo.png /usr/share/plasma/avatars/echo.png
#setfattr -n user.component -v usr-share-plasma-avatars-phlip.png /usr/share/plasma/avatars/phlip.png
#setfattr -n user.component -v usr-share-plasma-avatars-scope.png /usr/share/plasma/avatars/scope.png
#setfattr -n user.component -v usr-share-plasma-avatars-tina.png /usr/share/plasma/avatars/tina.png
#setfattr -n user.component -v usr-lib-firmware-ctefx\x2ddesktop.bin /usr/lib/firmware/ctefx-desktop.bin
#setfattr -n user.component -v usr-lib-firmware-ctefx\x2dr3di.bin /usr/lib/firmware/ctefx-r3di.bin

#COUNT=30
#OUTPUT="/tmp/nonrpm.json"
## 600KiB
#MIN_SIZE=614400
#IGNORE=(
#    "^/usr/lib/sysimage/rpm-ostree-base-db/rpmdb.sqlite"
#    "^/usr/share/rpm/rpmdb.sqlite"
#    "^/usr/lib/modules" # spam
#    "^/usr/bin/tailscaled" # packaging is bumd, hardlinks
#    "^/usr/bin/zpool"
#    "^/usr/lib/fontconfig/cache"
#    "^/usr/lib64/.*\.so" # mostly useless files
#    "^/usr/lib32/.*\.so" # can't be assed to make this one thing
#    "^/usr/lib/.*\.so" # and do it properly
#    "^/usr/lib/bootupd/" # not worth
#)
#
#IGNORE_REGEX=$(printf "|%s" "${IGNORE[@]}")
#IGNORE_REGEX="${IGNORE_REGEX:1}"
#
## which files are not tracked by the rpmdb
#RPM_FILES=$(mktemp)
#rpm -qa --qf '[%{FILENAMES}\n]' | grep -E "^/usr|^/opt" | sort > "$RPM_FILES"
#
#NON_RPM_FILES=$(comm -23 \
#    <(find /usr -type f 2>/dev/null | grep -Ev "$IGNORE_REGEX" | sort) \
#    "$RPM_FILES"
#)
#
#echo "$NON_RPM_FILES" | xargs -d '\n' du -b 2>/dev/null | jq -Rn --argjson min "$MIN_SIZE" '
#  [
#    inputs | split("\t") | {
#      "path": .[1],
#      "size": (.[0] | tonumber),
#      "component": (.[1] | ltrimstr("/") | gsub("/"; "-"))
#    } | select(.size >= $min)
#  ]
#' > "$OUTPUT"
#
#echo "found $(jq 'length' "$OUTPUT") non-rpm tracked files"
#
## generated example command
## setfattr -n user.component -v usr-share-doc-aurora-aurora.pdf /usr/share/doc/aurora/aurora.pdf
#jq -c '.[]' "$OUTPUT" | while read -r item; do
#    path=$(echo "$item" | jq -r '.path')
#    comp=$(echo "$item" | jq -r '.component')
#    setfattr -n user.component -v "$comp" "$path"
#done
#
#echo "listing $COUNT biggest ones"
#jq -r --arg n "$COUNT" ' sort_by(.size) | reverse | .[0:($n | tonumber)] | .[] | "\(.size)\t\(.path)" ' "$OUTPUT" | numfmt --to=iec --field=1

echo "::endgroup::"
