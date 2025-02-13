#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail


# Patched shell
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        kf6-kio kf6-kio


# Make sure KDE Frameworks and our kf6-kio are on the same version
kf6_version=$(rpm -qi kf6-kcoreaddons | awk '/^Version/ {print $3}')
kf6_kio_version=$(rpm -qi kf6-kio-core | awk '/^Version/ {print $3}')

if [[ "$kf6_version" != "$kf6_kio_version" ]]; then
    echo "Mismatched kf6-kio version $kf6_kio_version. Bump ublue-os/packages kf6-kio to $kf6_version"
    exit 1
fi

# Fix for ID in fwupd
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        fwupd fwupd

# Switcheroo patch
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:sentry:switcheroo-control_discrete \
        switcheroo-control switcheroo-control

dnf5 -y copr remove sentry/switcheroo-control_discrete

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
curl --retry 3 -Lo /tmp/starship.tar.gz "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> /etc/bashrc

# Bash Prexec
curl --retry 3 -Lo /usr/share/bash-prexec https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh

# Consolidate Just Files
find /tmp/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Register Fonts
fc-cache -f /usr/share/fonts/ubuntu
fc-cache -f /usr/share/fonts/inter

# Caps
setcap 'cap_net_raw+ep' /usr/libexec/ksysguard/ksgrd_network_helper

echo "::endgroup::"
