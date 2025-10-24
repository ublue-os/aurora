#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

if rpm -q docker-ce >/dev/null; then
    systemctl enable docker.socket
fi
systemctl enable podman.socket
systemctl enable swtpm-workaround.service
systemctl enable ublue-os-libvirt-workarounds.service
systemctl enable aurora-dx-groups.service
systemctl enable --global aurora-dx-user-vscode.service

# NOTE: With isolated COPR installation, most repos are never enabled globally.
# We only need to clean up repos that were enabled during the build process.

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/vscode.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/docker-ce.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo

# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

echo "::endgroup::"
