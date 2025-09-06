#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

if ! jq -e '.["image-tag"] | test("beta")' /usr/share/ublue-os/image-info.json >/dev/null; then
    echo "Skipping beta for non-beta image"
    exit 0
fi

# install sudo-rs
dnf5 -y install sudo-rs
ln -sf /usr/bin/su-rs /usr/bin/su
ln -sf /usr/bin/sudo-rs /usr/bin/sudo
ln -sf /usr/bin/visudo-rs /usr/bin/visudo

dnf5 -y install eol-rebaser
systemctl enable eol-rebaser.timer

echo "::endgroup::"
