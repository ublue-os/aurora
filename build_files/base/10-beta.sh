#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

if ! jq -e '.["image-tag"] | test("beta")' /usr/share/ublue-os/image-info.json >/dev/null; then
    echo "Skipping beta for non-beta image"
    exit 0
fi

sudo dnf5 install -y bazaar krunner-bazaar

if jq -e '.["image-flavor"] | test("nvidia")' /usr/share/ublue-os/image-info.json >/dev/null; then
  sed -i 's|^Exec=bazaar window --auto-service$|Exec=env GSK_RENDERER=opengl bazaar window --auto-service|' /usr/share/applications/io.github.kolunmi.Bazaar.desktop
fi

echo "::endgroup::"
