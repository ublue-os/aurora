#!/usr/bin/bash

set -xeou pipefail

echo "::group:: Copy Files"

# Copy Files to Image
rsync -rvK /ctx/system_files/dx/ /

echo "::endgroup::"

# Apply IP Forwarding before installing Docker to prevent messing with LXC networking
sysctl -p

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
