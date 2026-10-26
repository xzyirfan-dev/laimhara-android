# LAIMHARA — HANDOFF (baca ini dulu di sesi baru)

Game 3D offline Android "Laimhara" (nostalgia Laghaim Online), Godot 4.3 GDScript, renderer GL Compatibility, arm64.
Pemilik: Irfan (bahasa Indonesia, gaya singkat & direktif, minim basa-basi, Claude boleh ambil keputusan implementasi sendiri).
**Output akhir WAJIB: APK siap install** (kirim sebagai .zip karena batas upload 30 MiB; APK ±75MB, zip ±25MB).

## Syarat tetap dari user
1. JANGAN bergaya Roblox. Harus mirip Laghaim asli: gelap sci-fi fantasy, tekstur bergaya lukis, model runcing/berduri.
2. Ada efek suara (skill, tembakan, monster, ambient, musik).
3. UI profesional (referensi: Black Desert Mobile paper-doll + tas, Lineage mobile tooltip, Lineage2 Revolution HUD).
4. Semua item harus berfungsi (gem/socket, tempa, efek visual per tier). Perlengkapan 9 slot.

## Struktur proyek (res://)
- scripts/: game.gd (autoload G: state, item, stat, drop, tempa, socket), item_db.gd (slot, rarity, gem, bonus, fx level),
  hud.gd (HUD + jendela Karakter/Tas/Toko/Tempa/Socket/Jewel, popup), ui_kit.gd, item_slot.gd, item_card.gd,
  hero.gd (model karakter per-slot: build_eq(equipped)), player.gd, monster.gd, world.gd, models.gd, gfx.gd, data.gd, scaling.gd, title.gd, main.gd
- art/icons (180 PNG ikon), art/ui (bingkai 9-patch, bar, pad) — dibuat oleh tools/art/*.py (PIL). Regenerate: python3 tools/art/build_art.py
- fonts/ Poppins. tools/: selftest.tscn, uishots.tscn (screenshot UI), flow.gd, sign_apk.py, build_apk.sh, setup_env.sh
- Autoload G = res://scripts/game.gd. Viewport 1280x720, stretch canvas_items/expand, landscape.

## Build & uji
- Container baru: `bash tools/setup_env.sh` (unduh Godot+templates, fake Android SDK). Restore kunci ~/.laimhara_key.pem/.laimhara_cert.pem dari backup.
- Build: `bash tools/build_apk.sh` -> build/Laimhara.zip. export_presets.cfg harus `package/signed=false` (ditandatangani oleh tools/sign_apk.py v1+v2).
- Uji: `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/selftest.tscn` (HARUS sebagai scene, bukan --script: autoload G tidak ada di mode script).
- Screenshot UI: res://tools/uishots.tscn -> /home/claude/shots/*.png (llvmpipe lambat; jalankan nohup di background lalu poll).
- Setelah menambah aset/skrip: `godot --headless --path . --import`.

## Jebakan teknis
- GDScript: `var x := dict[...]` gagal (Variant) -> tulis tipe eksplisit. Editor import wajib untuk PNG baru.
- Menu pause tree; HUD process_mode ALWAYS. Joystick/pad multi-touch di Hud._input (jangan diganti Control).
- Upload file maks 30 MiB. Agent sub-sesi sering kena 429 -> kerjakan langsung.
- Workspace container bisa reset: selalu backup ke zip + kirim ke user + simpan ringkasan di memory/Notion.

## STATUS (2026-10-23)
SELESAI: sistem 9 slot+rarity+socket/gem+forge +15, 180 ikon, HUD baru, jendela Karakter (paper-doll 3D), popup item, toko/tempa/socket/jewel, hero per-slot + efek tier, APK v3 terkirim.
BELUM: audio (hilang saat reset), tekstur lukis, model monster/NPC/dunia masih blocky, Roblox-look belum hilang.

## NEXT (urutan disarankan)
1. Verifikasi UI di HP asli (user): ukuran sentuh, scroll tas, popup. Perbaiki sesuai feedback.
2. AUDIO: sintesis via Python (numpy/wave): SFX tembak, skill x6, hit, monster mati, UI klik, level up, potion, forge sukses/gagal, socket; ambient per map; musik kota/hunting. Buat autoload `Sfx` + AudioStreamPlayer pool; simpan .wav/.ogg di res://audio. Hubungkan ke player.gd/monster.gd/hud.gd/game.gd signals.
3. DUNIA: tekstur lukis prosedural (tanah, rumput, batu, pasir, salju per map), langit/kabut gelap, pencahayaan dramatis, prop berduri (pohon mati, kristal, tulang), kota Velamina bergaya Laghaim.
4. MONSTER & NPC: bangun ulang model organik runcing (bukan bola/kotak) per map (10 map) + boss; animasi jalan/serang/mati; NPC berpakaian.
5. Karakter: kepala/rambut/wajah lebih bagus, efek partikel senjata/armor lebih kaya (+9/+12/+15), set bonus aura, sayap tier 400.
6. Fitur: quest tambahan, skill per level, gelar, peta dunia, pengaturan suara/grafis.
7. QA penuh (selftest, flow, screenshot semua map), build, zip, kirim.
