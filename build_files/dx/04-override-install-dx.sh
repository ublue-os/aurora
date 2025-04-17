#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

curl --retry 3 -Lo /tmp/kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64"
chmod +x /tmp/kind
mv /tmp/kind /usr/bin/kind

# ls-iommu helper tool for listing devices in iommu groups (PCI Passthrough)
DOWNLOAD_URL=$(curl https://api.github.com/repos/HikariKnight/ls-iommu/releases/latest | jq -r '.assets[] | select(.name| test(".*x86_64.tar.gz$")).browser_download_url')
curl --retry 3 -Lo /tmp/ls-iommu.tar.gz "$DOWNLOAD_URL"
mkdir /tmp/ls-iommu
tar --no-same-owner --no-same-permissions --no-overwrite-dir -xvzf /tmp/ls-iommu.tar.gz -C /tmp/ls-iommu
mv /tmp/ls-iommu/ls-iommu /usr/bin/
rm -rf /tmp/ls-iommu*

echo "::endgroup::"
