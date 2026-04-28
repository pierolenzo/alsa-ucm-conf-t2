#!/usr/bin/env sh

# This script must be run as root to install system-wide configuration files.
if [ "$USER" != "root" ]
then
    echo "This script must be run as root. You will be prompted for your password."
    sudo chmod 755 "$0"
    sudo "./$0"
    exit 0
fi

LOG_FILE="/var/log/t2-audio-install.log"

log_action() {
    local msg="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

log_action "Starting T2 audio configuration installation..."
log_action "Cleaning up any legacy ALSA/PulseAudio configuration files..."

# Remove legacy configuration files (from main branch and older versions)
for dir in "/usr/share/pulseaudio/alsa-mixer" "/usr/share/alsa-card-profile/mixer"
do
    if [ -d "$dir" ]; then
        for f in "$dir/profile-sets/apple-t2"* "$dir/paths/t2-"*; do
            if [ -e "$f" ] || [ -L "$f" ]; then
                log_action "Removing legacy file: $f"
                rm -f "$f"
            fi
        done
    fi
done

for f in "/usr/lib/udev/rules.d/91-pulseaudio-custom.rules" \
         "/usr/lib/udev/rules.d/91-audio-custom.rules" \
         "/usr/share/alsa/cards/AppleT2.conf"; do
    if [ -e "$f" ] || [ -L "$f" ]; then
        log_action "Removing legacy file: $f"
        rm -f "$f"
    fi
done

ucm_dir="/usr/share/alsa/ucm2"
if [ -d "$ucm_dir" ]
then
    log_action "Installing ALSA UCM2 profiles into $ucm_dir..."
    
    # Copy files and log each copied file
    cp -av ucm2/* "$ucm_dir/" | while IFS= read -r line; do
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
    
    echo ""
    echo "======================================================="
    echo -e "\033[1;32mInstallation Successful!\033[0m"
    echo "======================================================="
    echo "To apply the new audio routing, restart your audio server"
    echo "by running this command (WITHOUT sudo):"
    echo ""
    echo "    systemctl --user restart wireplumber pipewire"
    echo ""
    echo -e "\033[1;33mIMPORTANT NOTE FOR FIRST TIME USE:\033[0m"
    echo "If automatic headphone switching does not work initially,"
    echo "plug in your headphones and manually select them as the"
    echo "output device in your desktop audio settings or pwvucontrol."
    echo "WirePlumber will remember this preference for future automatic switching."
    echo "======================================================="
else
    log_action "Error: Directory $ucm_dir not found. ALSA UCM2 might not be installed."
fi
