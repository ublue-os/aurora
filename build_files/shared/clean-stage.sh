#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Revert back to upstream defaults
mv /etc/dnf/dnf.conf.bak /etc/dnf/dnf.conf
dnf versionlock clear

# This comes last because we can't *ever* afford to ship fedora flatpaks on the image
systemctl disable flatpak-add-fedora-repos.service
systemctl mask flatpak-add-fedora-repos.service
rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

# Relink rpm-ostree-base-db to rpmdb to ensure it correctly reflects the system
# image's rpmdb and doesn't carry over package info from the base image.
# See: https://github.com/coreos/rpm-ostree/issues/4554
# https://forge.fedoraproject.org/atomic/tracker/issues/82
for file in rpmdb.sqlite rpmdb.sqlite-shm rpmdb.sqlite-wal; do
    target="/usr/share/rpm/${file}"
    link_path="/usr/lib/sysimage/rpm-ostree-base-db/${file}"
    if [[ -f "${target}" && -f "${link_path}" ]]; then
        # Note, this needs to be a hardlink, not a symbolic link.
        ln -f "${target}" "${link_path}"
    fi
done

rm -rf /.gitkeep

find /var/* -maxdepth 0 -type d \! -name cache -exec rm -fr {} \;
rm -rf /tmp/*
mkdir -p /var/tmp

# Needs to be here to make the main image build strict (no /opt there)
# This is for downstream images/stuff like k0s
rm -rf /opt && ln -s /var/opt /opt

echo "::endgroup::"
