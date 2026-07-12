#!/usr/bin/env bash

# Setup Public Keys for containers that are pulled during the build

set -eoux pipefail

PKI_DIR="/etc/pki/containers"
REGISTRIES="/etc/containers/registries.d"

mkdir -p "${PKI_DIR}" "${REGISTRIES}"
cp cosign.pub "${PKI_DIR}/ghcr.io-ublue-os.pub"
cp quay.io-fedora-ostree-desktops.pub "${PKI_DIR}"

yq -n '.docker."ghcr.io/ublue-os".use-sigstore-attachments = true' | tee "${REGISTRIES}"/ublue-os.yaml
yq -n '.docker."quay.io/fedora-ostree-desktops".use-sigstore-attachments = true' | tee "${REGISTRIES}"/fedora-ostree-desktops.yaml

jq '.transports.docker["ghcr.io/ublue-os"] = [
  {
    "type": "sigstoreSigned",
    "keyPath": "/etc/pki/containers/ghcr.io-ublue-os.pub",
    "signedIdentity": {
      "type": "matchRepository"
    }
  }
] |
.transports.docker["quay.io/fedora-ostree-desktops"] = [
  {
    "type": "sigstoreSigned",
    "keyPath": "/etc/pki/containers/quay.io-fedora-ostree-desktops.pub",
    "signedIdentity": {
      "type": "matchRepository"
    }
  }
]' /etc/containers/policy.json | tee /etc/containers/policy.json.tmp > /dev/null && mv /etc/containers/policy.json.tmp /etc/containers/policy.json
