#!/usr/bin/env bash

set -euo pipefail

source /usr/lib/ublue/setup-services/libsetup.sh
version-script aurora-flatpak user 1 || exit 0

# More consistent Qt/GTK themes for Flatpaks
flatpak override --user --filesystem=xdg-config/gtk-4.0:ro

# TODO: re-evaluate with Fedora 42
# Setting this variable to anything other than `xdgdesktopportal`
# will break the XDG Desktop Portal inside the sandbox
# See https://github.com/ublue-os/aurora/issues/224
flatpak override --user --unset-env=QT_QPA_PLATFORMTHEME

# webkit override to devpod for nvidia users
flatpak override --user --env=WEBKIT_DISABLE_COMPOSITING_MODE=1 sh.loft.devpod
