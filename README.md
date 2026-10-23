# Laimhara Android APK

Distribusi APK Laimhara v3 untuk Android. Repo ini dibuat dari artefak APK yang diberikan, bukan dari source project Godot/Android.

## Isi repo

- `apk/Laimhara_v3_baru.apk` — APK release yang diberikan.
- `apk/SHA256SUMS` — checksum SHA-256 untuk verifikasi integritas.
- `metadata/apk.json` — metadata package/version/SDK hasil inspeksi.
- `scripts/install.sh` — instalasi ke perangkat Android melalui ADB.
- `scripts/verify-apk.sh` — verifikasi checksum dan struktur APK.
- `example-skill/muapi-3d-logo-animation/` — kontrak integrasi dokumentasi untuk skill/asset 3D; source skill tidak tersedia di ZIP.

## Instalasi Android

1. Aktifkan **Developer options** dan **USB debugging** pada perangkat Android.
2. Pasang Android Platform Tools sehingga perintah `adb` tersedia.
3. Jalankan:

```bash
./scripts/verify-apk.sh
./scripts/install.sh
```

Atau secara langsung:

```bash
adb install -r apk/Laimhara_v3_baru.apk
adb shell monkey -p com.irfan.laimhara3 1
```

APK menargetkan Android SDK 34 dan minimum SDK 21. ABI yang tersedia pada artefak ini adalah `arm64-v8a`.

## Batasan source

ZIP sumber hanya berisi satu APK. APK tidak dapat diperlakukan sebagai source project Android/Godot yang dapat dibangun ulang secara maintainable. Untuk build APK baru, perubahan UI, atau integrasi engine yang sesungguhnya, diperlukan source project Godot/Android asli beserta aset dan konfigurasi build.

## Lisensi dan distribusi

Pastikan Anda memiliki hak distribusi atas APK dan aset yang disertakan sebelum membuat repo publik atau mendistribusikan APK lebih lanjut.
