#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v adb >/dev/null || { echo 'adb tidak ditemukan. Install Android Platform Tools terlebih dahulu.' >&2; exit 1; }
./scripts/verify-apk.sh
adb start-server >/dev/null
adb wait-for-device
adb install -r apk/Laimhara_v3_baru.apk
printf 'Terpasang. Menjalankan com.irfan.laimhara3...\n'
adb shell monkey -p com.irfan.laimhara3 1 >/dev/null
