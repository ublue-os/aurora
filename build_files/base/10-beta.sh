#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail


if ! jq -e '.["image-tag"] | test("beta|latest")' /usr/share/ublue-os/image-info.json >/dev/null; then
    echo "We only run this on latest and beta"
    exit 0
fi



echo "::endgroup::"
