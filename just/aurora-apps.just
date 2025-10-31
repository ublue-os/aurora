# vim: set ft=make :
########################
### aurora-apps.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

# alias for setup-cockpit
[group('Apps')]
cockpit:
    @ujust setup-cockpit

# Enable Cockpit for web-based system management | https://cockpit-project.org/
[group('Apps')]
setup-cockpit ACTION="":
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh

    MANAGED_COCKPIT_CONTAINER="cockpit-ws"

    if sudo podman container exists $MANAGED_COCKPIT_CONTAINER ; then
        COCKPIT_CONTAINER_STATUS_PRETTY="${green}${b}Installed${n}"
        COCKPIT_CONTAINER_STATUS=1
    else
        COCKPIT_CONTAINER_STATUS_PRETTY="${invert}${b}Not installed${n}"
        COCKPIT_CONTAINER_STATUS=0
    fi

    COCKPIT_SERVICE_STATUS="$(systemctl is-enabled cockpit.service)"
    if [ "$COCKPIT_SERVICE_STATUS" == "enabled" ]; then
        COCKPIT_SERVICE_STATUS="${green}${b}Enabled${n}"
    elif [ "$COCKPIT_SERVICE_STATUS" == "disabled" ]; then
        COCKPIT_SERVICE_STATUS="${red}${b}Disabled${n}"
    else
        COCKPIT_SERVICE_STATUS="${invert}${b}Not installed${n}"
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
        cat <<EOF
    Usage: ujust setup-cockpit <option>
      <option>: Specify the quick option to skip the prompt
      Use 'install' to select Install Cockpit
      Use 'enable' to select Enable Cockpit
      Use 'disable' to select Disable Cockpit
      Use 'uninstall' to select Uninstall Cockpit
    EOF
        exit 0
    elif [ "$OPTION" == "" ]; then
        echo "${bold}Cockpit Setup${normal}"
        echo "Cockpit service is currently: $COCKPIT_SERVICE_STATUS"
        echo "The Cockpit container is currently: $COCKPIT_CONTAINER_STATUS_PRETTY"
        if [[ "${COCKPIT_CONTAINER_STATUS}" -eq 0 ]]; then
            echo "Warning: This will enable ssh password login because Cockpit requires it."
            OPTION=$(Choose "Install Cockpit" "Cancel")
        else
            OPTION=$(Choose "Enable Cockpit" "Disable Cockpit" "Uninstall Cockpit")
        fi
    fi
    if [[ "${OPTION,,}" =~ ^install ]]; then
        echo "${blue}${b}Installing Cockpit${n}"
        sudo /bin/bash <<EOF
    [ ! -f /etc/ssh/sshd_config.d/02-enable-passwords.conf ] && echo -e "# File managed by ujust cockpit\nPasswordAuthentication yes" > /etc/ssh/sshd_config.d/02-enable-passwords.conf
    systemctl -q try-restart sshd
    systemctl -q enable --now sshd
    if ! podman image exists quay.io/cockpit/ws ; then
        podman pull quay.io/cockpit/ws:latest
    fi
    podman container runlabel -q --name $MANAGED_COCKPIT_CONTAINER RUN quay.io/cockpit/ws
    podman container runlabel -q INSTALL quay.io/cockpit/ws systemctl enable cockpit.service
    EOF
        OPTION="Enable Cockpit"
    fi
    if [[ "${OPTION,,}" =~ ^enable ]]; then
        sudo /bin/bash <<EOF
    echo "${green}${b}Enabling${n} Cockpit"
    systemctl -q enable --now cockpit.service
    podman start $MANAGED_COCKPIT_CONTAINER
    echo "$(Urllink "http://localhost:9090" "Open Cockpit${n}") -> http://localhost:9090"
    EOF
    fi
    if [[ "${OPTION,,}" =~ ^disable ]]; then
        echo "${red}${b}Disabling${n} Cockpit"
        sudo /bin/bash <<EOF
    systemctl -q disable cockpit.service
    podman stop $MANAGED_COCKPIT_CONTAINER
    EOF
        echo "Cockpit has been ${b}${red}disabled${n}"
    fi
    if [[ "${OPTION,,}" =~ ^uninstall ]] ; then
        sudo /bin/bash <<EOF
    [ -f /etc/ssh/sshd_config.d/02-enable-passwords.conf ] && rm -f /etc/ssh/sshd_config.d/02-enable-passwords.conf
    systemctl -q try-restart sshd
    systemctl -q disable --now cockpit.service
    rm -f /etc/systemd/system/cockpit.service
    podman stop -i $MANAGED_COCKPIT_CONTAINER
    podman rm -f $MANAGED_COCKPIT_CONTAINER
    EOF
        echo "Cockpit has been ${red}${b}uninstalled${n}"
    fi

