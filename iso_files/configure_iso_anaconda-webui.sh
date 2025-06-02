#!/usr/bin/env bash

set -eoux pipefail

IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
IMAGE_TAG="$(jq -c -r '."image-tag"' <<<"$IMAGE_INFO")"
IMAGE_REF="$(jq -c -r '."image-ref"' <<<"$IMAGE_INFO")"
IMAGE_REF="${IMAGE_REF##*://}"
sbkey='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der'

# Configure Live Environment
## Remove packages from liveCD to save space
dnf remove -y google-noto-fonts-all ublue-brew ublue-motd || true

glib-compile-schemas /usr/share/glib-2.0/schemas

systemctl disable rpm-ostree-countme.service
systemctl disable tailscaled.service
systemctl disable bootloader-update.service
systemctl disable brew-upgrade.timer
systemctl disable brew-update.timer
systemctl disable brew-setup.service
systemctl disable rpm-ostreed-automatic.timer
systemctl disable uupd.timer
systemctl disable ublue-system-setup.service
systemctl disable ublue-guest-user.service
systemctl disable check-sb-key.service
systemctl --global disable ublue-flatpak-manager.service
systemctl --global disable podman-auto-update.timer
systemctl --global disable ublue-user-setup.service

# Configure Anaconda

# Install Anaconda WebUI
SPECS=(
    "libblockdev-btrfs"
    "libblockdev-lvm"
    "libblockdev-dm"
    "anaconda-live"
    "anaconda-webui"
)
dnf install -y "${SPECS[@]}"

# swap webui package to copr
dnf -y copr enable @rhinstaller/Anaconda-webui
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:group_rhinstaller:Anaconda-webui \
    anaconda-webui anaconda-webui

# Anaconda Profile Detection

# Aurora
tee /etc/anaconda/profile.d/aurora.conf <<'EOF'
# Anaconda configuration file for Aurora Stable

[Profile]
# Define the profile.
profile_id = aurora

[Profile Detection]
# Match os-release values
os_id = aurora

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = fedora
menu_auto_hide = True

[Storage]
default_scheme = BTRFS
btrfs_compression = zstd:1
default_partitioning =
    /     (min 1 GiB, max 70 GiB)
    /home (min 500 MiB, free 50 GiB)
    /var  (btrfs)

[User Interface]
custom_stylesheet = /usr/share/anaconda/pixmaps/fedora.css
hidden_spokes =
    NetworkSpoke
    PasswordSpoke
hidden_webui_pages =
    root-password
    network

[Localization]
use_geolocation = False
EOF

# Configure
. /etc/os-release
echo "Aurora release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release

sed -i 's/ANACONDA_PRODUCTVERSION=.*/ANACONDA_PRODUCTVERSION=""/' /usr/{,s}bin/liveinst || true
sed -i 's|^Icon=.*|Icon=/usr/share/anaconda/pixmaps/fedora-logo-icon.png|' /usr/share/applications/liveinst.desktop || true

# Get Artwork
git clone --depth=1 https://github.com/ublue-os/packages.git /root/packages
mkdir -p /usr/share/anaconda/pixmaps/
cp -r /root/packages/aurora/fedora-logos/src/anaconda/* /usr/share/anaconda/pixmaps/
rm -rf /root/packages

# Interactive Kickstart
tee -a /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=$IMAGE_REF:$IMAGE_TAG --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
%include /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
EOF

# Signed Images
tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $IMAGE_REF:$IMAGE_TAG
%end
EOF

# Disable Fedora Flatpak
tee /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks <<'EOF'
%post --erroronfail
systemctl disable flatpak-add-fedora-repos.service
%end
EOF

# Install Flatpaks
tee /usr/share/anaconda/post-scripts/install-flatpaks.ks <<'EOF'
%post --erroronfail --nochroot
deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0/var/lib/"
mkdir -p "$target"
rsync -aAXUHKP /var/lib/flatpak "$target"
%end
EOF

# Fetch the Secureboot Public Key
curl --retry 15 -Lo /etc/sb_pubkey.der "$sbkey"

# Enroll Secureboot Key
tee /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks <<'EOF'
%post --erroronfail --nochroot
set -oue pipefail

readonly ENROLLMENT_PASSWORD="universalblue"
readonly SECUREBOOT_KEY="/etc/sb_pubkey.der"

if [[ ! -d "/sys/firmware/efi" ]]; then
    echo "EFI mode not detected. Skipping key enrollment."
    exit 0
fi

if [[ ! -f "$SECUREBOOT_KEY" ]]; then
    echo "Secure boot key not provided: $SECUREBOOT_KEY"
    exit 0
fi

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"
if [[ ":Jupiter:Galileo:" =~ ":$SYS_ID:" ]]; then
    echo "Steam Deck hardware detected. Skipping key enrollment."
    exit 0
fi

mokutil --timeout -1 || :
echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "$SECUREBOOT_KEY" || :
%end
EOF
