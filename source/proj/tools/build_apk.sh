#!/bin/bash
# Build + sign APK Laimhara. Jalankan dari root proyek: bash tools/build_apk.sh
set -e
G=${GODOT:-/home/claude/tools/Godot_v4.3-stable_linux.x86_64}
$G --headless --path . --import >/dev/null 2>&1 || true
mkdir -p build
$G --headless --path . --export-release Android build/laimhara.apk 2>&1 | tail -3
python3 tools/sign_apk.py build/laimhara.apk build/Laimhara.apk
cd build && rm -f Laimhara.zip && zip -9 -q Laimhara.zip Laimhara.apk && ls -la Laimhara.zip
