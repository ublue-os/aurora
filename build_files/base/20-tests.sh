#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

xmllint --noout \
  /usr/share/backgrounds/default.xml \
  /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

# If this file is not on the image bazaar will automatically be removed from users systems :(
# See: https://docs.flatpak.org/en/latest/flatpak-command-reference.html#flatpak-preinstall
test -f /usr/share/flatpak/preinstall.d/bazaar.preinstall

# Make sure this garbage never makes it to an image
test -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service && false

# Basic smoke test to check if the flatpak version is from our copr
flatpak preinstall --help

desktop-file-validate \
  /usr/share/applications/Discourse.desktop \
  /usr/share/applications/boot-to-windows.desktop \
  /usr/share/applications/dev.getaurora.aurora-docs.desktop \
  /usr/share/applications/documentation.desktop \
  /usr/share/applications/org.gnome.Ptyxis.desktop \
  /usr/share/applications/system-update.desktop

# Check for KDE Plasma version mismatch
# Fedora Repos have gotten the newer one, trying to upgrade
# everything except a few packages, breaking SDDM and shell

KDE_VER="$(rpm -q --qf '%{VERSION}' plasma-desktop)"
# package picked by failures in the past
KSCREEN_VERS="$(rpm -q --qf '%{VERSION}' kscreen)"
KWIN_VERS="$(rpm -q --qf '%{VERSION}' kwin)"

# Doing QT as well just in case, we have a versionlock in main
QT_VER="$(rpm -q --qf '%{VERSION}' qt6-qtbase)"
# Not an important package in itself, just a good indicator
QTFS_VER="$(rpm -q --qf '%{VERSION}' qt6-filesystem)"

if [[ "$KDE_VER" != "$KSCREEN_VERS" || "$KDE_VER" != "$KWIN_VERS" ]]; then
    echo "KDE Version mismatch"
    exit 1
fi

if [[ "$QT_VER" != "$QTFS_VER" ]]; then
    echo "QT Version mismatch"
    exit 1
fi

IMPORTANT_PACKAGES=(
    distrobox
    fish
    flatpak
    krunner-bazaar
    kwin
    pipewire
    plasma-desktop
    podman
    ptyxis
    sddm
    Sunshine
    systemd
    tailscale
    uupd
    wireplumber
    zsh
)

for package in "${IMPORTANT_PACKAGES[@]}"; do
    rpm -q "${package}" >/dev/null || { echo "Missing package: ${package}... Exiting"; exit 1 ; }
done

# these packages are supposed to be removed
# and are considered footguns
UNWANTED_PACKAGES=(
    firefox
    plasma-discover-kns
    plasma-discover-rpm-ostree
    podman-docker
)

for package in "${UNWANTED_PACKAGES[@]}"; do
    if rpm -q "${package}" >/dev/null 2>&1; then
        echo "Unwanted package found: ${package}... Exiting"; exit 1
    fi
done

# TODO: Enable when libnvidia-container-tools are on F43
#if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
#  NV_PACKAGES=(
#      libnvidia-container-tools
#      kmod-nvidia
#      nvidia-driver-cuda
#)
#  for package in "${NV_PACKAGES[@]}"; do
#      rpm -q "${package}" >/dev/null || { echo "Missing NVIDIA package: ${package}... Exiting"; exit 1 ; }
#  done
#fi

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
