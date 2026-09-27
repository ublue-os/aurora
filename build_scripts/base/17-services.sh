#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

systemctl preset-all
systemctl --global preset-all

echo "::endgroup::"
