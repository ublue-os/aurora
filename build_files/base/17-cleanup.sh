#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Setup Systemd
systemctl enable rpm-ostree-countme.service
systemctl enable tailscaled.service
systemctl enable dconf-update.service
systemctl enable brew-setup.service
systemctl enable aurora-groups.service
systemctl enable ublue-system-setup.service
systemctl --global enable ublue-user-setup.service
systemctl --global enable podman-auto-update.timer
systemctl enable input-remapper.service

# Nuke possible Fedora flatpak repos
systemctl enable flatpak-nuke-fedora.service

# TODO: Reinvestigate when bazaar gains dbus activation
# systemctl --global enable bazaar.service

# see /usr/bin/rechunker-group-fix
# DO NOT REMOVE THIS
systemctl enable rechunker-group-fix.service

# run flatpak preinstall once at startup
systemctl enable flatpak-preinstall.service

# disable sunshine service
systemctl --global disable app-dev.lizardbyte.app.Sunshine.service

# Make speech dispatcher work by default
# TODO: Revisit with F45
# https://src.fedoraproject.org/rpms/redhat-systemd-presets/pull-request/4
# https://bugzilla.redhat.com/show_bug.cgi?id=2284507
systemctl --global enable speech-dispatcher.socket

# Updater
systemctl enable uupd.timer

# Disable the old update timer
systemctl disable rpm-ostreed-automatic.timer

# Hide Desktop Files. Hidden removes mime associations
for file in htop nvtop; do
    if [[ -f "/usr/share/applications/${file}.desktop" ]]; then
        desktop-file-edit --set-key=Hidden --set-value=true /usr/share/applications/${file}.desktop
    fi
done

# NOTE: With isolated COPR installation, most repos are never enabled globally.
# We only need to clean up repos that were enabled during the build process.

# Disable third-party repos
for repo in fedora-multimedia tailscale fedora-cisco-openh264; do
    if [[ -f "/etc/yum.repos.d/${repo}.repo" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "/etc/yum.repos.d/${repo}.repo"
    fi
done

# Disable Terra repos (installed on F42 and earlier)
for i in /etc/yum.repos.d/terra*.repo; do
    if [[ -f "$i" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "$i"
    fi
done

# Disable all COPR repos (should already be disabled by helpers, but ensure)
for i in /etc/yum.repos.d/_copr:*.repo; do
    if [[ -f "$i" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "$i"
    fi
done

# Disable RPM Fusion repos
for i in /etc/yum.repos.d/rpmfusion-*.repo; do
    if [[ -f "$i" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "$i"
    fi
done

# Disable fedora-coreos-pool if it exists
if [ -f /etc/yum.repos.d/fedora-coreos-pool.repo ]; then
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-coreos-pool.repo
fi

echo "::endgroup::"
