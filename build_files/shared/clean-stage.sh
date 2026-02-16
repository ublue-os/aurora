#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Revert back to upstream defaults
dnf config-manager setopt keepcache=0

# This comes last because we can't *ever* afford to ship fedora flatpaks on the image
systemctl mask flatpak-add-fedora-repos.service
rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

# reinvestigate when https://github.com/ostreedev/ostree/pull/3559 reached fedora
mv '/usr/share/doc/just/README.中文.md' '/usr/share/doc/just/README.zh-cn.md'

rm -rf /.gitkeep

# https://bootc-dev.github.io/bootc/filesystem.html#filesystem
rm -rf /{var,tmp,boot}
mkdir -p /{var,tmp,boot}
find /run/* -maxdepth 0 -type d \
  \! -name .containerenv \
  \! -name secrets \
  \! -name systemd \
  -exec rm -fr {} \;

echo "::endgroup::"
