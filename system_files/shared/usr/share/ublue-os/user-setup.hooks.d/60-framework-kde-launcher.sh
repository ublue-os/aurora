#!/usr/bin/bash
set -euo pipefail

source /usr/lib/ublue/setup-services/libsetup.sh
version-script aurora-framework-icon user 1 || exit 0

VEN_ID="$(cat /sys/devices/virtual/dmi/id/chassis_vendor)"
if [[ ":Framework:" =~ ":$VEN_ID:" ]]; then
  echo "Running Framework KDE Plasma Shell setup"

  CONFIG="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

  if [[ -f "$CONFIG" ]]; then
    # Find kickoff/application launcher applet sections
    APPLET_SECTIONS=$(grep -n '\[Containments\]\[[0-9]*\]\[Applets\]\[[0-9]*\]' "$CONFIG")

    # For each applet section, check if it's a launcher and update it
    while IFS=: read -r line_num line_content; do
      SECTION_NUM=$(echo "$line_content" | sed -E 's/\[Containments\]\[([0-9]+)\]\[Applets\]\[([0-9]+)\]/\1:\2/')
      CONT_NUM=$(echo "$SECTION_NUM" | cut -d: -f1)
      APP_NUM=$(echo "$SECTION_NUM" | cut -d: -f2)

      # Check if this is a launcher applet
      IS_LAUNCHER=$(grep -A 5 "\[Containments\]\[$CONT_NUM\]\[Applets\]\[$APP_NUM\]" "$CONFIG" | grep -i "kickoff\|launcher")

      if [[ -n "$IS_LAUNCHER" ]]; then
        echo "Found launcher applet in section $CONT_NUM:$APP_NUM, updating icon"
        kwriteconfig6 --file "$CONFIG" --group Containments --group $CONT_NUM --group Applets --group $APP_NUM --group Configuration --group General --key "icon" "framework"
      fi
    done <<<"$APPLET_SECTIONS"

    echo "Restarting Plasma to apply changes"
    systemctl --user restart plasma-plasmashell.service
  fi
fi
