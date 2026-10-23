#!/bin/bash
# Pulihkan lingkungan build di container baru (Godot 4.3 + templates + fake Android SDK).
set -e
mkdir -p /home/claude/tools && cd /home/claude/tools
[ -f Godot_v4.3-stable_linux.x86_64 ] || { curl -sSL -o godot.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip && unzip -q -o godot.zip; }
T=~/.local/share/godot/export_templates/4.3.stable
if [ ! -d $T ]; then curl -sSL -o templates.tpz https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz && mkdir -p $T && unzip -q -o templates.tpz -d /tmp/tpl && cp -r /tmp/tpl/templates/* $T/; fi
S=/home/claude/tools/sdk
mkdir -p $S/platform-tools $S/build-tools/34.0.0 $S/cmdline-tools/latest/bin $S/platforms/android-34
for f in $S/platform-tools/adb $S/cmdline-tools/latest/bin/sdkmanager $S/build-tools/34.0.0/apksigner $S/build-tools/34.0.0/zipalign; do printf '#!/bin/sh\n' > $f; chmod +x $f; done
JH=$(dirname $(dirname $(readlink -f $(which java))))
mkdir -p ~/.config/godot
printf '[gd_resource type="EditorSettings" format=3]\n\n[resource]\nexport/android/android_sdk_path = "%s"\nexport/android/java_sdk_path = "%s"\n' $S $JH > ~/.config/godot/editor_settings-4.3.tres
echo "env OK. Kunci tanda tangan: ~/.laimhara_key.pem & ~/.laimhara_cert.pem (restore dari backup agar update APK bisa menimpa)"
