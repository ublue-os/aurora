#!/usr/bin/bash
set -euo pipefail

# https://develop.kde.org/docs/plasma/scripting/

source /usr/lib/ublue/setup-services/libsetup.sh
version-script aurora-framework-icon user 1 || exit 0

VEN_ID="$(cat /sys/devices/virtual/dmi/id/chassis_vendor)"
if [[ ":Framework:" =~ ":$VEN_ID:" ]]; then
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allPanels = panels();

    for (var i = 0; i < allPanels.length; i++) {
      var panel = allPanels[i];
      var widgetIds = panel.widgetIds;

      for (var j = 0; j < widgetIds.length; j++) {
        var widget = panel.widgetById(widgetIds[j]);

        if (widget.type === \"org.kde.plasma.kickoff\") {
          widget.currentConfigGroup = [\"General\"];
          widget.writeConfig(\"icon\", \"framework\");
          widget.reloadConfig();
        }
      }
    }
  "
fi
