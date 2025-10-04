#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

xmllint --noout \
  /usr/share/backgrounds/default.xml \
  /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml \
  /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

desktop-file-validate \
  /usr/share/applications/Discourse.desktop \
  /usr/share/applications/boot-to-windows.desktop \
  /usr/share/applications/dev.getaurora.aurora-docs.desktop \
  /usr/share/applications/documentation.desktop \
  /usr/share/applications/org.gnome.Ptyxis.desktop \
  /usr/share/applications/system-update.desktop

IMPORTANT_PACKAGES=(
    bazaar
    fish
    krunner-bazaar
    ptyxis
    starship
    tailscale
    uupd
    zsh
)

for package in "${IMPORTANT_PACKAGES[@]}"; do
    rpm -q "${package}" >/dev/null || { echo "Missing package: ${package}... Exiting"; exit 1 ; }
done

IMPORTANT_UNITS=(
    brew-update.timer
    brew-upgrade.timer
    rpm-ostree-countme.timer
    tailscaled.service
    ublue-system-setup.service
    uupd.timer
  )

for unit in "${IMPORTANT_UNITS[@]}"; do
    if ! systemctl is-enabled "$unit" 2>/dev/null | grep -q "^enabled$"; then
        echo "${unit} is not enabled"
        exit 1
    fi
done

echo "::endgroup::"
