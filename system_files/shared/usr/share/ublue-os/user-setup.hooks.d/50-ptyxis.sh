#!/usr/bin/env bash

set -euo pipefail

source /usr/lib/ublue/setup-services/libsetup.sh
version-script aurora-ptyxis user 1 || exit 0

# Ensure custom ptyxis theme is present
PTYXIS_THEME_DIR="/etc/skel/.local/share/org.gnome.Ptyxis/palettes"
PTYXIS_DIR="$HOME/.local/share/org.gnome.Ptyxis/palettes"
mkdir -p "$PTYXIS_DIR"
if [[ ! -f "$PTYXIS_DIR/catppuccin-dynamic.palette" ]]; then
  cp "$PTYXIS_THEME_DIR/catppuccin-dynamic.palette" "$PTYXIS_DIR/catppuccin-dynamic.palette"
fi