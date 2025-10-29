#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail


if ! jq -e '.["image-tag"] | test("beta|latest")' /usr/share/ublue-os/image-info.json >/dev/null; then
    echo "We only run this on latest and beta"
    exit 0
fi

PLASMA_VERSION=$(rpm -q --qf %{VERSION} plasma-desktop)

# We don't want to install the copr version if it's in fedora repos
if [[ "${PLASMA_VERSION}" =~ "^6\.5" ]]; then
  echo "Skipping installing 6.5 when we are already on 6.5"
  exit 1
fi

# KDE 6.5
log() {
    echo -e "\n\033[1;34m==> $1\033[0m\n"
}

error() {
    echo -e "\n\033[1;31mERROR: $1\033[0m\n" >&2
}

COPRS=(
    "@kdesig/kde-final"
)

ENABLED_REPOS=()

# Enable COPRs and set priority
for copr in "${COPRS[@]}"; do
    log "Enabling COPR: $copr"
    if ! dnf5 -y copr enable "$copr"; then
        error "Failed to enable COPR: $copr"
        continue
    fi

    copr_sanitized="${copr//@/group_}"
    repo_id="copr:copr.fedorainfracloud.org:${copr_sanitized////:}"
    log "Setting priority=1 for $repo_id"
    if ! dnf5 -y config-manager setopt "${repo_id}.priority=1"; then
        error "Failed to set priority for $repo_id"
        continue
    fi

    ENABLED_REPOS+=("--repo=$repo_id")
done

# Upgrade all installed packages from the COPR repos
if (( ${#ENABLED_REPOS[@]} > 0 )); then
    log "Upgrading packages from enabled COPRs"
    if ! dnf5 upgrade -y "${ENABLED_REPOS[@]}" --allowerasing; then
        error "Upgrade failed"
        exit 1
    fi
else
    log "No COPRs were successfully enabled. Nothing to upgrade."
fi

dnf5 -y remove plasma-discover-kns

dnf5 -y copr disable @kdesig/kde-final

echo "::endgroup::"
