#!/usr/bin/env sh
set -e

# ==============================================================================
# Configuration & Constants
# ==============================================================================

LOG_FILE="/var/log/t2-audio-install.log"
UCM_DIR="/usr/share/alsa/ucm2"

LEGACY_DIRS="
/usr/share/pulseaudio/alsa-mixer
/usr/share/alsa-card-profile/mixer
"

LEGACY_FILES="
/usr/lib/udev/rules.d/91-pulseaudio-custom.rules
/usr/share/alsa/cards/AppleT2.conf
"

# Colors for terminal output
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RESET="\033[0m"

# ==============================================================================
# Functions
# ==============================================================================

require_root() {
  if [ "$USER" != "root" ]; then
    echo "This script must be run as root. You will be prompted for your password."
    sudo chmod 755 "$0"
    exec sudo "./$0"
  fi
}

log_action() {
  local msg="$(date '+%Y-%m-%d %H:%M:%S') - $1"
  echo "$msg"
  echo "$msg" >>"$LOG_FILE"
}

remove_legacy_files() {
  log_action "Cleaning up any legacy ALSA/PulseAudio configuration files..."

  # Remove legacy configurations from directories
  for dir in $LEGACY_DIRS; do
    if [ -d "$dir" ]; then
      for f in "$dir/profile-sets/apple-t2"* "$dir/paths/t2-"*; do
        if [ -e "$f" ] || [ -L "$f" ]; then
          log_action "Removing legacy file: $f"
          rm -f "$f"
        fi
      done
    fi
  done

  # Remove specific legacy files
  for f in $LEGACY_FILES; do
    if [ -e "$f" ] || [ -L "$f" ]; then
      log_action "Removing legacy file: $f"
      rm -f "$f"
    fi
  done
}

install_ucm_profiles() {
  if [ ! -d "$UCM_DIR" ]; then
    log_action "Error: Directory $UCM_DIR not found. ALSA UCM2 might not be installed."
    exit 1
  fi

  log_action "Installing ALSA UCM2 profiles into $UCM_DIR..."

  # Copy files and log each copied file beautifully
  cp -av ucm2/* "$UCM_DIR/" | while IFS= read -r line; do
    case "$line" in
    removed*)
      log_action "Overwritten: ${line#removed }"
      ;;
    *-\>*)
      dest="${line#*-> }"
      log_action "Installed: $dest"
      ;;
    *)
      log_action "$line"
      ;;
    esac
  done
}

print_post_install_instructions() {
  echo ""
  echo "======================================================="
  printf "%b\n" "${COLOR_GREEN}Installation Successful!${COLOR_RESET}"
  echo "======================================================="
  echo "To apply the new audio routing, restart your audio server"
  echo "by running this command (WITHOUT sudo):"
  echo ""
  echo "    systemctl --user restart wireplumber pipewire"
  echo ""
  printf "%b\n" "${COLOR_YELLOW}IMPORTANT NOTE FOR FIRST TIME USE:${COLOR_RESET}"
  echo "If automatic headphone switching does not work initially,"
  echo "plug in your headphones and manually select them as the"
  echo "output device in your desktop audio settings or pwvucontrol."
  echo "WirePlumber will remember this preference for future automatic switching."
  echo "======================================================="
}

main() {
  require_root

  # Initialize log file if it doesn't exist to ensure permissions are correct
  touch "$LOG_FILE"
  chmod 644 "$LOG_FILE"

  log_action "Starting T2 audio configuration installation..."

  remove_legacy_files
  install_ucm_profiles
  print_post_install_instructions
}

# ==============================================================================
# Execution
# ==============================================================================

main "$@"
