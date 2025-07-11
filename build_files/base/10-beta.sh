#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

if ! jq -e '.["image-tag"] | test("beta")' /usr/share/ublue-os/image-info.json >/dev/null; then
    echo "Skipping beta for non-beta image"
    exit 0
fi

sudo dnf5 install -y bazaar krunner-bazaar

# For new users, enable Bazaar in KRunner + disable Discover results
cat >> /usr/share/kde-settings/kde-profile/default/xdg/krunnerrc << 'EOF'
krunner_appstreamEnabled=false
bazaarrunnerEnabled=true
EOF

if jq -e '.["image-flavor"] | test("nvidia")' /usr/share/ublue-os/image-info.json >/dev/null; then
  sed -i 's|^Exec=bazaar window --auto-service$|Exec=env GSK_RENDERER=opengl bazaar window --auto-service|' /usr/share/applications/io.github.kolunmi.Bazaar.desktop
fi

echo "::endgroup::"
