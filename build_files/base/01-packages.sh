#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# may break when partially upgraded
dnf versionlock add "qt6-*" "plasma-desktop"

PLASMA_VERS=$(rpm -q --qf "%{VERSION}" plasma-desktop)

# use override to replace mesa and others with less crippled versions
dnf config-manager addrepo --from-repofile="https://negativo17.org/repos/fedora-multimedia.repo"
dnf config-manager setopt fedora-multimedia.priority=90

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

FEDORA_PACKAGES=(
    adcli
    alsa-firmware
    apr{,-util}
    autofs
    borgbackup
    davfs2
    distrobox
    evtest
    fastfetch
    fcitx5-{chewing,chinese-addons,configtool,gtk,hangul,libthai,m17n,mozc,qt,sayura,unikey}
    fish
    flatpak-spawn
    foo2zjs
    gcc{,-c++}
    git-credential-libsecret
    glow
    google-noto-sans-balinese-fonts
    google-noto-sans-cjk-fonts
    google-noto-sans-javanese-fonts
    google-noto-sans-sundanese-fonts
    grub2-tools-extra
    gum
    gvfs{,-fuse}
    htop
    icoutils
    ifuse
    igt-gpu-tools
    input-remapper
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
    libimobiledevice-utils
    libratbag-ratbagd
    libxcrypt-compat
    lm_sensors
    lshw
    nvtop
    oddjob-mkhomedir
    openrgb-udev-rules
    pam-u2f
    pam_yubico
    pamu2fcfg
    plasma-wallpapers-dynamic
    plasma-firewall-"${PLASMA_VERS}"
    powerstat
    powertop
    rclone
    restic
    samba-winbind{,-clients,-modules}
    setools-console
    solaar-udev
    squashfs-tools
    symlinks
    tcpdump
    tesseract-devel
    tmux
    tesseract-langpack-{eng,deu,fra,spa,por,ita,pol,fin,nld,jpn,jpn_vert,hin,chi_sim,chi_sim_vert,chi_tra,chi_tra_vert}
    traceroute
    vim
    yubikey-manager
    zsh
)

NEGATIVO_PACKAGES=(
    ffmpeg{,-libs}
    intel-vaapi-driver
    libfdk-aac
    libva-utils
    pipewire-libs-extra
    uld
  )

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos and ${#NEGATIVO_PACKAGES[@]} from Negativo..."
dnf5 -y install "${FEDORA_PACKAGES[@]}" "${NEGATIVO_PACKAGES[@]}"

# Fedora Tailscale is usually behind
dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf config-manager setopt tailscale-stable.enabled=0
dnf -y install --enablerepo='tailscale-stable' tailscale

# From ublue-os/packages
copr_install_isolated "ublue-os/packages" \
    "kcm_ublue" \
    "krunner-bazaar" \
    "oversteer-udev" \
    "uupd"

# kAirpods from ledif/kairpods COPR
copr_install_isolated "ledif/kairpods" \
    "kairpods"

# Sunshine from lizardbyte/beta COPR
copr_install_isolated "lizardbyte/beta" \
    "sunshine"

# Packages to exclude - common to all versions
EXCLUDED_PACKAGES=(
    akonadi-server{,-mysql}
    default-fonts-cjk-sans
    fedora-bookmarks
    fedora-chromium-config{,-kde}
    fedora-third-party
    ffmpegthumbnailer
    firefox
    firewall-config
    google-noto-sans-cjk-vf-fonts
    kcharselect
    khelpcenter
    krfb{,-libs}
    plasma-discover{,-libs}
    plasma-welcome-fedora
    podman-docker
)

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf5 -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

# https://github.com/ublue-os/bazzite/issues/1400
# TODO: test if we still need this when upgrading firmware with fwupd
dnf -y copr enable ublue-os/staging
dnf -y copr disable ublue-os/staging
dnf -y swap \
  --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
  fwupd fwupd

## Pins and Overrides
## Use this section to pin packages in order to avoid regressions
# Remember to leave a note with rationale/link to issue for each pin!
#
# Example:
#if [ "$FEDORA_MAJOR_VERSION" -eq "42" ]; then
#    Workaround pkcs11-provider regression, see issue #1943
#    dnf5 upgrade --refresh --advisory=FEDORA-2024-dd2e9fb225
#fi

# https://invent.kde.org/plasma/plasma-setup/-/issues/72
dnf -y swap --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
  plasma-setup plasma-setup-"${PLASMA_VERS}"-*.aurora

dnf versionlock add plasma-setup

# Install DX specific packages
if [[ "${IMAGE_FLAVOR}" == "dx" ]]; then
  /ctx/build_files/dx/00-dx.sh
fi

echo "::endgroup::"
