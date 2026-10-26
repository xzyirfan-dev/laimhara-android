# Laimhara (Godot 4.3)
Alur game: Layar Judul -> Game Baru (nama, warna rambut, rate EXP, intro) / Lanjutkan -> Dunia.
Menu (tombol "Menu" atau tombol Back/ESC): Lanjutkan, Simpan Sekarang, Pengaturan, Kembali ke Menu Utama, Keluar Game.
Save otomatis (user://laimhara_save.txt): tiap 20 dtk, saat pindah map, saat app di-pause/kehilangan fokus, dan saat keluar.
Build APK: godot --headless --path . --import  &&  godot --headless --path . --export-debug "Android" build/laimhara.apk
Tes balance: godot --headless --path . --script tools/selftest.gd
Tes alur UI (butuh display/xvfb): godot --path . --script tools/flow.gd
