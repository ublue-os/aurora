#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Current aurora systems have the bling.sh and bling.fish in their default locations
mkdir -p /usr/share/ublue-os/aurora-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/aurora-cli

# Try removing just docs (is it actually promblematic?)
rm -rf /usr/share/doc/just/README.*.md

echo "::endgroup::"
