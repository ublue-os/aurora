#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Current aurora systems have the bling.sh and bling.fish in their default locations
mkdir -p /usr/share/ublue-os/aurora-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/aurora-cli

# Remove the akmods recipes from ujust, which at the moment only contains
# the broken broadcom wl module recipe
sed -i 's|^import "/usr/share/ublue-os/just/50-akmods.just"|#import "/usr/share/ublue-os/just/50-akmods.just"|' /usr/share/ublue-os/justfile

echo "::endgroup::"
