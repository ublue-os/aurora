#!/usr/bin/env bash
# See: https://github.com/coreos/chunkah#customizing-the-layers
echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

HOMEBREW_TARBALL=/usr/share/homebrew.tar.zst
setfattr -n user.component -v "homebrew" "${HOMEBREW_TARBALL}"

# rpm-ostree creates tmpfiles from packages having owned files in /{var,run}
RPM_OSTREE_TMPFILES=/usr/lib/rpm-ostree/tmpfiles.d
setfattr -n user.component -v "rpm-ostree-tmpfiles.d" "${RPM_OSTREE_TMPFILES}"
# vibes, shouldn't change super often
setfattr -n user.update-interval -v "quarterly" "${RPM_OSTREE_TMPFILES}"

FONTCONFIG_CACHE=/usr/lib/fontconfig/cache
setfattr -n user.component -v "fontconfig-cache" "${FONTCONFIG_CACHE}"
# also vibes, no idea how often this changes, but it seems to change often
setfattr -n user.update-interval -v "daily" "${FONTCONFIG_CACHE}"

WALLPAPERS=/usr/share/backgrounds/aurora
setfattr -n user.component -v "aurora-wallpapers" "${WALLPAPERS}"
setfattr -n user.update-interval -v "monthly" "${WALLPAPERS}"

AURORA_CHARS=(/usr/share/plasma/avatars/{echo,lumina,scope,tina,vincent}.png)
setfattr -n user.component -v "aurora-assets" "${AURORA_CHARS[@]}"

BAZAAR=(/etc/bazaar/*.jxl)
setfattr -n user.component -v "aurora-assets" "${BAZAAR[@]}"
setfattr -n user.update-interval -v "quarterly" "${BAZAAR[@]}"

AURORA_DOCS_PDF="/usr/share/doc/aurora/aurora.pdf"
setfattr -n user.component -v "aurora-offline-docs" "${AURORA_DOCS_PDF}"

# TODO: everything else we can probably add here
FRAMEWORK_ICC=(/usr/share/color/icc/colord/framework1{3,6}.icc)
setfattr -n user.component -v "never-change" "${FRAMEWORK_ICC[@]}"
setfattr -n user.update-interval -v "yearly" "${FRAMEWORK_ICC[@]}"

# This is absolutely nasty, ideally we'd use SOURCE_DATE_EPOCH=0 on chunkah for
# all the touch invocations but this (potentially) affects the layer plan
# negatively
# See: https://github.com/coreos/chunkah/issues/160
#
# on the composefs backend this also makes it so that bootc (uupd notification)
# flags the image as outdated with label org.opencontainers.image.created and
# ".Created" (it's set to 1970 after all) this doesn't happen on ostree
# https://github.com/bootc-dev/bootc/issues/2227

# This shouldn't hurt anything, Epoch 0 is what RPMs are using, we don't want to override that
find /usr /etc /opt -exec touch -h -a -m -d '1970-01-01T00:00:00Z' {} +

# getfattr -R -d /usr 2> /dev/null || true
# getfattr -R -d /etc 2> /dev/null || true

echo "::endgroup::"
