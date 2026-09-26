#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

KERNEL_PKGS_ORIG=(kernel kernel-{core,modules,modules-core,modules-extra,tools-libs,tools})

# removing them all at once is slower
for pkg in "${KERNEL_PKGS_ORIG[@]}"; do
  rpm --erase "${pkg}" --nodeps
done

# cleanup leftovers that are not covered by kernel-* packages for some reason
rm -rf /usr/lib/modules

KERNEL_PKGS=(
  /tmp/kernel-rpms/kernel-[0-9]*.rpm
  /tmp/kernel-rpms/kernel-core-*.rpm
  /tmp/kernel-rpms/kernel-modules-*.rpm
)

KMODS=(
  /tmp/rpms/{common,kmods}/*xone*.rpm
  /tmp/rpms/{common,kmods}/*v4l2loopback*.rpm
)

if [[ "${IMAGE_FLAVOR}" == "dx" ]]; then
  KERNEL_PKGS+=(/tmp/kernel-rpms/kernel-devel-*.rpm)
fi

KERNEL_PKGS_ALL=( "${KERNEL_PKGS[@]}" "${KMODS[@]}" )

# shims to bypass kernel install triggering dracut/rpm-ostree
# this is really ugly, skipping scriplets might be not a good idea
cd /usr/lib/kernel/install.d \
&& mv 05-rpmostree.install 05-rpmostree.install.bak \
&& mv 50-dracut.install 50-dracut.install.bak \
&& printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install \
&& printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install \
&& chmod +x  05-rpmostree.install 50-dracut.install

dnf -y install "${KERNEL_PKGS_ALL[@]}"

# restore original kernel install
mv -f 05-rpmostree.install.bak 05-rpmostree.install \
&& mv -f 50-dracut.install.bak 50-dracut.install
cd -

KERNEL_VERSIONLOCK=( "${KERNEL_PKGS_ORIG[@]}" kernel-devel{-matched,} )

dnf versionlock add "${KERNEL_VERSIONLOCK[@]}"

mkdir -p /etc/pki/akmods/certs
ghcurl "https://github.com/ublue-os/akmods/raw/refs/heads/main/certs/public_key.der" --retry 3 -Lo /etc/pki/akmods/certs/akmods-ublue.der

echo "::endgroup::"
