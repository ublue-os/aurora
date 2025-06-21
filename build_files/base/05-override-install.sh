#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Patched shell and switcheroo-control
dnf5 -y swap \
  --repo="terra-extras" \
  kf6-kio kf6-kio-$(rpm -q --qf "%{VERSION}" kf6-kcoreaddons)

dnf5 -y swap \
  --repo="terra-extras" \
  switcheroo-control switcheroo-control

# Fix for ID in fwupd
dnf5 -y swap \
  --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
  fwupd fwupd

# Explicitly install KDE Plasma related packages with the same version as in base image
dnf5 -y install \
  plasma-firewall-$(rpm -q --qf "%{VERSION}" plasma-desktop)

# Offline Aurora documentation
curl --retry 3 -Lo /tmp/aurora.pdf https://github.com/ublue-os/aurora-docs/releases/download/0.1/aurora.pdf
install -Dm0644 -t /usr/share/doc/aurora/ /tmp/aurora.pdf

# Starship Shell Prompt
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> /etc/bashrc

# Bash Prexec
curl --retry 3 -Lo /usr/share/bash-prexec https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh

dnf5 -y swap fedora-logos aurora-logos
dnf5 -y install aurora-kde-config
dnf5 -y install aurora-plymouth

# Consolidate Just Files
find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just

# Caps
setcap 'cap_net_raw+ep' /usr/libexec/ksysguard/ksgrd_network_helper

echo "::endgroup::"
