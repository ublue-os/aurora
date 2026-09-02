# Toggle Aurora staged deployment desktop notifications.

[group('Aurora')]
aurora-update-notifier action="status":
    #!/usr/bin/env bash
    set -euo pipefail

    action="{{ action }}"
    system_timer="aurora-deployment-check.timer"
    system_service="aurora-deployment-check.service"
    user_path="aurora-deployment-notifier.path"

    case "${action}" in
      enable|on)
        systemctl --user enable --now "${user_path}"
        sudo systemctl enable --now "${system_timer}"
        sudo systemctl start "${system_service}" || true
        echo "Aurora update notifications enabled."
        ;;
      disable|off)
        systemctl --user disable --now "${user_path}" || true
        sudo systemctl disable --now "${system_timer}" || true
        rm -f "${XDG_STATE_HOME:-${HOME}/.local/state}/aurora/deployment-notifier/last-notified"
        echo "Aurora update notifications disabled."
        ;;
      status)
        echo "User notifier:"
        systemctl --user --no-pager status "${user_path}" || true
        echo
        echo "System checker:"
        systemctl --no-pager status "${system_timer}" || true
        ;;
      *)
        echo "Usage: ujust aurora-update-notifier [enable|disable|status]"
        exit 2
        ;;
    esac
