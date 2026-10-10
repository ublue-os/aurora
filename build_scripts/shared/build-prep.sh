#!/usr/bin/bash
# This script should generally set up the build so we can move on to start installing packages

set -eoux pipefail

# Speeds up local builds and workaround network flakes, mainly for COPR and negativo
cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
dnf config-manager setopt keepcache=1 timeout=60

# configuring dnf repos
BUILD_FILES=(
  "/ctx/build_files/shared/"
  )

if [[ "${IMAGE_FLAVOR}" == "dx" ]]; then
  BUILD_FILES+=("/ctx/build_files/dx/")
fi

rsync -rvKl "${BUILD_FILES[@]}" /

if [[ "${UBLUE_IMAGE_TAG}" == "kde-nightly" ]]; then
  cat > /usr/share/dnf5/repos.d/copr:copr.fedorainfracloud.org:solopasha:plasma-unstable.repo << EOF
[copr:copr.fedorainfracloud.org:solopasha:plasma-unstable]
name=Copr repo for plasma-unstable owned by solopasha
baseurl=https://download.copr.fedorainfracloud.org/results/solopasha/plasma-unstable/fedora-\$releasever-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/solopasha/plasma-unstable/pubkey.gpg
repo_gpgcheck=0
enabled=0
enabled_metadata=1
EOF
fi

# mostly for codecs fedora can't ship
dnf config-manager setopt fedora-multimedia.priority=90

# https://fedoraproject.org/wiki/OpenH264
# this would be fine to use as well, negativo just has it, one less repo
dnf config-manager setopt fedora-cisco-openh264.enabled=0

mkdir -p /tmp/scripts/helpers
install -Dm0755 /ctx/build_scripts/shared/utils/ghcurl /tmp/scripts/helpers/ghcurl

echo "::endgroup::"
