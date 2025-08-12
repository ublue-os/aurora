#!/usr/bin/bash
set -euo pipefail

# https://develop.kde.org/docs/plasma/scripting/

source /usr/lib/ublue/setup-services/libsetup.sh
version-script aurora-framework-icon user 1 || exit 0

VEN_ID="$(cat /sys/devices/virtual/dmi/id/chassis_vendor)"
if [[ ":Framework:" =~ ":$VEN_ID:" ]]; then
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    let allPanels = panels();

    for (let i = 0; i < allPanels.length; i++) {
      let panel = allPanels[i];
      let widgetIds = panel.widgetIds;

      for (let j = 0; j < widgetIds.length; j++) {
        let widget = panel.widgetById(widgetIds[j]);

        if (widget.type === \"org.kde.plasma.kickoff\") {
          widget.currentConfigGroup = [\"General\"];
          widget.writeConfig(\"icon\", \"framework\");
          widget.reloadConfig();
        }
      }
    }
  "
fi
