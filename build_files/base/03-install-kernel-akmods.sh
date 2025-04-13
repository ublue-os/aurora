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

# Install Kernel
dnf5 -y install \
  /tmp/kernel-rpms/kernel-[0-9]*.rpm \
  /tmp/kernel-rpms/kernel-core-*.rpm \
  /tmp/kernel-rpms/kernel-modules-*.rpm

# TODO: Figure out why akmods cache is pulling in akmods/kernel-devel
dnf5 -y install \
  /tmp/kernel-rpms/kernel-devel-*.rpm

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra

# Everyone
# NOTE: we won't use dnf5 copr plugin for ublue-os/akmods until our upstream provides the COPR standard naming
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
    dnf5 -y install /tmp/akmods/kmods/*xone*.rpm || true
    dnf5 -y install /tmp/akmods/kmods/*xpadneo*.rpm || true
    dnf5 -y install /tmp/akmods/kmods/*openrazer*.rpm || true
    dnf5 -y install /tmp/akmods/kmods/*framework-laptop*.rpm || true
else
    dnf5 -y install \
        /tmp/akmods/kmods/*xone*.rpm \
        /tmp/akmods/kmods/*xpadneo*.rpm \
        /tmp/akmods/kmods/*openrazer*.rpm \
        /tmp/akmods/kmods/*framework-laptop*.rpm
fi

# Install v4l2loopback from terra or gracefully fail
dnf5 -y install --repo="terra" /tmp/akmods/kmods/*v4l2loopback*.rpm || true

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
  curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/main/nvidia-install.sh
  chmod +x /tmp/nvidia-install.sh
  IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh
  rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
  ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
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
    /tmp/akmods-zfs/kmods/zfs/libzfs5-*.rpm
    /tmp/akmods-zfs/kmods/zfs/libzpool5-*.rpm
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
