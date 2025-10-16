#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Beta Updates Testing Repo...
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
    dnf5 config-manager setopt updates-testing.enabled=1
fi

# Remove Existing Kernel
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
    rpm --erase $pkg --nodeps
done

# Fetch Common AKMODS & Kernel RPMS
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/
# NOTE: kernel-rpms should auto-extract into correct location

# For stable images with coreos kernel always replace the kernel with the one from akmods
if [ "$AKMODS_FLAVOR" = "coreos-stable" ]; then
  dnf5 -y install /tmp/kernel-rpms/kernel-{core,modules,modules-core,modules-extra}-"${KERNEL}".rpm
  # CoreOS doesn't do kernel-tools, removes leftovers from newer kernel
  dnf5 -y remove kernel-tools{,-libs}
fi

# Only touch latest kernel when we need to pin it because of some super bad regression
# so only replace the latest kernel with the one from akmods when the ublue-os/main kernel differs from ublue-os/akmods, so we pin in Aurora/Bluefin but not in main
if [[ "$AKMODS_FLAVOR" = "main" && "$KERNEL" -ne $(rpm -q --queryformat="%{evr}.%{arch}" kernel-core) ]]; then
  dnf5 -y install /tmp/kernel-rpms/kernel{,-core,-modules,-modules-core,-modules-extra}-"${KERNEL}".rpm
fi

# TODO: Remove this shit with F43
if [[ "$AKMODS_FLAVOR" = "bazzite" ]]; then
  dnf5 -y install /tmp/kernel-rpms/kernel{,-core,-modules,-modules-core,-modules-extra}-"${KERNEL}".rpm
fi

# Prevent kernel stuff from upgrading again
dnf5 versionlock add kernel{,-core,-modules,-modules-core,-modules-extra,-tools,-tools-lib,-headers,-devel,-devel-matched}

# Everyone
# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
    dnf5 -y install /tmp/akmods/kmods/*xone*.rpm || true
    dnf5 -y install /tmp/akmods/kmods/*openrazer*.rpm || true
    dnf5 -y install /tmp/akmods/kmods/*framework-laptop*.rpm || true
else
    dnf5 -y install \
        /tmp/akmods/kmods/*xone*.rpm \
        /tmp/akmods/kmods/*openrazer*.rpm \
        /tmp/akmods/kmods/*framework-laptop*.rpm
fi

# RPMFUSION Dependent AKMODS
dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm

dnf5 -y install \
        v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm

dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release

# Nvidia AKMODS
if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
  # Fetch Nvidia RPMs
  if [[ "${IMAGE_NAME}" =~ open ]]; then
    skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia-open:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods-rpms
  else
    skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods-rpms
  fi
  NVIDIA_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-rpms/manifest.json | cut -d : -f 2)
  tar -xvzf /tmp/akmods-rpms/"$NVIDIA_TARGZ" -C /tmp/
  mv /tmp/rpms/* /tmp/akmods-rpms/

  # Exclude the Golang Nvidia Container Toolkit in Fedora Repo
 dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit

  # Install Nvidia RPMs
  curl --retry 3 -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/main/main/build_files/nvidia-install.sh
  chmod +x /tmp/nvidia-install.sh
  IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
  rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
  ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
  tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF
fi

# ZFS for stable
if [[ ${AKMODS_FLAVOR} =~ coreos ]]; then
  # Fetch ZFS RPMs
  skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-zfs:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods-zfs
  ZFS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-zfs/manifest.json | cut -d : -f 2)
  tar -xvzf /tmp/akmods-zfs/"$ZFS_TARGZ" -C /tmp/
  mv /tmp/rpms/* /tmp/akmods-zfs/

  # Declare ZFS RPMs
  ZFS_RPMS=(
    /tmp/akmods-zfs/kmods/zfs/kmod-zfs-"${KERNEL}"-*.rpm
    /tmp/akmods-zfs/kmods/zfs/libnvpair3-*.rpm
    /tmp/akmods-zfs/kmods/zfs/libuutil3-*.rpm
    /tmp/akmods-zfs/kmods/zfs/libzfs6-*.rpm
    /tmp/akmods-zfs/kmods/zfs/libzpool6-*.rpm
    /tmp/akmods-zfs/kmods/zfs/python3-pyzfs-*.rpm
    /tmp/akmods-zfs/kmods/zfs/zfs-*.rpm
    pv
  )

  # Install
  dnf5 -y install "${ZFS_RPMS[@]}"

  # Depmod and autoload
  depmod -a -v "${KERNEL}"
  echo "zfs" >/usr/lib/modules-load.d/zfs.conf
fi

echo "::endgroup::"
