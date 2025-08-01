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


dnf5 -y copr disable ublue-os/staging
dnf5 -y copr disable ublue-os/packages
if [[ "${FEDORA_MAJOR_VERSION}" -lt "42" ]]; then
    dnf5 -y copr disable ganto/lxc4
fi
dnf5 -y copr disable ganto/umoci
dnf5 -y copr disable karmab/kcli
dnf5 -y copr disable hikariknight/looking-glass-kvmfr
dnf5 -y copr disable gmaglione/podman-bootc
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/vscode.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/docker-ce.repo
dnf5 -y copr disable phracek/PyCharm
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo
# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
# Diable terra repo
dnf5 -y config-manager setopt "terra".enabled=false

for i in /etc/yum.repos.d/rpmfusion-*; do
    sed -i 's@enabled=1@enabled=0@g' "$i"
done

echo "::endgroup::"
