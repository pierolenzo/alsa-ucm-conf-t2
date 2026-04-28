#!/usr/bin/env sh

# This script must be run as root to install system-wide configuration files.
if [ "$USER" != "root" ]
then
    echo "This script must be run as root. You will be prompted for your password."
    sudo chmod 755 "$0"
    sudo "./$0"
    exit 0
fi

echo "Cleaning up any legacy ALSA/PulseAudio configuration files..."
# Silently remove legacy configuration files (from main branch and older versions)
for dir in "/usr/share/pulseaudio/alsa-mixer" "/usr/share/alsa-card-profile/mixer"
do
    if [ -d "$dir" ]; then
        rm -f "$dir/profile-sets/apple-t2"*
        rm -f "$dir/paths/t2-"*
    fi
done
rm -f "/usr/lib/udev/rules.d/91-pulseaudio-custom.rules"
rm -f "/usr/lib/udev/rules.d/91-audio-custom.rules"
rm -f "/usr/share/alsa/cards/AppleT2.conf"

ucm_dir="/usr/share/alsa/ucm2"
if [ -d "$ucm_dir" ]
then
    echo "Installing ALSA UCM2 profiles..."
    cp -av ucm2/* "$ucm_dir/"
    
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
    echo "Error: Directory $ucm_dir not found. ALSA UCM2 might not be installed."
fi
