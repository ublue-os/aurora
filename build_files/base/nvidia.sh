#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

IMAGE_NAME="${BASE_IMAGE_NAME}" AKMODNV_PATH="/tmp/rpms/nvidia" MULTILIB=0 /tmp/rpms/nvidia/ublue-os/nvidia-install.sh
if [ -f "/etc/yum.repos.d/nvidia-container-toolkit.repo" ]; then
    sed -i \
        -e 's/^gpgcheck=0/gpgcheck=1/' \
        -e 's/^enabled=0.*/enabled=1/' \
        -e 's|^sslcacert=.*|sslcacert=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem|' \
        "/etc/yum.repos.d/nvidia-container-toolkit.repo"
fi
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

echo "::endgroup::"
