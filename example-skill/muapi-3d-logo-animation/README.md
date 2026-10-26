# MUAPI 3D Logo Animation integration

Folder ini adalah titik integrasi dokumentasi yang diminta untuk `example-skill/muapi-3d-logo-animation`.

## Status

APK yang diberikan hanya berisi hasil build. Tidak ada source project, file skill, kredensial, atau pipeline MUAPI di dalam ZIP, sehingga integrasi runtime belum dapat diimplementasikan tanpa artefak tersebut.

## Kontrak integrasi yang disarankan

- Input: model/logo 3D dan parameter animasi dari skill MUAPI.
- Output: aset/clip yang kompatibel dengan project Godot asli.
- Packaging: aset dimasukkan ke project Godot, lalu APK dibangun ulang melalui export Android.
- Keamanan: jangan commit API key; gunakan environment variable atau secret manager.

Untuk implementasi nyata, tambahkan source Godot/Android dan definisi skill MUAPI ke repo ini, lalu hubungkan output animasi ke scene/project sebelum menjalankan pipeline export.
