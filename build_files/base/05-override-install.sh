#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# switcheroo swap is not needed for F43 ->
if [[ "${FEDORA_MAJOR_VERSION}" -lt "43" ]]; then
dnf5 -y swap \
  --repo="terra-extras" \
  switcheroo-control switcheroo-control
fi

# Fix for ID in fwupd
if [[ "${UBLUE_IMAGE_TAG}" != "beta" ]]; then
dnf5 -y swap \
  --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
  fwupd fwupd
fi

# Explicitly install KDE Plasma related packages with the same version as in base image
dnf5 -y install \
  plasma-firewall-$(rpm -q --qf "%{VERSION}" plasma-desktop)

# install packages from sunshine, scx-scheds and openrazer repos
if [[ "${UBLUE_IMAGE_TAG}" != "beta" ]]; then
  dnf5 -y install sunshine scx-scheds openrazer-daemon
fi

# Offline Aurora documentation
ghcurl "https://github.com/ublue-os/aurora-docs/releases/download/0.1/aurora.pdf" --retry 3 -o /tmp/aurora.pdf
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
find /tmp/just -iname '*.just' ! -name 'aurora-beta.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just

# Caps
setcap 'cap_net_raw+ep' /usr/libexec/ksysguard/ksgrd_network_helper

echo "::endgroup::"
