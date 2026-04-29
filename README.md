# Better Audio for Macs with the T2 Chip

This repository provides modern ALSA UCM2 (Use Case Manager) configuration files to properly route audio and automatically switch between speakers and headphones on Macs with the T2 Security Chip. 

Previously, this required complex PulseAudio/PipeWire profile-sets and udev rules which still struggled with things like headphone jack detection. By moving to UCM2, the audio server (PipeWire or PulseAudio) can natively understand the hardware layout and seamlessly handle jack insertion events.

Note that an `apple-bce` driver exposing standard ALSA controls is required. 

The original PulseAudio files were based on various community gists.

## Installation
You can install the ALSA UCM configuration files using `install.sh`.

```bash
sudo ./install.sh
```

This will copy the contents of the `ucm2/` directory to `/usr/share/alsa/ucm2/`.
After installation, restart your audio services (e.g., `systemctl --user restart pipewire pipewire-pulse wireplumber`).

## Uninstallation
To remove the installed configuration and revert to default settings:

```bash
sudo ./uninstall.sh
```

This will remove the T2-specific UCM profiles from `/usr/share/alsa/ucm2/`.
After uninstallation, restart your audio services to apply the changes.

Note that some distributions (for example NixOS) may have different ways to install the files or require pointing to a custom ALSA topology path.
