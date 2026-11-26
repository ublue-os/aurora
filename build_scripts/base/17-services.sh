#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

systemctl preset-all
systemctl --global preset-all

# Disable gcr services so it doesn't break ssh-agent
# https://bugzilla.redhat.com/show_bug.cgi?id=2584783
# https://github.com/ublue-os/aurora/issues/3241
systemctl --global mask gcr-ssh-agent.socket gcr-ssh-agent.service

echo "::endgroup::"
