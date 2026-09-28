#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# Apply IP Forwarding before installing Docker to prevent messing with LXC networking
sysctl -p

# DX packages from Fedora repos - common to all versions
FEDORA_PACKAGES=(
    android-tools
    bcc
    bcvk
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
    edk2-ovmf
    flatpak-builder
    incus
    incus-agent
    iotop
    libvirt
    libvirt-nss
    lxc
    nicstat
    numactl
    osbuild-selinux
    p7zip
    p7zip-plugins
    podman-compose
    podman-machine
    podman-tui
    qemu
    qemu-char-spice
    qemu-device-display-virtio-gpu
    qemu-device-display-virtio-vga
    qemu-device-usb-redirect
    qemu-img
    qemu-system-x86-core
    qemu-user-binfmt
    qemu-user-static
    sysprof
    trace-cmd
    udica
    virt-manager
    virt-v2v
    virt-viewer
    ydotool
)

# rocm doesn't work well on nvidia
if [[ ! "${IMAGE_NAME}" =~ nvidia ]]; then
  FEDORA_PACKAGES+=("rocm-hip" "rocm-opencl" "rocm-smi")
fi

dnf5 -y install "${FEDORA_PACKAGES[@]}"

# We could use Fedora's moby packages, these are "official"
DOCKER_CE=(
  containerd.io
  docker-buildx-plugin
  docker-ce
  docker-ce-cli
  docker-compose-plugin
)

COPR_PREFIX="copr:copr.fedorainfracloud.org"

# shellcheck disable=SC1010
dnf do -y \
  --action install --from-repo=code code \
  --action install --from-repo=docker-ce-stable "${DOCKER_CE[@]}" \
  --action install --from-repo="${COPR_PREFIX}:karmab:kcli" kcli

dnf -y install --from-repo="${COPR_PREFIX}:ublue-os:packages" ublue-os-libvirt-workarounds

rsync -rvK /ctx/system_files/dx/ /

# Load iptable_nat module for docker-in-docker.
# See:
#   - https://github.com/ublue-os/bluefin/issues/2365
#   - https://github.com/devcontainers/features/issues/1235
mkdir -p /etc/modules-load.d
tee /etc/modules-load.d/ip_tables.conf <<EOF
iptable_nat
EOF

# Branding Changes
echo "Variant=Developer Experience" >> /usr/share/kde-settings/kde-profile/default/xdg/kcm-about-distrorc

echo "::endgroup::"
