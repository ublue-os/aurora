
# Toggle between Bazaar and Discover software stores (beta only)
[group('Apps')]
toggle-software-store ACTION="":
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh

    if ! jq -e '.["image-tag"] | test("beta")' /usr/share/ublue-os/image-info.json >/dev/null 2>&1; then
        echo "${red}${b}This feature is only available on beta images.${n}"
        exit 1
    fi

    discover_apps=(
        "org.kde.discover.desktop"
        "org.kde.discover-flatpak.desktop"
        "org.kde.discover.notifier.desktop"
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
        # Remove Bazaar override if it exists (shows Bazaar)
        if [ -f "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop" ]; then
            rm "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop"
        fi
        echo "${green}${b}Bazaar is now active${n}"

    elif [[ "${OPTION,,}" =~ ^(switch.*discover|discover) ]]; then
        echo "${blue}${b}Switching to Discover...${n}"
        # Copy Discover files from /usr to ~/.local (shows them)
        for app in "${discover_apps[@]}"; do
            if [ -f "/usr/share/applications/${app}.disabled" ]; then
                cp "/usr/share/applications/${app}.disabled" "$HOME/.local/share/applications/${app}"
            fi
        done
        # Hide Bazaar by creating NoDisplay override
        echo "[Desktop Entry]\nNoDisplay=true" > "$HOME/.local/share/applications/io.github.kolunmi.Bazaar.desktop"
        echo "${blue}${b}Discover is now active${n}"

    elif [[ "${OPTION,,}" =~ ^cancel ]]; then
        echo "No changes made."
        exit 0
    fi
