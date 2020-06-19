#!/usr/bin/env bash

# Simple script that toggle pulseaudio's microphone on/off.
# If `notify-send` <https://developer.gnome.org/libnotify/> is available, show a
#  notification with the current mic state after toggling it.
# if `mktrayicon` <https://github.com/jonhoo/mktrayicon> is available, show a
#  tray icon in the notification area that tracks the mic state.

# Bash strict mode <http://redsymbol.net/articles/unofficial-bash-strict-mode>
set -euo pipefail
IFS=$'\n\t'

# Script's directory
readonly __dir="$(CDPATH="" cd -- "$(dirname -- "$(realpath -- "$0")")" && pwd)"
# Script's name
readonly __name="$(basename -- "$(realpath -- "$0")")"
# Script's absolute path
readonly __file="${__dir}/${__name}"
# Runtime directory
readonly __runtime="${XDG_RUNTIME_DIR:-/tmp}/${__name}"

# Ensure runtime directory exists
mkdir -p "$__runtime"

# Source common functions
. "${__dir}/functions.sh"

TRAY_ONLY=0
if [ "$#" -gt 0 ]; then
  # Parse command line options and execute necessary actions
  case "${1}" in
    -q)
      QUIET=1
      ;;
    -qq)
      QUIET=2
      ;;
    -qqq)
      QUIET=3
      ;;
    --help | -h)
      cat << EOF
About:
Simple script that toggle pulseaudio's microphone on/off and notify the user
about it's current state.

Usage: $0 [options]
options:
  -q[q][q]      Make script quieter. 1=Log, 2=Warning, 3=Error.
  --help, -h    Show this help message.
  --tray        Only initializes tray icon.
  --remove-tray Only removes tray icon.

No options toggles microphone on/off and notify user about it's status, also
initialize tray if necessary.
EOF
      exit 0
      ;;
    --tray)
      TRAY_ONLY=1
      ;;
    --remove-tray)
      close_tray
      exit 0
      ;;
    *)
      error "Unknown parameter: $1 (-h for more info)"
      ;;
  esac
fi

if ! has "pactl"; then
  error "No pactl utility available"
fi

# Retrieve default audio source
DEFAULT_SOURCE="$(pactl info | grep "Default Source" | cut -d " " -f3)"

if [ -z "$DEFAULT_SOURCE" ]; then
  error "No source device available"
fi

if [ "$TRAY_ONLY" -eq 0 ]; then
  # Toggle mic on/off
  pactl set-source-mute "$DEFAULT_SOURCE" toggle
fi

# Retrieve default audio source state after toggle
IS_DEFAULT_SOURCE_MUTED="$(pactl list \
  | grep -E "Name: $DEFAULT_SOURCE$|Mute" \
  | grep "Name:" -A1 \
  | tail -1 | cut -d: -f2 | tr -d " " \
)"

# Notify user of mic state
if [ "$IS_DEFAULT_SOURCE_MUTED" == "yes" ]; then
  ICON="mic-off"
  MESSAGE="Microphone is disabled"
else
  ICON="mic-on"
  MESSAGE="Microphone is enabled"
fi

if [ "$TRAY_ONLY" -eq 0 ]; then
  log "$MESSAGE"
  send_notification "$ICON" "presence.online" "Mic Toggle" "$MESSAGE"
fi

tray "$ICON" "$MESSAGE" "$TRAY_ONLY"