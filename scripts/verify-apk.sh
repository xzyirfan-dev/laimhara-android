#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test -s apk/Laimhara_v3_baru.apk
sha256sum --check apk/SHA256SUMS
unzip -tq apk/Laimhara_v3_baru.apk
printf 'APK OK: checksum and ZIP integrity verified.\n'
