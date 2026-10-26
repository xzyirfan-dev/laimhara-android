# Laimhara Android (Godot 4.3)

Laimhara adalah MMORPG offline bergaya dark cyberpunk industrial untuk Android, dibangun dengan Godot 4.3 dan renderer GL Compatibility.

## Fitur utama

- Monster per spot dengan level tetap per map dan batas kepadatan.
- Dungeon tematik per map dengan monster spesial, loot tier tinggi, dan boss.
- Quest bounty monster berulang setiap 20 kill, quest harian, dan achievement permanen.
- Crafting berbasis resep/material, mount Cyber Runner, world event, combo hunt, dan reputasi faksi.
- Terrain prosedural bertema dengan bukit, lembah, sungai, tebing, dan struktur map.
- Kamera free-orbit: rotasi 360°, pitch, dan zoom.
- Joystick mobile diperbaiki; menu yang sebelumnya scroll memakai pagination untuk interaksi Android yang stabil.
- Equipment bertier dengan bonus, opsi, efek, dan visual forge.

Guild, PvP, dan dungeon key tidak digunakan sesuai spesifikasi.

## Validasi

Self-test runtime dijalankan dengan Godot headless/Xvfb dan menghasilkan:

- Level 400: 7.985 kill pada simulasi progression.
- Save/load roundtrip berhasil.
- Semua menu pagination dan menu inventory/NPC berhasil dibuka.
- Skill cast berhasil.
- Crafting, mount, meteor event, combo bonus, dan reputasi berhasil.

Perintah validasi:

```bash
/home/ubuntu/tools/Godot_v4.3-stable_linux.x86_64 --headless --editor --path . --quit
xvfb-run -a godot --path . --rendering-driver opengl3 --scene res://tools/selftest.tscn
```

## Build dan signing

```bash
/home/ubuntu/tools/Godot_v4.3-stable_linux.x86_64 --headless --path . --export-release Android build/laimhara.apk
python3 tools/sign_apk.py build/laimhara.apk build/Laimhara-final.apk
zip -9 build/Laimhara-final.zip build/Laimhara-final.apk
```

Signing key disimpan di luar repository (`~/.laimhara_key.pem` dan `~/.laimhara_cert.pem`). ZIP distribusi final berisi APK signed dan berukuran di bawah batas 30 MB.
