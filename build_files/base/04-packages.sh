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
    kde-runtime-docs
    krb5-workstation
    ksystemlog
    libimobiledevice
    libsss_autofs
    libxcrypt-compat
    lm_sensors
    make
    oddjob-mkhomedir
    plasma-wallpapers-dynamic
    powertop
    ptyxis
    python3-pip
    rclone
    restic
    samba-winbind
    samba-winbind-clients
    samba-winbind-modules
    setools-console
    sssd-ad
    sssd-ipa
    sssd-krb5
    tailscale
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
        # No additional Fedora packages for 43
        ;;
esac

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf5 -y install "${FEDORA_PACKAGES[@]}"

# Install COPR packages using isolated enablement (secure)
echo "Installing COPR packages with isolated repo enablement..."

# From ublue-os/staging
copr_install_isolated "ublue-os/staging" \
    "fw-fanctrl"

# From ublue-os/packages
copr_install_isolated "ublue-os/packages" \
    "aurora-backgrounds" \
    "bazaar" \
    "krunner-bazaar" \
    "kcm_ublue" \
    "ublue-bling" \
    "ublue-branding-logos" \
    "ublue-brew" \
    "ublue-fastfetch" \
    "ublue-motd" \
    "ublue-polkit-rules" \
    "ublue-setup-services"

# Version-specific COPR packages
case "$FEDORA_MAJOR_VERSION" in
    42)
        # uupd from ublue-os/packages for F42
        copr_install_isolated "ublue-os/packages" "uupd"

        # OpenRazer from hardware:razer repo (not a COPR)
        dnf5 -y config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo
        dnf5 -y install openrazer-daemon
        sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/hardware:razer.repo

        # Sunshine from lizardbyte/beta COPR
        copr_install_isolated "lizardbyte/beta" "sunshine"
        ;;
    43)
        # No additional COPR packages for F43
        # nerd fonts, sunshine and openrazer-daemon are excluded for F43
        ;;
esac

# kAirpods from ledif/kairpods COPR
copr_install_isolated "ledif/kairpods" \
    "kairpods"

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
            fw-fanctrl
            sunshine
            openrazer-daemon
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

if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t EXCLUDED_PACKAGES < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}")
fi

# TODO: remove me on next flatpak release when preinstall landed
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
    dnf5 -y copr enable ublue-os/flatpak-test
    dnf5 -y copr disable ublue-os/flatpak-test
    dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
    dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
    dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
    # print information about flatpak package, it should say from our copr
    rpm -q flatpak --qf "%{NAME} %{VENDOR}\n" | grep ublue-os
fi

# Explicitly install KDE Plasma related packages with the same version as in base image
dnf5 -y install \
    plasma-firewall-$(rpm -q --qf "%{VERSION}" plasma-desktop)

# Swap/install aurora branding packages from ublue-os/packages COPR using isolated enablement
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:packages \
    fedora-logos aurora-logos
dnf5 -y install \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:packages \
    aurora-kde-config \
    aurora-plymouth

echo "::endgroup::"
