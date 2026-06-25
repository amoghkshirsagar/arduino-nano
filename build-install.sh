#!/usr/bin/env bash
set -euo pipefail

# Interactive script to build/upload/monitor PlatformIO sketches in this project.
# Place at project root and run `./manage_sketch.sh` (make executable with chmod +x).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INI_FILE="$ROOT_DIR/platformio.ini"

if command -v platformio >/dev/null 2>&1; then
  PIO=platformio
elif command -v pio >/dev/null 2>&1; then
  PIO=pio
else
  echo "PlatformIO CLI not found. Install PlatformIO or ensure 'platformio' or 'pio' is in PATH."
  exit 1
fi

if [[ ! -f "$INI_FILE" ]]; then
  echo "platformio.ini not found in $ROOT_DIR"
  exit 1
fi

read_envs_from_ini() {
  grep -E '^\[env:' "$INI_FILE" | sed -E 's/^\[env:([^]]+)\].*/\1/'
}

ENVS=( $(read_envs_from_ini) )
if [[ ${#ENVS[@]} -eq 0 ]]; then
  echo "No [env:*] entries found in $INI_FILE"
  exit 1
fi

select_env() {
  echo "Available sketches/environments:"
  for i in "${!ENVS[@]}"; do
    idx=$((i+1))
    printf "%2d) %s\n" "$idx" "${ENVS[$i]}"
  done
  echo
  read -rp "Select sketch number (q to quit): " sel
  if [[ "$sel" == "q" || "$sel" == "Q" ]]; then
    exit 0
  fi
  if ! [[ "$sel" =~ ^[0-9]+$ ]] || (( sel < 1 || sel > ${#ENVS[@]} )); then
    echo "Invalid selection"; return 1
  fi
  ENV_NAME="${ENVS[$((sel-1))]}"
  return 0
}

get_monitor_speed() {
  # Prefer per-sketch platformio.ini if present, otherwise fall back to root
  local ini="$INI_FILE"
  if [[ -f "$ROOT_DIR/$ENV_NAME/platformio.ini" ]]; then
    ini="$ROOT_DIR/$ENV_NAME/platformio.ini"
  fi
  awk -v env="$ENV_NAME" -v file="$ini" '
    BEGIN{found=0}
    {gsub(/^[ \t]+|[ \t]+$/,"")}
    /^\[/{found=0}
    $0 == "[env:" env "]" { found=1; next }
    found==1 && tolower($0) ~ /^monitor_speed/ { split($0,a,"="); gsub(/^[ \t]+|[ \t]+$/,"",a[2]); print a[2]; exit }
  ' "$ini"
}

project_dir_for_env() {
  # If a directory with the env name exists and contains a platformio.ini, return it
  local dir="$ROOT_DIR/$ENV_NAME"
  if [[ -d "$dir" && -f "$dir/platformio.ini" ]]; then
    printf "%s" "$dir"
    return 0
  fi
  # Fallback: if a folder exists with same name but no platformio.ini, still use it
  if [[ -d "$dir" ]]; then
    printf "%s" "$dir"
    return 0
  fi
  return 1
}

ensure_platformio_udev_rules() {
  python -c 'from platformio.fs import ensure_udev_rules; ensure_udev_rules()' >/dev/null 2>&1
}

install_platformio_udev_rules() {
  local rules_src
  rules_src=$(python -c 'from platformio.fs import get_platformio_udev_rules_path; print(get_platformio_udev_rules_path())' 2>/dev/null)
  if [[ -z "$rules_src" || ! -f "$rules_src" ]]; then
    echo "Unable to locate PlatformIO udev rules asset."
    return 1
  fi
  local rules_dst="/etc/udev/rules.d/99-platformio-udev.rules"
  echo "Installing PlatformIO udev rules to $rules_dst"
  if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
    sudo install -m 0644 "$rules_src" "$rules_dst"
    sudo udevadm control --reload >/dev/null 2>&1 || true
    sudo udevadm trigger --subsystem-match=tty --action=add >/dev/null 2>&1 || true
  else
    install -m 0644 "$rules_src" "$rules_dst"
    udevadm control --reload >/dev/null 2>&1 || true
    udevadm trigger --subsystem-match=tty --action=add >/dev/null 2>&1 || true
  fi
}

check_platformio_udev_rules() {
  if ensure_platformio_udev_rules; then
    return 0
  fi
  echo "PlatformIO udev rules are missing or outdated."
  read -rp "Install/update them now? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    install_platformio_udev_rules
    return $?
  fi
  return 1
}

scan_usb_serial_ports() {
  local ports=()
  if command -v "$PIO" >/dev/null 2>&1; then
    mapfile -t ports < <($PIO device list 2>/dev/null | grep -Eo '/dev/tty(USB|ACM)[A-Za-z0-9_.]*' | sort -u)
  fi
  if [[ ${#ports[@]} -eq 0 ]]; then
    mapfile -t ports < <(find /dev -maxdepth 1 -type c \( -name 'ttyUSB*' -o -name 'ttyACM*' \) 2>/dev/null | sort)
  fi
  printf "%s\n" "${ports[@]}"
}

rescan_usb_serial_ports() {
  if ! command -v udevadm >/dev/null 2>&1; then
    return
  fi
  echo "Rescanning USB serial devices..."
  if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
    sudo udevadm trigger --subsystem-match=tty --action=add >/dev/null 2>&1 || true
    sudo udevadm settle >/dev/null 2>&1 || true
  elif [[ $EUID -eq 0 ]]; then
    udevadm trigger --subsystem-match=tty --action=add >/dev/null 2>&1 || true
    udevadm settle >/dev/null 2>&1 || true
  fi
}

choose_port() {
  mapfile -t PORTS < <(scan_usb_serial_ports)
  if [[ ${#PORTS[@]} -eq 0 ]]; then
    echo "No USB serial ports detected. Trying a udev rescan."
    rescan_usb_serial_ports
    sleep 2
    mapfile -t PORTS < <(scan_usb_serial_ports)
  fi
  if [[ ${#PORTS[@]} -eq 0 ]]; then
    read -rp "No USB serial ports detected. Enter port path (e.g. /dev/ttyUSB0) or leave empty to cancel: " selected_port
    SELECTED_PORT="$selected_port"
    return
  fi
  if [[ ${#PORTS[@]} -eq 1 ]]; then
    SELECTED_PORT="${PORTS[0]}"
    return
  fi
  echo "Detected serial ports:"
  for i in "${!PORTS[@]}"; do
    idx=$((i+1))
    printf "%2d) %s\n" "$idx" "${PORTS[$i]}"
  done
  read -rp "Select port number (or press Enter to cancel): " psel
  if [[ -z "$psel" ]]; then
    SELECTED_PORT=""
    return
  fi
  if ! [[ "$psel" =~ ^[0-9]+$ ]] || (( psel<1 || psel> ${#PORTS[@]} )); then
    SELECTED_PORT=""
    return
  fi
  SELECTED_PORT="${PORTS[$((psel-1))]}"
}

upload_command() {
  local output
  local pdir
  if pdir=$(project_dir_for_env); then
    if output=$($PIO run -d "$pdir" -e "$ENV_NAME" -t upload "${UPLOAD_ARGS[@]}" 2>&1); then
      printf '%s\n' "$output"
      return 0
    fi
  else
    if output=$($PIO run -e "$ENV_NAME" -t upload "${UPLOAD_ARGS[@]}" 2>&1); then
      printf '%s\n' "$output"
      return 0
    fi
  fi
  last_upload_output="$output"
  printf '%s\n' "$output" >&2
  return 1
}

upload_with_retry() {
  local attempt=1
  local max_attempts=3
  local choice

  while true; do
    if upload_command; then
      return 0
    fi

    echo
    echo "Upload failed."
    if [[ "$last_upload_output" =~ stk500_getsync ]] || [[ "$last_upload_output" =~ "not in sync:" ]]; then
      echo "Detected upload sync error (stk500_getsync / not in sync)."
    fi

    if (( attempt >= max_attempts )); then
      echo "Reached maximum retry attempts ($max_attempts)."
      return 1
    fi

    echo "Options:"
    echo "  r) Retry same port"
    echo "  p) Re-select port and retry"
    echo "  a) Abort upload"
    read -rp "Choose action [r/p/a]: " choice
    case "$choice" in
      [rR])
        attempt=$((attempt+1))
        continue
        ;;
      [pP])
        choose_port
        if [[ -z "$SELECTED_PORT" ]]; then
          echo "No port selected; aborting."
          return 1
        fi
        UPLOAD_ARGS=(--upload-port "$SELECTED_PORT")
        attempt=$((attempt+1))
        continue
        ;;
      *)
        return 1
        ;;
    esac
  done
}

perform_upload() {
  if [[ -z "${SELECTED_PORT:-}" ]]; then
    choose_port
  fi
  if [[ -z "$SELECTED_PORT" ]]; then
    echo "Upload aborted: no USB serial port selected."
    return 1
  fi
  UPLOAD_ARGS=(--upload-port "$SELECTED_PORT")
  upload_with_retry
}

while true; do
  if [[ -z "${ENV_NAME:-}" ]]; then
    if ! select_env; then
      continue
    fi
  fi
  echo "Selected: $ENV_NAME"
  MONITOR_SPEED=$(get_monitor_speed)
  MONITOR_SPEED=${MONITOR_SPEED:-115200}

  echo
  echo "Actions:"
  echo "  1) Build"
  echo "  2) Upload"
  echo "  3) Monitor (open serial monitor)"
  echo "  4) Upload + Monitor"
  echo "  5) Clean"
  echo "  6) Install/Update PlatformIO udev rules"
  echo "  7) Upload with retry"
  echo "  8) Upload + Monitor with retry"
  echo "  9) Reselect sketch"
  echo "  q) Quit"
  read -rp "Choose action: " action
  case "$action" in
    1)
      if pdir=$(project_dir_for_env); then
        $PIO run -d "$pdir" -e "$ENV_NAME"
      else
        $PIO run -e "$ENV_NAME"
      fi
      ;;
    2)
      check_platformio_udev_rules || true
      choose_port
      if [[ -z "$SELECTED_PORT" ]]; then
        echo "Upload aborted: no USB serial port selected."
      else
        UPLOAD_ARGS=(--upload-port "$SELECTED_PORT")
        if pdir=$(project_dir_for_env); then
          $PIO run -d "$pdir" -e "$ENV_NAME" -t upload "${UPLOAD_ARGS[@]}"
        else
          $PIO run -e "$ENV_NAME" -t upload "${UPLOAD_ARGS[@]}"
        fi
      fi
      ;;
    3)
      choose_port
      if [[ -z "$SELECTED_PORT" ]]; then
        echo "No port chosen."
      else
        echo "Opening monitor on $SELECTED_PORT at $MONITOR_SPEED bps (Ctrl+C to exit)";
        $PIO device monitor -p "$SELECTED_PORT" -b "$MONITOR_SPEED"
      fi
      ;;
    4)
      check_platformio_udev_rules || true
      choose_port
      if [[ -z "$SELECTED_PORT" ]]; then
        echo "Upload + Monitor aborted: no USB serial port selected."
      else
        UPLOAD_ARGS=(--upload-port "$SELECTED_PORT")
        if pdir=$(project_dir_for_env); then
          $PIO run -d "$pdir" -e "$ENV_NAME" -t upload -t monitor "${UPLOAD_ARGS[@]}"
        else
          $PIO run -e "$ENV_NAME" -t upload -t monitor "${UPLOAD_ARGS[@]}"
        fi
      fi
      ;;
    5)
      if pdir=$(project_dir_for_env); then
        $PIO run -d "$pdir" -e "$ENV_NAME" -t clean
      else
        $PIO run -e "$ENV_NAME" -t clean
      fi
      ;;
    6)
      install_platformio_udev_rules
      ;;
    7)
      check_platformio_udev_rules || true
      perform_upload
      ;;
    8)
      check_platformio_udev_rules || true
      if perform_upload; then
        echo "Upload succeeded. Opening monitor on $SELECTED_PORT at $MONITOR_SPEED bps (Ctrl+C to exit)";
        $PIO device monitor -p "$SELECTED_PORT" -b "$MONITOR_SPEED"
      fi
      ;;
    9)
      ENV_NAME=""
      continue
      ;;
    q|Q)
      exit 0
      ;;
    *)
      echo "Unknown action" ;;
  esac
  echo
  read -rp "Press Enter to continue..." _
done
