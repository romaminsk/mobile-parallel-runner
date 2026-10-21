# mobile-parallel-runner — параллельные прогоны мобильных тестов (WIP)

Скрипты для параллельного запуска мобильных автотестов на локальной device farm:
Android-эмуляторы и iOS-симуляторы, несколько Appium-серверов на выделенных портах,
без облачных ферм.

Санитизированная выжимка практики из серии статей о мобильной инфраструктуре:

- [Android Emulators in CI: Appium, ADB, Ports, and Parallel Runs](https://medium.com/@rnovokhatski/android-emulators-in-ci-appium-adb-ports-and-parallel-runs-b2b3bf943925)
- [iOS Automated Tests in CI: Simulators, WebDriverAgent, and the macOS Tax](https://medium.com/@rnovokhatski/ios-automated-tests-in-ci-simulators-webdriveragent-and-the-macos-tax-39d5275836e3)
- [Why Your Mobile Tests Are Flaky (And How to Stop Blaming Appium)](https://medium.com/@rnovokhatski/why-your-mobile-tests-are-flaky-and-how-to-stop-blaming-appium-f8cb997bc581)

## Что внутри

| Файл | Назначение |
|---|---|
| `scripts/android-parallel-boot.sh` | параллельный старт Android-эмуляторов со стаггером, `ADB_LIBUSB`, ожидание настоящей готовности |
| `scripts/ios-parallel-run.sh` | параллельный старт iOS-симуляторов по UDID, подавление системных попапов, `wdaLocalPort` + отдельный Appium на устройство |
| `scripts/device-ready.sh` | честная проверка готовности: `boot_completed` врёт — проверяем `dev.bootcomplete` и ответ package manager |
| `config/devices.example.conf` | пример карты устройств и портов |

## Ключевые принципы (почему скрипты такие)

- **Не стартовать все эмуляторы одновременно** — ADB валится; между стартами стаггер (`sleep 50` из статьи — не магия, а ровно это)
- **`ADB_LIBUSB=1`** — стабильный бэкенд ADB: меньше устройств, зависающих в «offline»
- **`boot_completed` врёт**: `sys.boot_completed=1` ещё не значит, что устройство принимает команды — двойная проверка
- **Порт на каждое устройство** (`systemPort`, `wdaLocalPort`) + отдельный Appium-сервер: параллельность без драк за порты
- **`pm clear` перед прогоном** — чистое состояние приложения
- **iOS**: `simctl boot` по UDID, подавление AutoFill/парольных попапов, чистый cleanup без удаления девайсов

## Требования

- Android: `adb`, `emulator` (`ANDROID_HOME`), Appium 2.x
- iOS: macOS, Xcode (`simctl`), WebDriverAgent, Appium 2.x + `appium-xcuitest-driver`, `jq`

## Статус

**WIP-скелет**: санитизированные и упрощённые скрипты из реальной практики,
без проприетарного кода и данных. Обрастает по мере времени.
