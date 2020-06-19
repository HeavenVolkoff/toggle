#!/usr/bin/env bash

# TODO:
# - Add option so user can select which camera to act upon

# Simple script that toggle V4L usb camera on/off.
# If `notify-send` <https://developer.gnome.org/libnotify/> is available, show a
#  notification with the current camera state after toggling it.
# if `mktrayicon` <https://github.com/jonhoo/mktrayicon> is available, show a
#  tray icon in the notification area that tracks the camera state.

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

get_usb_cameras () {
  declare -A cameras
  for video in $(find /dev -maxdepth 1 -name "video*" -print); do
    path="devices"
    for component in $(\
      udevadm info -q path /dev/video0 \
      | tr '/' "\n" | tail -n +3 \
    ); do
      path="${path}/${component}"
      if ! DEVICE="$(
        eval "$(udevadm info -q property -x -p "$path" 2>/dev/null)";
        [ -n "${DEVPATH:-}" ] && [ "${DRIVER:-}" == "usb" ] \
        && echo "$DEVPATH";
      )"; then
        continue
      fi

      case "$(basename "$DEVICE")" in
        usb*) continue ;;
        *) cameras[$DEVICE]=1 ;;
      esac 
    done
  done
  echo "${!cameras[@]}"
}

toggle_camera () {
  [ "$#" -ne 1 ] && error "toggle_camera requires a single argument"

  local camera="$1"
  if is_camera_binded "$camera"; then
    pkexec sh -c "echo ${camera} > /sys/bus/usb/drivers/usb/unbind"
  else
    pkexec sh -c "echo ${camera} > /sys/bus/usb/drivers/usb/bind"
  fi
}

is_camera_binded () {
  [ "$#" -ne 1 ] && error "is_camera_binded requires a single argument"
  [ -d "/sys/bus/usb/devices/${1}" ] || error "Invalid camera identifier"
  [ -e "/sys/bus/usb/devices/${1}/driver/" ]
}

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
Simple script that toggle V4L usb camera on/off and notify the user about it's
current state.

Usage: $0 [options]
options:
  -q[q][q]      Make script quieter. 1=Log, 2=Warning, 3=Error.
  --help, -h    Show this help message.
  --tray        Only initializes tray icon.
  --remove-tray Only removes tray icon.

No options toggles camera on/off and notify user about it's status, also
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

if ! CAMERA_PATH="$( \
  [ -f "${__runtime}/camera" ] \
  && CAMERA="$(cat "${__runtime}/camera")" \
  && udevadm info -q name -p "$CAMERA" &>/dev/null \
  && echo "$CAMERA"
)"; then
  rm -f "${__runtime}/camera"
  CAMERAS=( $(get_usb_cameras) )
  [ "${#CAMERAS[@]}" -lt 1 ] && error "No cameras found"
  CAMERA_PATH="${CAMERAS[0]}"
  echo "$CAMERA_PATH" > "${__runtime}/camera"
fi

CAMERA="$(basename $CAMERA_PATH)"
CAMERA_MODEL="$( \
  udevadm info -q property -x -p "$CAMERA_PATH" \
  | awk 'BEGIN { FS = "=" } ; /\<ID_MODEL\>/ {print $2}' \
  | tr -d "'" \
)"

if [ "$TRAY_ONLY" -eq 0 ]; then
  toggle_camera "$CAMERA"
fi

# Notify user of camera state
if is_camera_binded "$CAMERA"; then
  ICON="camera-on"
  MESSAGE="Camera ($CAMERA_MODEL) is enabled"
else
  ICON="camera-off"
  MESSAGE="Camera ($CAMERA_MODEL) is disabled"
fi

if [ "$TRAY_ONLY" -eq 0 ]; then
  log "$MESSAGE"
  send_notification "$ICON" "presence.online" "Camera Toggle" "$MESSAGE"
fi

tray "$ICON" "$MESSAGE" "$TRAY_ONLY"