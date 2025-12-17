#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

# to reduce the indiviual layer size we put big files that are not shipped with RPMs in their own layers
# See: https://coreos.github.io/rpm-ostree/build-chunked-oci/

setfattr -n user.component -v "homebrew" /usr/share/homebrew.tar.zst
setfattr -n user.component -v "starship" /usr/bin/starship
setfattr -n user.component -v "nerd-fonts" /usr/share/fonts/nerd-fonts

echo "::endgroup::"
