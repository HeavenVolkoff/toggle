# Toggle
Simple Bash scripts for toggling camera and mic on/off.

# Using
Just execute `camera-toggle.sh` to toggle any connected usb camera on/off, or execute `mic-toggle.sh` to toggle the default pulse-audio sink on/off.

For more options see `--help`.

# Optional requirements
For improved user notification of the current camera/mic state, the script can use `notify-send`¹ utility, if available, for displaying a desktop notification,
or it can use the `mktrayicon`² utility for displaying a tray icon in the notification area.

1. https://developer.gnome.org/libnotify/

2. https://github.com/jonhoo/mktrayicon

# Installation (Arch Linux)
A PKGBUILD is provided at the root of the repository.
