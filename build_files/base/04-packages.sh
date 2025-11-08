#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# All DNF-related operations should be done here whenever possible
#shellcheck source=build_files/shared/copr-helpers.sh
source /ctx/build_files/shared/copr-helpers.sh

# NOTE:
# Packages are split into FEDORA_PACKAGES and COPR_PACKAGES to prevent
# malicious COPRs from injecting fake versions of Fedora packages.
# Fedora packages are installed first in bulk (safe).
# COPR packages are installed individually with isolated enablement.

# Base packages from Fedora repos - common to all versions

# Prevent partial upgrading, major kde version updates black screened
# https://github.com/ublue-os/aurora/issues/1227
dnf5 versionlock add plasma-desktop

FEDORA_PACKAGES=(
    adcli
    borgbackup
    davfs2
    evtest
    fastfetch
    fish
    foo2zjs
    freeipa-client
    git-credential-libsecret
    glow
    gum
    ifuse
    igt-gpu-tools
    input-remapper
    iwd
    kcm-fcitx5
    krb5-workstation
    ksystemlog
    libimobiledevice
    libsss_autofs
    libxcrypt-compat
    lm_sensors
    oddjob-mkhomedir
    plasma-wallpapers-dynamic
    powertop
    ptyxis
    rclone
    restic
    samba-winbind
    samba-winbind-clients
    samba-winbind-modules
    setools-console
    sssd-ad
    sssd-ipa
    sssd-krb5
    tmux
    virtualbox-guest-additions
    wireguard-tools
    wl-clipboard
    zsh
)

# Version-specific Fedora package additions
case "$FEDORA_MAJOR_VERSION" in
    42)
        FEDORA_PACKAGES+=(
            google-noto-fonts-all
            uld
        )
        ;;
    43)
        FEDORA_PACKAGES+=(
        )
        ;;
esac

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf5 -y install "${FEDORA_PACKAGES[@]}"

# Install tailscale package from their repo
echo "Installing tailscale from official repo..."
dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf config-manager setopt tailscale-stable.enabled=0
dnf -y install --enablerepo='tailscale-stable' tailscale

# Install COPR packages using isolated enablement (secure)
echo "Installing COPR packages with isolated repo enablement..."

# OpenRazer from hardware:razer repo (not a COPR)
        dnf5 -y config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
        dnf5 -y install openrazer-daemon
        sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/hardware:razer.repo

# From ublue-os/staging
copr_install_isolated "ublue-os/staging" \
    "fw-fanctrl"

# From ublue-os/packages
copr_install_isolated "ublue-os/packages" \
    "aurora-backgrounds" \
    "krunner-bazaar" \
    "kcm_ublue" \
    "ublue-bling" \
    "ublue-branding-logos" \
    "ublue-brew" \
    "ublue-fastfetch" \
    "ublue-motd" \
    "ublue-polkit-rules" \
    "ublue-setup-services" \
    "uupd"

# Version-specific COPR packages
case "$FEDORA_MAJOR_VERSION" in
    42)

        ;;
    43)

        ;;
esac

# kAirpods from ledif/kairpods COPR
copr_install_isolated "ledif/kairpods" \
    "kairpods"

# Sunshine from lizardbyte/beta COPR
copr_install_isolated "lizardbyte/beta" \
    "sunshine"

# Packages to exclude - common to all versions
EXCLUDED_PACKAGES=(
    fedora-bookmarks
    fedora-chromium-config
    fedora-chromium-config-kde
    firefox
    firefox-langpacks
    firewall-config
    kcharselect
    krfb
    krfb-libs
    plasma-discover-kns
    plasma-welcome-fedora
    podman-docker
)

# Version-specific package exclusions
case "$FEDORA_MAJOR_VERSION" in
    43)
        EXCLUDED_PACKAGES+=(

        )
        ;;
esac

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf5 -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

# we can't remove plasma-lookandfeel-fedora package because it is a dependency of plasma-desktop
rpm --erase --nodeps plasma-lookandfeel-fedora
# rpm erase doesn't remove actual files
rm -rf /usr/share/plasma/look-and-feel/org.fedoraproject.fedora.desktop/

# Install Terra repo (for switcheroo-control on F42 and earlier)
# shellcheck disable=SC2016
thirdparty_repo_install "terra" \
                       'terra,https://repos.fyralabs.com/terra$releasever' \
                       "terra-release" \
                       "terra-release-extras" \
                       "terra*"

# switcheroo swap is not needed for F43 ->
if [[ "${FEDORA_MAJOR_VERSION}" -lt "43" ]]; then
    dnf5 -y swap \
        --repo=terra-extras \
        switcheroo-control switcheroo-control
fi

# https://github.com/ublue-os/bazzite/issues/1400
# TODO: test if we still need this when upgrading firmware with fwupd
dnf5 -y swap \
  --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
  fwupd fwupd

# TODO: remove me on next flatpak release when preinstall landed
dnf5 -y copr enable ublue-os/flatpak-test
dnf5 -y copr disable ublue-os/flatpak-test
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper

## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
# Remember to leave a note with rationale/link to issue for each pin!
#
# Example:
#if [ "$FEDORA_MAJOR_VERSION" -eq "42" ]; then
#    Workaround pkcs11-provider regression, see issue #1943
#    dnf5 upgrade --refresh --advisory=FEDORA-2024-dd2e9fb225
#fi

# Explicitly install KDE Plasma related packages with the same version as in base image
dnf5 -y install \
    plasma-firewall-$(rpm -q --qf "%{VERSION}" plasma-desktop)

# Swap/install aurora branding packages from ublue-os/packages COPR using isolated enablement
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:packages \
    fedora-logos aurora-logos

echo "::endgroup::"
