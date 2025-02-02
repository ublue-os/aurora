#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# alternatives cannot create symlinks on its own during a container build
if [[ -f "/usr/bin/ld.bfd" ]]; then
    ln -sf /usr/bin/ld.bfd /etc/alternatives/ld && ln -sf /etc/alternatives/ld /usr/bin/ld
fi

## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
# Remember to leave a note with rationale/link to issue for each pin!
#
# Example:
#if [ "$FEDORA_MAJOR_VERSION" -eq "41" ]; then
#    Workaround pkcs11-provider regression, see issue #1943
#    rpm-ostree override replace https://bodhi.fedoraproject.org/updates/FEDORA-2024-dd2e9fb225
#fi

# Current aurora systems have the bling.sh and bling.fish in their default locations
mkdir -p /usr/share/ublue-os/aurora-cli
cp /usr/share/ublue-os/bling/* /usr/share/ublue-os/aurora-cli

# Copy flatpak list on image to compare against it on boot wo/ requiring curl to gh
FLATPAK_LIST=($(curl https://raw.githubusercontent.com/ublue-os/aurora/main/aurora_flatpaks/flatpaks))
if [[ ${IMAGE_NAME} =~ "dx" ]]; then
    FLATPAK_LIST+=($(curl https://raw.githubusercontent.com/ublue-os/aurora/main/dx_flatpaks/flatpaks))
fi
printf "%s\n" "${FLATPAK_LIST[@]}" > /usr/share/ublue-os/flatpak_list

echo "::endgroup::"
