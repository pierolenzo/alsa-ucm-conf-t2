#!/usr/bin/env sh
set -e

# ==============================================================================
# Configuration & Constants
# ==============================================================================

LOG_FILE="/var/log/t2-audio-install.log"
UCM_DIR="/usr/share/alsa/ucm2"

# Paths relative to UCM_DIR
UCM_PATHS="
AppleT2
conf.d/AppleT2x2
conf.d/AppleT2x4
conf.d/AppleT2x6
"

# Colors for terminal output
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[1;31m"
COLOR_RESET="\033[0m"

# ==============================================================================
# Functions
# ==============================================================================

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. You will be prompted for your password."
    exec sudo "$0" "$@"
  fi
}

log_action() {
  local msg="$(date '+%Y-%m-%d %H:%M:%S') - $1"
  echo "$msg"
  [ -f "$LOG_FILE" ] && echo "$msg" >>"$LOG_FILE"
}

remove_ucm_profiles() {
  log_action "Removing ALSA UCM2 profiles from $UCM_DIR..."

  for path in $UCM_PATHS; do
    full_path="$UCM_DIR/$path"
    if [ -e "$full_path" ]; then
      log_action "Removing: $full_path"
      rm -rf "$full_path"
    else
      log_action "Path not found, skipping: $full_path"
    fi
  done
}

print_post_uninstall_instructions() {
  echo ""
  echo "======================================================="
  printf "%b\n" "${COLOR_GREEN}Uninstallation Complete!${COLOR_RESET}"
  echo "======================================================="
  echo "To revert to default audio settings, restart your audio server"
  echo "by running this command (WITHOUT sudo):"
  echo ""
  echo "    systemctl --user restart wireplumber pipewire"
  echo ""
  printf "%b\n" "${COLOR_YELLOW}NOTE:${COLOR_RESET}"
  echo "Standard ALSA/PulseAudio/PipeWire configuration should now"
  echo "be used. If you still experience issues, a system reboot"
  echo "might be necessary to fully reset the audio state."
  echo "======================================================="
}

main() {
  require_root "$@"

  log_action "Starting T2 audio configuration uninstallation..."

  remove_ucm_profiles
  
  # Optional: remove the log file itself
  if [ -f "$LOG_FILE" ]; then
    printf "Do you want to remove the installation log file ($LOG_FILE)? [y/N] "
    read opt
    case "$opt" in
      [yY][eE][sS]|[yY]) 
        rm -f "$LOG_FILE"
        echo "Log file removed."
        ;;
      *)
        echo "Log file kept at $LOG_FILE."
        ;;
    esac
  fi

  print_post_uninstall_instructions
}

# ==============================================================================
# Execution
# ==============================================================================

main "$@"
