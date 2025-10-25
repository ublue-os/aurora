#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Offline Aurora documentation
ghcurl "https://github.com/ublue-os/aurora-docs/releases/download/0.1/aurora.pdf" --retry 3 -o /tmp/aurora.pdf
install -Dm0644 -t /usr/share/doc/aurora/ /tmp/aurora.pdf

# Starship Shell Prompt
ghcurl "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz" --retry 3 -o /tmp/starship.tar.gz
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >> /etc/bashrc

# Nerdfont symbols
# to fix motd and prompt atleast temporarily
ghcurl "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip" --retry 3 -o /tmp/nerdfontsymbols.zip
unzip /tmp/nerdfontsymbols.zip -d /tmp
mkdir -p /usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly/
mv /tmp/SymbolsNerdFont*.ttf /usr/share/fonts/nerd-fonts/NerdFontsSymbolsOnly/

# Bash Prexec
curl --retry 3 -Lo /usr/share/bash-prexec https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh

# Consolidate Just Files
find /tmp/just -iname '*.just' ! -name 'aurora-beta.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just

# Caps
setcap 'cap_net_raw+ep' /usr/libexec/ksysguard/ksgrd_network_helper

echo "::endgroup::"
