# Verify if a command exists
has () {
  [ "$#" -lt 1 ] && return 1
  command -v "$1" &>/dev/null;
}

# Verify if the terminal running this is interactive or not
is_interactive () {
  if has "tty" && tty -s; then
    return 0
  elif [ -t 0 ]; then
    return 0
  elif ! [ -z "${PS1:-}" ]; then
    return 0
  else
    case "$-" in
      *i*) return 0 ;;
      *) return 1 ;;
    esac
  fi
}

log () {
  [ "$#" -lt 1 ] && return 0

  if [ "$((${QUIET:-0}+0))" -lt 1 ]; then
    if is_interactive; then
      echo "${__name}: $@"
    else
      logger -p local0.notice -t "$__name" "$@"
    fi
  fi
}

error () {
  [ "$#" -lt 1 ] && return 0

  if [ "$((${QUIET:-0}+0))" -lt 3 ]; then
    if is_interactive; then
      echo "${__name}: $@" 1>&2;
    else
      logger -p local0.crit -t "$__name" "$@"
    fi
  fi

  exit 1
}

warning () {
  [ "$#" -lt 1 ] && return 0

  if [ "$((${QUIET:-0}+0))" -lt 2 ]; then
    if is_interactive; then
      echo "${__name}: $@";
    else
      logger -p local0.warning -t "$__name" "$@"
    fi
  fi
}

send_notification () {
  if [ "$#" -eq 3 ]; then
    local icon="$1"
    local header="$2"
    local body="$3"
  elif [ "$#" -eq 4 ]; then
    local icon="$1"
    local category="$2"
    local header="$3"
    local body="$4"
  else
    warning "send_notification function must receive three or four arguments"
    return 0
  fi

  if ! has "notify-send"; then
    warning "notify-send is not available, can't create notification"
    return 0
  fi

  notify-send -u normal -t 500 -i "$icon" -c "$category" "$header" "$body" \
    || warning "Failed to send notification"
}

tray () {
  if ! has "mktrayicon"; then
    local required="$((${3:-0}+0))"
    if [ "$required" -eq 0 ]; then
      warning "mktrayicon is not available, can't create tray icon."
      return 0  
    fi

    error "mktrayicon is not available, can't create tray icon."
  fi

  if [ "$#" -lt 2 ]; then
    warning "tray function must receive two arguments"
    return 0
  fi

  local pid="${__runtime}/tray.pid"
  local pipe="${__runtime}/tray.icon"

  if ! [ -p "$pipe" ]; then
    rm -f "$pipe" "$pid"
    mkfifo "$pipe"
  fi

  if ! ( [ -f "$pid" ] && kill -0 "$(cat "$pid")" &>/dev/null ); then
    rm -f "$pid"
    mktrayicon "$pipe" </dev/null &>/dev/null &
    echo "$!" > "$pid"
    echo "c ${__file}" > "$pipe"
    echo "m Exit,${__file} --remove-tray" > "$pipe"
  fi

  echo "i $1" > "$pipe"
  echo "t $2" > "$pipe"
}

close_tray() {
  if ! has "mktrayicon"; then
    return 0
  fi

  local pid="${__runtime}/tray.pid"
  local pipe="${__runtime}/tray.icon"

  if ! ( [ -f "$pid" ] && kill -s TERM "$(cat "$pid")" &>/dev/null ); then
    if [ "$(cat "/proc/${PPID}/comm")" == "mktrayicon" ]; then
      kill -s TERM "$PPID" || true 
    fi
  fi

  rm -f "$pid"
  rm -f "$pipe"
}