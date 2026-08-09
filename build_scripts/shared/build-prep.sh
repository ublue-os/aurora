# This script should generally set up the build so we can move on to start installing packages

#!/usr/bin/bash

set -eoux pipefail

# Speeds up local builds and workaround network flakes, mainly for COPR and negativo
cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
dnf config-manager setopt keepcache=1 timeout=60

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_scripts/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl

echo "::endgroup::"