# alias for install-jetbrains-toolbox
[group('Apps')]
jetbrains-toolbox:
    @ujust install-jetbrains-toolbox

# Install JetBrains Toolbox | https://www.jetbrains.com/toolbox-app/
[group('Apps')]
install-jetbrains-toolbox:
    #!/usr/bin/env bash
    pushd "$(mktemp -d)"
    echo "Get latest JetBrains Toolbox version"
    # Get the json with latest releases
    curl -sSfL -o releases.json "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
    # Extract information
    BUILD_VERSION=$(jq -r '.TBA[0].build' ./releases.json)
    DOWNLOAD_LINK=$(jq -r '.TBA[0].downloads.linux.link' ./releases.json)
    CHECKSUM_LINK=$(jq -r '.TBA[0].downloads.linux.checksumLink' ./releases.json)
    echo "Installing JetBrains Toolbox ${BUILD_VERSION}"
    curl -sSfL -O "${DOWNLOAD_LINK}"
    curl -sSfL "${CHECKSUM_LINK}" | sha256sum -c
    tar zxf jetbrains-toolbox-"${BUILD_VERSION}".tar.gz
    mkdir -p $HOME/.local/share/JetBrains/ToolboxApp/
    mv jetbrains-toolbox-"${BUILD_VERSION}"/* $HOME/.local/share/JetBrains/ToolboxApp/
    echo "Launching JetBrains Toolbox"
    $HOME/.local/share/JetBrains/ToolboxApp/bin/jetbrains-toolbox &

# Install GUI apps for OpenRazer
[group('Apps')]
install-openrazer-frontend:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    OPENRAZER_CONFIGURATOR_APP="None"
    echo "${bold}Select OpenRazer Frontend Apps${normal}"
    OPTION=$(Choose "Razer Genie" "Polychromatic" "Close")
    if [[ "${OPTION,,}" =~ ^razer[[:space:]]genie ]]; then
        echo "Installing Razer Genie..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        flatpak --system install -y flathub xyz.z3ntu.razergenie
        OPENRAZER_CONFIGURATOR_APP="Razer Genie"
    elif [[ "${OPTION,,}" =~ ^polychromatic ]]; then
        echo "Installing Polychromatic..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        flatpak --system install -y flathub app.polychromatic.controller
        OPENRAZER_CONFIGURATOR_APP="Polychromatic"
    else
        echo "Not Selecting GUI Frontend"
    fi
    echo "$OPENRAZER_CONFIGURATOR_APP is installed"

# Install OpenTabletDriver, an open source, cross-platform, user-mode tablet driver
[group('Apps')]
install-opentabletdriver:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    echo "Installer for OpenTabletDriver..."
    echo "${bold}Install or Remove OpenTabletDriver${normal}"
    OPTION=$(Choose "Install" "Uninstall" "Exit")
    if [[ "${OPTION,,}" =~ ^install ]]; then
        echo "Installing OpenTabletDriver..."
        curl -s https://api.github.com/repos/OpenTabletDriver/OpenTabletDriver/releases/latest \
        | jq -r '.assets | sort_by(.created_at) | .[] | select (.name|test("opentabletdriver.*tar.gz$")) | .browser_download_url' \
        | wget -qi - -O /tmp/OpenTabletDriver/opentabletdriver.tar.gz && \
        tar --strip-components=1 -xvzf /tmp/OpenTabletDriver/opentabletdriver.tar.gz -C /tmp/OpenTabletDriver && \
        pkexec cp /tmp/OpenTabletDriver/etc/udev/rules.d/70-opentabletdriver.rules /etc/udev/rules.d/71-opentabletdriver.rules && \
        rm -rf /tmp/OpenTabletDriver && \
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && \
        flatpak --system install -y flathub net.opentabletdriver.OpenTabletDriver && \
        mkdir -p $HOME/.config/OpenTabletDriver && \
        flatpak override --user --filesystem=xdg-config/OpenTabletDriver net.opentabletdriver.OpenTabletDriver && \
        mkdir -p $HOME/.config/systemd/user && \
        curl -s https://raw.githubusercontent.com/flathub/net.opentabletdriver.OpenTabletDriver/refs/heads/master/scripts/opentabletdriver.service > $HOME/.config/systemd/user/opentabletdriver.service  && \
        systemctl --user daemon-reload && \
        systemctl enable --user --now opentabletdriver.service
    elif [[ "${OPTION,,}" =~ ^uninstall ]]; then
        echo "Uninstalling OpenTabletDriver..."
        pkexec rm /etc/udev/rules.d/71-opentabletdriver.rules && \
        flatpak --system remove -y flathub net.opentabletdriver.OpenTabletDriver
    else
        echo "Have a good day :)!"
    fi

# Install and configure Incus
[group('Apps')]
install-incus:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if ! grep -e "-dx" <<< $CURRENT_IMAGE ; then
        echo "Developer mode is currently ${b}${red}Disabled${n}."
        echo "Run \"ujust devmode\" to turn on Developer mode."
        exit
    fi
    echo 'Installing and configuring Incus.'
    /usr/libexec/aurora-incus

# Install Kubernetes CLI dev tools
[group('Apps')]
aurora-k8s:
    #!/usr/bin/bash
    echo "☸️🛠️ Adding Kubernetes command line tools..."
    brew bundle --file /usr/share/ublue-os/homebrew/aurora-k8s.Brewfile

# alias for install-ai-tools
aurora-ai:
    @ujust install-ai-tools

# Install AI tools
[group('Apps')]
install-ai-tools:
    #!/usr/bin/bash
    echo "🧠🤖 Adding AI tools..."
    brew bundle --file /usr/share/ublue-os/homebrew/aurora-ai.Brewfile

# Setup and configure Sunshine Game Streaming host
[group('Apps')]
setup-sunshine ACTION="":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    SERVICE_STATE="$(systemctl is-enabled --user sunshine.service)"
    OPTION={{ ACTION }}
    if [ "$SERVICE_STATE" == "enabled" ]; then
        SERVICE_STATE="${green}${b}Enabled${n}"
    else
        SERVICE_STATE="${red}${b}Disabled${n}"
    fi
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust setup-sunshine <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'enable' to enable the Sunshine service"
      echo "  Use 'disable' to disable the Sunshine service"
      echo "  Use 'portal' to open the Sunshine management portal"
      echo "  Use 'exit' to exit without making changes"
      exit 0
    elif [ "$OPTION" == "" ]; then
      echo "Service is $SERVICE_STATE"
      OPTION=$(Choose "Enable" "Disable" "Open Portal" "Exit")
    fi
    if [[ "${OPTION,,}" =~ ^enable ]]; then
      systemctl enable --user --now sunshine.service
    elif [[ "${OPTION,,}" =~ ^(remove|uninstall|disable) ]]; then
      systemctl disable --user --now sunshine.service
    elif [[ "${OPTION,,}" =~ ^(portal|open) ]]; then
      echo "Opening Sunshine management portal..."
      xdg-open https://localhost:47990
    elif [[ "${OPTION,,}" =~ ^exit ]]; then
      echo "Exiting without making changes."
      exit 0
    fi

# Toggle between Bazaar and Discover software stores
[group('Apps')]
toggle-software-store ACTION="":
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh

    discover_apps=(
        "org.kde.discover.desktop"
        "org.kde.discover.flatpak.desktop"
        "org.kde.discover.urlhandler.desktop"
    )

    mkdir -p "$HOME/.local/share/applications"

    discover_active=false
    for app in "${discover_apps[@]}"; do
        if [ -f "$HOME/.local/share/applications/${app}" ]; then
            discover_active=true
            break
        fi
    done

    if [ "$discover_active" = true ]; then
        CURRENT_STATE="discover"
        CURRENT_STATE_PRETTY="${blue}${b}Discover${n}"
    else
        CURRENT_STATE="bazaar"
        CURRENT_STATE_PRETTY="${green}${b}Bazaar${n}"
    fi

    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
        echo "Usage: ujust toggle-software-store <option>"
        echo "  <option>: Specify the quick option to skip the prompt"
        echo "  Use 'bazaar' to enable Bazaar (hide Discover)"
        echo "  Use 'discover' to enable Discover (hide Bazaar)"
        exit 0
    elif [ "$OPTION" == "" ]; then
        echo "${bold}Software Store Toggle${normal}"
        echo "Currently active: $CURRENT_STATE_PRETTY"
        if [ "$CURRENT_STATE" == "discover" ]; then
            OPTION=$(Choose "Switch to Bazaar" "Cancel")
        else
            OPTION=$(Choose "Switch to Discover" "Cancel")
        fi
    fi

    if [[ "${OPTION,,}" =~ ^(switch.*bazaar|bazaar) ]]; then
        echo "${green}${b}Switching to Bazaar...${n}"
        # Remove Discover files from ~/.local (hides them)
        for app in "${discover_apps[@]}"; do
            if [ -f "$HOME/.local/share/applications/${app}" ]; then
                rm "$HOME/.local/share/applications/${app}"
            fi
        done

        # Remove discover notifier (might still exist from before we removed it from the image)
        if [ -f "$HOME/.config/autostart/org.kde.discover.notifier.desktop" ]; then
            rm "$HOME/.config/autostart/org.kde.discover.notifier.desktop"
        fi

        # Remove Bazaar override if it exists (shows Bazaar)
        if [ -f "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop" ]; then
            rm "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop"
        fi

        # discover could still be running
        pkill -f DiscoverNotifier

        # enable bazaar in krunner
        kwriteconfig6 --file krunnerrc --group Plugins --key krunner_appstreamEnabled false
        kwriteconfig6 --file krunnerrc --group Plugins --key bazaarrunnerEnabled true
        systemctl --user restart plasma-krunner.service plasma-plasmashell.service

        echo "${green}${b}Bazaar is now active${n}"

    elif [[ "${OPTION,,}" =~ ^(switch.*discover|discover) ]]; then
        echo "${blue}${b}Switching to Discover...${n}"
        # Copy Discover files from /usr to ~/.local (shows them)
        for app in "${discover_apps[@]}"; do
            if [ -f "/usr/share/applications/${app}.disabled" ]; then
                cp "/usr/share/applications/${app}.disabled" "$HOME/.local/share/applications/${app}"
            fi
        done

        # bazaar is probably still running
        pkill -f bazaar

        # enable discover in krunner
        kwriteconfig6 --file krunnerrc --group Plugins --key krunner_appstreamEnabled true
        kwriteconfig6 --file krunnerrc --group Plugins --key bazaarrunnerEnabled false
        systemctl --user restart plasma-krunner.service plasma-plasmashell.service

        # Hide Bazaar by creating NoDisplay override
        cp /usr/share/applications/io.github.kolunmi.Bazaar.desktop "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop"
        desktop-file-edit --set-key=NoDisplay --set-value=true "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop"
        echo "${blue}${b}Discover is now active${n}"

    elif [[ "${OPTION,,}" =~ ^cancel ]]; then
        echo "No changes made."
        exit 0
    fi
