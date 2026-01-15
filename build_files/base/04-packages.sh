#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# use negativo17 for 3rd party packages with higher priority than default
if ! grep -q fedora-multimedia <(dnf5 repolist); then
    # Enable or Install Repofile
    dnf5 config-manager setopt fedora-multimedia.enabled=1 ||
        dnf5 config-manager addrepo --from-repofile="https://negativo17.org/repos/fedora-multimedia.repo"
fi
# Set higher priority
dnf5 config-manager setopt fedora-multimedia.priority=90

# Add Flathub to the image for eventual application
mkdir -p /etc/flatpak/remotes.d/
curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

# may break SDDM/KWin when upgraded
dnf5 versionlock add "qt6-*"

# use override to replace mesa and others with less crippled versions
OVERRIDES=(
    "intel-gmmlib"
    "intel-mediasdk"
    "intel-vpl-gpu-rt"
    "libheif"
    "libva"
    "libva-intel-media-driver"
    "mesa-dri-drivers"
    "mesa-filesystem"
    "mesa-libEGL"
    "mesa-libGL"
    "mesa-libgbm"
    "mesa-va-drivers"
    "mesa-vulkan-drivers"
)

dnf5 distro-sync --skip-unavailable -y --repo='fedora-multimedia' "${OVERRIDES[@]}"
dnf5 versionlock add "${OVERRIDES[@]}"
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
    alsa-firmware
    apr
    apr-util
    borgbackup
    davfs2
    distrobox
    evtest
    fastfetch
    fcitx5-chinese-addons
    fcitx5-configtool
    fcitx5-gtk
    fcitx5-hangul
    fcitx5-libthai
    fcitx5-mozc
    fcitx5-qt
    fcitx5-sayura
    fcitx5-unikey
    fdk-aac
    ffmpeg
    ffmpeg-libs
    fish
    flatpak-spawn
    foo2zjs
    freeipa-client
    git-credential-libsecret
    glow
    google-noto-sans-balinese-fonts
    google-noto-sans-cjk-fonts
    google-noto-sans-javanese-fonts
    google-noto-sans-sundanese-fonts
    grub2-tools-extra
    gum
    gvfs
    gvfs-fuse
    heif-pixbuf-loader
    htop
    icoutils
    ifuse
    igt-gpu-tools
    input-remapper
    intel-vaapi-driver
    iwd
    just
    kate
    kcm-fcitx5
    krb5-workstation
    ksshaskpass
    ksystemlog
    libavcodec
    libcamera-gstreamer
    libcamera-tools
    libfdk-aac
    libheif
    libimobiledevice
    libimobiledevice-utils
    libratbag-ratbagd
    libsss_autofs
    libva-utils
    libxcrypt-compat
    lm_sensors
    lshw
    nvtop
    oddjob-mkhomedir
    openrgb-udev-rules
    pam-u2f
    pam_yubico
    pamu2fcfg
    pipewire-libs-extra
    plasma-wallpapers-dynamic
    powerstat
    powertop
    ptyxis
    rclone
    restic
    samba-winbind
    samba-winbind-clients
    samba-winbind-modules
    setools-console
    solaar-udev
    squashfs-tools
    sssd-ad
    sssd-ipa
    sssd-krb5
    symlinks
    tcpdump
    tmux
    traceroute
    uld
    vim
    virtualbox-guest-additions
    wireguard-tools
    wl-clipboard
    yubikey-manager
    zsh
)

# Version-specific Fedora package additions
case "$FEDORA_MAJOR_VERSION" in
    43)
        FEDORA_PACKAGES+=(
        )
        ;;
    44)
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
    "kcm_ublue" \
    "krunner-bazaar" \
    "oversteer-udev" \
    "uupd"

# Version-specific COPR packages
# Example:
# copr_install_isolated "ublue-os/packages" "bazaar" "uupd"
case "$FEDORA_MAJOR_VERSION" in
    43)

        ;;
    44)

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
    akonadi-server
    akonadi-server-mysql
    default-fonts-cjk-sans
    fedora-bookmarks
    fedora-chromium-config
    fedora-chromium-config-kde
    fedora-third-party
    ffmpegthumbnailer
    firefox
    firefox-langpacks
    firewall-config
    google-noto-sans-cjk-vf-fonts
    kcharselect
    khelpcenter
    krfb
    krfb-libs
    mariadb
    mariadb-common
    mariadb-errmsg
    plasma-discover-kns
    plasma-discover-rpm-ostree
    plasma-welcome-fedora
    podman-docker
)

# Version-specific package exclusions
case "$FEDORA_MAJOR_VERSION" in
    43)
        EXCLUDED_PACKAGES+=()
        ;;
    44)
        EXCLUDED_PACKAGES+=()
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


# https://github.com/ublue-os/bazzite/issues/1400
# TODO: test if we still need this when upgrading firmware with fwupd
dnf5 -y swap \
  --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
  fwupd fwupd

# TODO: remove me on next flatpak release when preinstall landed in Fedora
dnf5 -y copr enable ublue-os/flatpak-test
dnf5 -y copr disable ublue-os/flatpak-test
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test install flatpak-debuginfo flatpak-libs-debuginfo flatpak-session-helper-debuginfo

## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
# Remember to leave a note with rationale/link to issue for each pin!
#
# Example:
#if [ "$FEDORA_MAJOR_VERSION" -eq "42" ]; then
#    Workaround pkcs11-provider regression, see issue #1943
#    dnf5 upgrade --refresh --advisory=FEDORA-2024-dd2e9fb225
#fi

# mitigate upstream packaging bug: https://bugzilla.redhat.com/show_bug.cgi?id=2332429
# swap the incorrectly installed OpenCL-ICD-Loader for ocl-icd, the expected package
dnf5 -y swap --repo='fedora' \
    OpenCL-ICD-Loader ocl-icd

# Explicitly install KDE Plasma related packages with the same version as in base image
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
  dnf -y copr enable @kdesig/kde-beta
  dnf -y copr disable @kdesig/kde-beta
  dnf -y --repo=copr:copr.fedorainfracloud.org:group_kdesig:kde-beta swap plasma-firewall plasma-firewall
else
  dnf -y install \
    plasma-firewall-$(rpm -q --qf "%{VERSION}" plasma-desktop)
fi

echo "::endgroup::"
