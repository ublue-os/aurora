#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Not available for Fedora 43 yet
dnf config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit

ghcurl "https://raw.githubusercontent.com/ublue-os/main/main/build_files/nvidia-install.sh" -o /tmp/nvidia-install.sh
chmod +x /tmp/nvidia-install.sh
IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" AKMODNV_PATH="/tmp/rpms/nvidia" /tmp/nvidia-install.sh
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

echo "::endgroup::"
