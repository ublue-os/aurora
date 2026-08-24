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
#shellcheck source=build_scripts/shared/copr-helpers.sh
source /ctx/build_scripts/shared/copr-helpers.sh

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
    google-noto-sans-cham-fonts
    google-noto-sans-cjk-fonts
    google-noto-sans-javanese-fonts
    google-noto-sans-linear-a-fonts
    google-noto-sans-linear-b-fonts
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
    ksystemlog
    libcamera-gstreamer
    libcamera-tools
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
    plasma-union-"${PLASMA_VERS}"
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
    tesseract-langpack-{deu,fra,spa,por,ita,pol,fin,nld,jpn,jpn_vert,hin,chi_sim,chi_sim_vert,chi_tra,chi_tra_vert}
    tmux
    traceroute
    vim
    yubikey-manager
    zsh
)

FEDORA_PACKAGES_AMD64=(
    powerstat
  )

NEGATIVO_PACKAGES=(
    ffmpeg{,-libs}
    libavcodec
    libfdk-aac
    libva-utils
    pipewire-libs-extra
    uld
  )

NEGATIVO_PACKAGES_AMD64=(
    intel-vaapi-driver
  )

PACKAGES=( "${FEDORA_PACKAGES[@]}" "${NEGATIVO_PACKAGES[@]}" )

if [[ $(arch) == x86_64 ]]; then
  PACKAGES+=( "${FEDORA_PACKAGES_AMD64[@]}" "${NEGATIVO_PACKAGES_AMD64[@]}" )
fi

dnf -y install "${PACKAGES[@]}"

# Fedora Tailscale is usually behind
dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf config-manager setopt tailscale-stable.enabled=0
dnf -y install --enablerepo='tailscale-stable' tailscale

# NOTE: Remove ublue-os-selinux-workarounds package when upstream issue is fixed
# https://github.com/ublue-os/akmods/issues/537
# From ublue-os/packages
copr_install_isolated "ublue-os/packages" \
    "kcm_ublue" \
    "krunner-bazaar" \
    "ublue-os-selinux-workarounds" \
    "oversteer-udev" \
    "uupd"

# kAirpods from ledif/kairpods COPR
copr_install_isolated "ledif/kairpods" \
    "kairpods"

# Sunshine from lizardbyte/stable COPR
copr_install_isolated "lizardbyte/stable" \
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
    kcharselect
    khelpcenter
    krfb{,-libs}
    plasma-discover{,-libs}
    plasma-welcome-fedora
    podman-docker
)

dnf -y remove "${EXCLUDED_PACKAGES[@]}"

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
dnf -y copr enable ublue-os/staging
dnf -y copr disable ublue-os/staging
dnf -y swap --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
  plasma-setup plasma-setup-"${PLASMA_VERS}"-*.aurora

# https://github.com/ostreedev/ostree/issues/3635
dnf -y swap --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
  ostree ostree

dnf versionlock add plasma-setup

# Install DX specific packages
if [[ "${IMAGE_FLAVOR}" == "dx" ]]; then
  /ctx/build_scripts/dx/00-dx.sh
fi

# Keep *-logos in RPM DB for downstream package installations
# We are not allowed to ship an empty fedora-logos package
dnf -y swap fedora-logos generic-logos
rpm --erase --nodeps --nodb generic-logos

echo "::endgroup::"
