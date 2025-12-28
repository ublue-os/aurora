#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# We need to have the ublue-os signing keys on the image!
# Published images without these keys won't be able to pull ghcr.io/ublue-os/*
# and can therefore not update!
# https://github.com/ublue-os/main/blob/963609eaf01f7c2bb1a76821fe6d0ec269d2df25/build_files/install.sh#L56
# https://github.com/ublue-os/packages/tree/1f77c7e7faa9ebad120609a10d79e0412376c3b7/packages/ublue-os-signing/src

KEY1=$(jq -r '.transports.docker."ghcr.io/ublue-os"[0].keyPaths[0]' /etc/containers/policy.json)
BACKUP_KEY=$(jq -r '.transports.docker."ghcr.io/ublue-os"[0].keyPaths[1]' /etc/containers/policy.json)
KEY1_SHA256="af78ecfda6eb21c35195af3739341715e9cfc3f2f5911dd9c10b0670547bf6e8"
BACKUP_KEY_SHA256="b723467015ba562d40b4645c98c51c65d8254bb59444f6e9962debcfe2315da0"

echo "${KEY1_SHA256}  ${KEY1}" | sha256sum -c -
echo "${BACKUP_KEY_SHA256}  ${BACKUP_KEY}" | sha256sum -c -

# branding related changes
test -f /usr/share/icons/hicolor/scalable/distributor-logo.svg
test -f /usr/share/pixmaps/system-logo-white.png
test -f /usr/share/icons/hicolor/scalable/apps/start-here.svg
test -f /usr/share/pixmaps/fedora-logo.svg
test -d /usr/share/plasma/look-and-feel/dev.getaurora.aurora.desktop

test -f /usr/share/backgrounds/aurora/aurora-wallpaper-8/contents/images/3840x2160.jxl
test -f /usr/share/wallpapers/aurora-wallpaper-8/contents/images/3840x2160.jxl
test -L /usr/share/backgrounds/default.jxl

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

test -f /usr/share/doc/aurora/aurora.pdf
test -f /usr/share/homebrew.tar.zst

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
    akonadi-server
    fedora-logos
    fedora-third-party
    firefox
    plasma-discover-kns
    plasma-discover-rpm-ostree
    plasma-lookandfeel-fedora
    podman-docker
)

for package in "${UNWANTED_PACKAGES[@]}"; do
    if rpm -q "${package}" >/dev/null 2>&1; then
        echo "Unwanted package found: ${package}... Exiting"; exit 1
    fi
done

if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
  NV_PACKAGES=(
      kmod-nvidia
      libnvidia-container-tools
      nvidia-driver-cuda
)
  for package in "${NV_PACKAGES[@]}"; do
      rpm -q "${package}" >/dev/null || { echo "Missing NVIDIA package: ${package}... Exiting"; exit 1 ; }
  done
fi

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
