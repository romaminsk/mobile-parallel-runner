#!/usr/bin/env bash
# Параллельный запуск Android-эмуляторов под Appium-прогоны.
# Практика из статьи: Android Emulators in CI (см. README).
set -euo pipefail

EMU="${ANDROID_HOME:-$HOME/Library/Android/sdk}/emulator/emulator"
CONF="$(dirname "$0")/../config/devices.conf"
STAGGER="${STAGGER:-50}"        # пауза между стартами: одновременно нельзя — ADB валится

export ADB_LIBUSB=1             # стабильный бэкенд ADB: меньше устройств «offline»

mapfile -t AVDS < <(grep -E '^avd:' "$CONF" | awk '{print $2}')
[ "${#AVDS[@]}" -gt 0 ] || { echo "нет avd: в $CONF"; exit 1; }

i=0
for avd in "${AVDS[@]}"; do
  port=$((8200 + i))            # systemPort для UiAutomator2 каждого устройства
  echo "[avd=$avd] старт: systemPort=$port"
  nohup "$EMU" -avd "$avd" -no-snapshot -no-audio >/dev/null 2>&1 &
  i=$((i+1))
  sleep "$STAGGER"              # стаггер — главный урок статьи
done

# Дождаться настоящей готовности: boot_completed врёт (см. device-ready.sh)
failed=0
while read -r serial; do
  if "$(dirname "$0")/device-ready.sh" android "$serial"; then
    # чистое состояние приложения перед прогоном:
    # PKG_UNDER_TEST=com.example.app scripts/android-parallel-boot.sh
    if [ -n "${PKG_UNDER_TEST:-}" ]; then
      adb -s "$serial" shell pm clear "$PKG_UNDER_TEST"
    fi
    echo "[serial=$serial] ГОТОВ"
  else
    echo "[serial=$serial] НЕ ГОТОВ (таймаут)" >&2
    failed=1
  fi
done < <(adb devices | awk '/^emulator-/ && $2=="device" {print $1}')

echo "systemPort на каждое устройство: 8200..$((8200 + ${#AVDS[@]} - 1))"
exit $failed
