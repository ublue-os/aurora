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

echo "Installing ${#FEDORA_PACKAGES[@]} DX packages from Fedora repos..."
dnf5 -y install "${FEDORA_PACKAGES[@]}"

# Docker packages from their repo
dnf -y install --from-repo=docker-ce-stable \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin

# VSCode package from Microsoft repo
dnf -y install --from-repo=code \
    code

dnf -y install --from-repo='copr:copr.fedorainfracloud.org:karmab:kcli' kcli

dnf -y install --from-repo='copr:copr.fedorainfracloud.org:ublue-os:packages' ublue-os-libvirt-workarounds

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

# Enable DX services
if rpm -q docker-ce >/dev/null; then
    systemctl enable docker.socket
fi
systemctl enable podman.socket
systemctl enable ublue-os-libvirt-workarounds.service
systemctl enable --global aurora-dx-user-vscode.service

# Disable RPM Fusion repos
for i in /etc/yum.repos.d/rpmfusion-*.repo; do
    if [[ -f "$i" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "$i"
    fi
done

echo "::endgroup::"
