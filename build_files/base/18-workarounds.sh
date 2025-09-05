#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
# Remember to leave a note with rationale/link to issue for each pin!
# Use dnf list --showduplicates package

# Workaround atheros-firmware regression
# see https://bugzilla.redhat.com/show_bug.cgi?id=2365882
# dnf -y swap atheros-firmware atheros-firmware-20250311-1$(rpm -E %{dist})

# Current aurora systems have the bling.sh and bling.fish in their default locations
mkdir -p /usr/share/ublue-os/aurora-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/aurora-cli

# Try removing just docs (is it actually promblematic?)
rm -rf /usr/share/doc/just/README.*.md

# NVIDIA GTK4 bug
# https://github.com/ublue-os/aurora/issues/841
if jq -e '.["image-flavor"] | test("nvidia")' /usr/share/ublue-os/image-info.json >/dev/null; then
  echo "GSK_RENDERER=ngl" >/usr/lib/environment.d/gsk.conf
fi

echo "::endgroup::"
