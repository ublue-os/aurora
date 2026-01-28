#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

echo "Variant=Beta Edition" >> /usr/share/kde-settings/kde-profile/default/xdg/kcm-about-distrorc

echo "::endgroup::"
