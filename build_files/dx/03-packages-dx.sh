#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# Load secure COPR helpers
# shellcheck source=build_files/shared/copr-helpers.sh
source /ctx/build_files/shared/copr-helpers.sh

# NOTE:
# Packages are split into FEDORA_PACKAGES and COPR_PACKAGES to prevent
# malicious COPRs from injecting fake versions of Fedora packages.
# Fedora packages are installed first in bulk (safe).
# COPR packages are installed individually with isolated enablement.

# DX packages from Fedora repos - common to all versions
FEDORA_PACKAGES=(
    android-tools
    bcc
    bpftop
    bpftrace
    cockpit-bridge
    cockpit-machines
    cockpit-networkmanager
    cockpit-ostree
    cockpit-podman
    cockpit-selinux
    cockpit-storaged
    cockpit-system
    code
    containerd.io
    docker-buildx-plugin
    docker-ce
    docker-ce-cli
    docker-compose-plugin
    docker-model-plugin
    edk2-ovmf
    flatpak-builder
    genisoimage
    iotop
    libvirt
    libvirt-nss
    nicstat
    numactl
    osbuild-selinux
    p7zip
    podman-compose
    podman-machine
    podman-tui
    podmansh
    powerline-fonts
    qemu
    qemu-char-spice
    qemu-device-display-virtio-gpu
    qemu-device-display-virtio-vga
    qemu-device-usb-redirect
    qemu-img
    qemu-system-x86-core
    qemu-user-binfmt
    qemu-user-static
    rocm-hip
    rocm-opencl
    rocm-smi
    sysprof
    tiptop
    trace-cmd
    udica
    virt-manager
    virt-v2v
    virt-viewer
    ydotool
)

echo "Installing ${#FEDORA_PACKAGES[@]} DX packages from Fedora repos..."
dnf5 -y install "${FEDORA_PACKAGES[@]}"

echo "Installing DX COPR packages with isolated repo enablement..."

# lxc/incus packages - only for F41 and earlier
if [[ "${FEDORA_MAJOR_VERSION}" -lt "42" ]]; then
    copr_install_isolated "ganto/lxc4" "incus" "incus-agent" "lxc"
fi

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf5 -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

echo "::endgroup::"
