#!/usr/bin/env bash
# Честная проверка готовности устройства.
# sys.boot_completed=1 ещё не значит, что устройство принимает команды:
# проверяем dev.bootcomplete и ответ package manager.
set -euo pipefail

type="$1"; id="$2"; timeout="${3:-300}"

is_android_ready() {            # $1 = serial
  local sys dev
  sys="$(adb -s "$1" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
  dev="$(adb -s "$1" shell getprop dev.bootcomplete 2>/dev/null | tr -d '\r' || true)"
  [ "$sys" = "1" ] && [ "$dev" = "1" ] \
    && adb -s "$1" shell pm path android >/dev/null 2>&1
}

is_ios_ready() {                # $1 = UDID симулятора
  [ "$(xcrun simctl list -j devices 2>/dev/null \
      | jq -r --arg u "$1" '.devices[][] | select(.udid==$u) | .state')" = "Booted" ]
}

wait_until() {                  # $1=checker, $2=id, $3=timeout
  local deadline=$((SECONDS + $3))
  until "$1" "$2"; do
    [ "$SECONDS" -ge "$deadline" ] && return 1
    sleep 2
  done
}

case "$type" in
  android) wait_until is_android_ready "$id" "$timeout" ;;
  ios)    wait_until is_ios_ready    "$id" "$timeout" ;;
  *) echo "usage: $0 {android <serial>|ios <udid>} [timeout_sec]"; exit 2 ;;
esac

echo "готов: $type $id"
