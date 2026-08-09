#!/usr/bin/bash

set -eoux pipefail

echo "::group:: Copy Files"

# Speeds up local builds and workaround network flakes, mainly for COPR and negativo
cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
dnf config-manager setopt keepcache=1 timeout=60

# We need to remove this package here because lots of files we add from `{projectbluefin,get-aurora-dev}/common` override the rpm files
# they go away when you do dnf remove
# Keep *-logos in RPM DB for downstream package installations
# We are not allowed to ship an empty fedora-logos package
dnf -y swap fedora-logos generic-logos
rpm --erase --nodeps --nodb generic-logos

# Copy only files needed by package and fetch stages. The full overlay is applied
# after package removals so replaced RPM-owned files are retained.
install -Dm0644 /ctx/system_files/shared/etc/dnf/plugins/copr.vendor.conf /etc/dnf/plugins/copr.vendor.conf
install -Dm0644 /ctx/system_files/shared/usr/share/applications/dev.getaurora.offline-docs.desktop /usr/share/applications/dev.getaurora.offline-docs.desktop
rsync -rvKl /ctx/system_files/shared/usr/share/ublue-os/ /usr/share/ublue-os/

if [[ "${IMAGE_FLAVOR}" == "dx" ]]; then
  /ctx/build_files/shared/build-dx.sh
fi

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_files/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl

echo "::endgroup::"
