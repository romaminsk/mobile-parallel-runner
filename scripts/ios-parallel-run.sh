#!/usr/bin/env bash
# Параллельный запуск iOS-симуляторов + по Appium-серверу на устройство.
# Практика из статьи: iOS Automated Tests in CI (см. README).
set -euo pipefail

CONF="$(dirname "$0")/../config/devices.conf"
WDA_PORT_BASE="${WDA_PORT_BASE:-8100}"
APPIUM_PORT_BASE="${APPIUM_PORT_BASE:-4723}"

mapfile -t UDIDS < <(grep -E '^udid:' "$CONF" | awk '{print $2}')
[ "${#UDIDS[@]}" -gt 0 ] || { echo "нет udid: в $CONF"; exit 1; }

cleanup() {
  echo "cleanup: гасим Appium и симуляторы (без удаления девайсов)"
  pkill -f "appium --port" 2>/dev/null || true
  for udid in "${UDIDS[@]}"; do xcrun simctl shutdown "$udid" 2>/dev/null || true; done
}
trap cleanup EXIT

i=0
for udid in "${UDIDS[@]}"; do
  wda=$((WDA_PORT_BASE + i)); appium_port=$((APPIUM_PORT_BASE + i))
  echo "[udid=$udid] boot: wdaLocalPort=$wda, appiumPort=$appium_port"

  xcrun simctl boot "$udid" 2>/dev/null || true   # уже Booted — не ошибка

  # Подавление AutoFill/парольных попапов — они съедают тапы в CI (техника из статьи)
  xcrun simctl spawn "$udid" defaults write .GlobalPreferences \
    AutomaticStrongPasswordsEnabled -bool false 2>/dev/null || true

  # Отдельный Appium на каждое устройство: wdaLocalPort + udid в default capabilities
  nohup appium --port "$appium_port" \
    --default-capabilities "{\"appium:udid\":\"$udid\",\"appium:wdaLocalPort\":$wda,\"appium:platformName\":\"iOS\"}" \
    >"/tmp/appium-$udid.log" 2>&1 &

  i=$((i+1))
done

# Дождаться готовности всех симуляторов
for udid in "${UDIDS[@]}"; do
  "$(dirname "$0")/device-ready.sh" ios "$udid"
done

echo "Запущено ${#UDIDS[@]} Appium-серверов: порты $APPIUM_PORT_BASE..$((APPIUM_PORT_BASE + ${#UDIDS[@]} - 1))"
echo "Ждём Ctrl+C — cleanup погасит Appium и симуляторы, не удаляя девайсы."
wait
