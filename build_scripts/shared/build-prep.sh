# This script should generally set up the build so we can move on to start installing packages

#!/usr/bin/bash

set -eoux pipefail

# Speeds up local builds and workaround network flakes, mainly for COPR and negativo
cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
dnf config-manager setopt keepcache=1 timeout=60

# https://fedoraproject.org/wiki/Changes/DisableVendorChangeByDefault
# Get ahead of fedora and make our stuff work with it already
echo "allow_vendor_change=False" >> /usr/share/dnf5/libdnf.conf.d/20-fedora-defaults.conf

cat > "/usr/share/dnf5/vendors.d/30-ublue-os-trusted.conf" << EOF
version = '1.1'

[[incoming_vendors]]
# used for:
# shipping patches from upstream before fedora ships them
# things we can't upstream
# ublue-os specific software
vendor = 'Fedora Copr - user ublue-os'
EOF

cat > "/etc/dnf/vendors.d/30-negativo-trusted.conf" << 'EOF'
# we use this for things which fedora can't legally distribute
# like fully enabled versions of video codec related things
version = '1.1'

[[incoming_vendors]]
vendor = 'negativo17.org'
EOF

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_scripts/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl

echo "::endgroup::"
