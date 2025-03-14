#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# swap devpod to use ublue copr
dnf5 -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
        devpod devpod

curl --retry 3 -Lo /tmp/kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64"
chmod +x /tmp/kind
mv /tmp/kind /usr/bin/kind

echo "::endgroup::"
