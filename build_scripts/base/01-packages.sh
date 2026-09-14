#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

# Prevent partial upgrading, major kde version updates black screened
# https://github.com/ublue-os/aurora/issues/1227
dnf versionlock add "qt6-*" "plasma-desktop"

PLASMA_VERS=$(rpm -q --qf "%{VERSION}" plasma-desktop)

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
    plasma-firewall-"${PLASMA_VERS}"
    plasma-oxygen
    plasma-union-"${PLASMA_VERS}"
    plasma-wallpapers-dynamic
    powertop
    rclone
    restic
    samba-winbind{,-clients,-modules}
    setools-console
    setroubleshoot-plugins
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

dnf -y install --enablerepo='fedora-multimedia' "${PACKAGES[@]}"

# Fedora Tailscale is usually behind
dnf -y install --from-repo='tailscale-stable' tailscale

COPR_UBLUE_OS_PACKAGES=(
    kcm_ublue
    krunner-bazaar
    oversteer-udev
    # https://github.com/ublue-os/akmods/issues/537
    ublue-os-selinux-workarounds
    uupd
  )

dnf -y install --from-repo='copr:copr.fedorainfracloud.org:ublue-os:packages' "${COPR_UBLUE_OS_PACKAGES[@]}"

dnf -y install --from-repo='copr:copr.fedorainfracloud.org:ledif:kairpods' kairpods

dnf -y install --from-repo='copr:copr.fedorainfracloud.org:lizardbyte:stable' sunshine

# Packages to exclude - common to all versions
EXCLUDED_PACKAGES=(
    akonadi-server{,-mysql}
    default-fonts-cjk-sans
    fedora-bookmarks
    fedora-chromium-config{,-kde}
    fedora-third-party
    firefox
    firewall-config
    kcharselect
    khelpcenter
    krfb{,-libs}
    plasma-discover{,-libs}
    plasma-welcome-fedora
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
dnf -y swap --from-repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
  plasma-setup plasma-setup-"${PLASMA_VERS}"-*.aurora

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
