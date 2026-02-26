#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Revert back to upstream defaults
dnf config-manager setopt keepcache=0
dnf versionlock clear

# This comes last because we can't *ever* afford to ship fedora flatpaks on the image
systemctl mask flatpak-add-fedora-repos.service
rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

# reinvestigate when https://github.com/ostreedev/ostree/pull/3559 reached fedora
mv '/usr/share/doc/just/README.中文.md' '/usr/share/doc/just/README.zh-cn.md'

rm -rf /.gitkeep

rm -rf /var/ && mkdir -p /var/tmp

# Needs to be here to make the main image build strict (no /opt there)
# This is for downstream images/stuff like k0s
rm -rf /opt && ln -s /var/opt /opt

echo "::endgroup::"
