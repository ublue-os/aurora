#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail


# Patched shell
  dnf5 -y swap \
      --repo=terra-extras \
          kf6-kio kf6-kio.switcheroo-$(rpm -qi kf6-kcoreaddons | awk '/^Version/ {print $3}')

# Switcheroo patch
  dnf5 -y swap \
      --repo=terra-extras \
          switcheroo-control switcheroo-control

# Fix for ID in fwupd - fwupd package needs to be updated in staging copr to 2.x
if [[ "${UBLUE_IMAGE_TAG}" != "beta" ]]; then
  dnf5 -y swap \
      --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
          fwupd fwupd
fi


# TODO: Fedora 41 specific -- re-evaluate with Fedora 42
# negativo's libheif is broken somehow on older Intel machines
# https://github.com/ublue-os/aurora/issues/8
dnf5 -y swap \
    --repo=fedora \
        libheif libheif
        
dnf5 -y swap \
    --repo=fedora \
        heif-pixbuf-loader heif-pixbuf-loader

# Starship Shell Prompt
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> /etc/bashrc

# Bash Prexec
curl --retry 3 -Lo /usr/share/bash-prexec https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh

dnf5 -y swap fedora-logos aurora-logos

# Consolidate Just Files
find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Caps
setcap 'cap_net_raw+ep' /usr/libexec/ksysguard/ksgrd_network_helper

echo "::endgroup::"
