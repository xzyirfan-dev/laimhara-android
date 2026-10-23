class_name Data
extends RefCounted
## Data statis: map, skill, nama item.

const MAPS := [
	{"id": 0, "name": "Kota Velamina", "min": 1, "max": 400, "town": true, "color": Color(0.45, 0.62, 0.4), "sky": Color(0.6, 0.78, 0.95), "mobs": [], "boss": "", "mc": Color.WHITE, "sets": []},
	{"id": 1, "name": "Padang Latihan Velamina", "min": 1, "max": 20, "town": false, "color": Color(0.36, 0.62, 0.3), "sky": Color(0.6, 0.8, 0.95), "mobs": ["Slime Padang", "Tikus Taring", "Belalang Besar"], "boss": "Raja Slime", "mc": Color(0.4, 0.85, 0.4), "sets": []},
	{"id": 2, "name": "Hutan Karnok", "min": 21, "max": 40, "town": false, "color": Color(0.2, 0.45, 0.22), "sky": Color(0.45, 0.65, 0.5), "mobs": ["Goblin Hutan", "Serigala Karnok", "Jamur Beracun"], "boss": "Ratu Spora", "mc": Color(0.65, 0.45, 0.2), "sets": []},
	{"id": 3, "name": "Lembah Badai", "min": 41, "max": 70, "town": false, "color": Color(0.5, 0.55, 0.4), "sky": Color(0.5, 0.55, 0.7), "mobs": ["Elang Petir", "Troll Lembah", "Golem Batu"], "boss": "Elang Badai", "mc": Color(0.5, 0.6, 0.95), "sets": []},
	{"id": 4, "name": "Gua Dekara", "min": 50, "max": 80, "town": false, "color": Color(0.25, 0.22, 0.3), "sky": Color(0.12, 0.1, 0.16), "mobs": ["Kelelawar Gua", "Kalajengking Batu", "Skeleton Dekara"], "boss": "Dekara Warden", "mc": Color(0.7, 0.7, 0.8), "sets": []},
	{"id": 5, "name": "Gurun Tanduk Putih", "min": 70, "max": 100, "town": false, "color": Color(0.85, 0.75, 0.5), "sky": Color(0.95, 0.85, 0.65), "mobs": ["Kalajengking Pasir", "Mumi Gurun", "Banteng Tanduk"], "boss": "Tanduk Putih", "mc": Color(0.9, 0.6, 0.3), "sets": [100]},
	{"id": 6, "name": "Rimba Magralis", "min": 100, "max": 150, "town": false, "color": Color(0.15, 0.4, 0.3), "sky": Color(0.3, 0.5, 0.45), "mobs": ["Ular Magralis", "Ent Rimba", "Harimau Hantu"], "boss": "Magralis", "mc": Color(0.3, 0.8, 0.6), "sets": []},
	{"id": 7, "name": "Kota Terkutuk Moriath", "min": 150, "max": 200, "town": false, "color": Color(0.3, 0.25, 0.3), "sky": Color(0.25, 0.18, 0.3), "mobs": ["Zombie Moriath", "Wraith", "Gargoyle"], "boss": "Lich Moriath", "mc": Color(0.6, 0.4, 0.8), "sets": [200]},
	{"id": 8, "name": "Ngarai Abadi", "min": 200, "max": 250, "town": false, "color": Color(0.55, 0.3, 0.25), "sky": Color(0.7, 0.4, 0.3), "mobs": ["Wyvern Muda", "Golem Magma", "Iblis Ngarai"], "boss": "Wyrm Abadi", "mc": Color(1.0, 0.4, 0.2), "sets": []},
	{"id": 9, "name": "Puncak Ragnok", "min": 250, "max": 300, "town": false, "color": Color(0.8, 0.85, 0.9), "sky": Color(0.75, 0.85, 0.95), "mobs": ["Yeti Ragnok", "Naga Es", "Titan Salju"], "boss": "Ragnok", "mc": Color(0.6, 0.85, 1.0), "sets": []},
	{"id": 10, "name": "Dimensi Chaos", "min": 300, "max": 400, "town": false, "color": Color(0.2, 0.1, 0.3), "sky": Color(0.12, 0.05, 0.2), "mobs": ["Chaos Spawn", "Void Walker", "Dimensi Horor"], "boss": "Chaos Emperor", "mc": Color(0.9, 0.2, 0.9), "sets": [320, 400]},
	]

static func dungeon_for(map_id: int) -> Dictionary:
	var base: Dictionary = MAPS[map_id].duplicate(true)
	var special_mobs: Array = []
	for mob in base.mobs:
		special_mobs.append("Dungeon " + str(mob))
	var dungeon_max: int = mini(400, maxi(int(base.max), int(Scaling.tier_for(int(base.max))) + 20))
	return {
		"id": int(base.id),
		"base_id": int(base.id),
		"name": "Dungeon " + str(base.name),
		"min": int(base.min),
		"max": dungeon_max,
		"town": false,
		"color": base.color.lightened(0.08),
		"sky": base.sky.darkened(0.08),
		"mobs": special_mobs,
		"boss": "Boss Dungeon " + str(base.boss),
		"mc": base.mc.lightened(0.12),
		"sets": base.sets,
		"dungeon": true,
		"drop_tier": dungeon_max
	}

const SKILLS := [
		{"id": "marks", "name": "Marksmanship (pasif: bonus damage)", "short": "", "unlock": 1, "max": 25, "kind": "p", "cd": 0.0, "f": 0.0},
		{"id": "snipe", "name": "Sniping (pasif: jangkauan)", "short": "", "unlock": 15, "max": 5, "kind": "p", "cd": 0.0, "f": 0.0},
		{"id": "pen", "name": "Penetration (pasif: tembus DEF)", "short": "", "unlock": 110, "max": 5, "kind": "p", "cd": 0.0, "f": 0.0},
		{"id": "eagle_eye", "name": "Eagle Eye (pasif: presisi)", "short": "", "unlock": 30, "max": 10, "kind": "p", "cd": 0.0, "f": 0.0},
		{"id": "overcharge", "name": "Overcharge Core (pasif: damage)", "short": "", "unlock": 120, "max": 10, "kind": "p", "cd": 0.0, "f": 0.0},
		{"id": "phase_shift", "name": "Phase Shift (pasif: evasi)", "short": "", "unlock": 220, "max": 10, "kind": "p", "cd": 0.0, "f": 0.0},
	{"id": "power", "name": "Tembakan Kuat", "short": "Kuat", "unlock": 1, "max": 25, "kind": "a", "cd": 3.0, "f": 1.0},
	{"id": "shield", "name": "Electric Shield", "short": "Perisai", "unlock": 15, "max": 25, "kind": "a", "cd": 20.0, "f": 1.5},
	{"id": "semi", "name": "Semi-automatic Fire", "short": "Semi", "unlock": 50, "max": 25, "kind": "a", "cd": 4.0, "f": 1.5},
	{"id": "frozen", "name": "Frozen Shot", "short": "Beku", "unlock": 101, "max": 25, "kind": "a", "cd": 6.0, "f": 2.0},
	{"id": "air", "name": "Air Raid", "short": "Raid", "unlock": 200, "max": 20, "kind": "a", "cd": 12.0, "f": 3.0},
		{"id": "fire", "name": "Fire Blindly", "short": "Api", "unlock": 300, "max": 30, "kind": "a", "cd": 20.0, "f": 4.0},
		{"id": "pierce", "name": "Piercing Barrage", "short": "Pierce", "unlock": 40, "max": 25, "kind": "a", "cd": 7.0, "f": 2.2},
		{"id": "gravity", "name": "Gravity Well", "short": "Gravitasi", "unlock": 130, "max": 20, "kind": "a", "cd": 15.0, "f": 3.0},
		{"id": "prism", "name": "Crystal Prism", "short": "Prism", "unlock": 180, "max": 20, "kind": "a", "cd": 18.0, "f": 2.5},
		{"id": "meteor", "name": "Meteor Salvo", "short": "Meteor", "unlock": 240, "max": 20, "kind": "a", "cd": 24.0, "f": 4.0},
		{"id": "void", "name": "Void Rift", "short": "Void", "unlock": 350, "max": 15, "kind": "a", "cd": 30.0, "f": 5.0},
]

const STACK_NAMES := {
	"hp": "Potion HP", "mp": "Potion MP", "tp": "Town Portal Scroll", "warp": "Warp Scroll",
	"gem": "Gem Kasar", "safety": "Safety Stone", "w50": "Warranty 50%", "w100": "Warranty 100%",
	"aeth4": "Aetherial Jewel G4", "aeth3": "Aetherial Jewel G3", "aeth2": "Aetherial Jewel G2", "aeth1": "Aetherial Jewel G1",
	"capsule": "Double EXP Capsule (30 mnt)",
}

# Katalog NPC sengaja tetap. Level karakter hanya menentukan akses map, bukan isi toko.
const NPC_EQUIPMENT_TIERS := [1, 10, 50, 100, 200, 320, 400]
const NPC_SUPPORT_STOCK := [
	["hp", [1, 10, 50, 100], 25], ["mp", [1, 10, 50, 100], 25],
	["tp", [1, 5, 20], 120], ["warp", [1, 5, 20], 240],
	["capsule", [1, 3, 10], 2500], ["safety", [1, 3, 10], 5000],
	["w50", [1, 3, 10], 8000], ["w100", [1, 3, 10], 30000]
]
const NPC_GEM_PRICES := {1: 1200, 2: 3600}
const NPC_JEWEL_PRICES := {"aeth4": 2500, "aeth3": 7500, "aeth2": 20000, "aeth1": 60000}

const W_NAMES := {1: "Pistol Latihan", 10: "Pistol Perunggu", 50: "Senapan Badai", 100: "Senapan Rantai", 200: "Senapan GWH", 320: "Senapan Magralis", 400: "Senapan Ragnok"}
const A_NAMES := {1: "Zirah Latihan", 10: "Zirah Perunggu", 50: "Zirah Badai", 100: "Zirah Penjaga", 200: "Zirah Tanduk Putih", 320: "Zirah Moriath", 400: "Zirah Ragnok"}

static func skill(id: String) -> Dictionary:
	for s in SKILLS:
		if s.id == id:
			return s
	return {}

static func actives() -> Array:
	var a: Array = []
	for s in SKILLS:
		if s.kind == "a":
			a.append(s)
	return a

static func item_base_name(slot: String, t: int) -> String:
	var names: Dictionary = W_NAMES if slot == "weapon" else A_NAMES
	var best := 1
	for k in names.keys():
		if k <= t and k > best:
			best = k
	return names[best]


# ---------- role-play: teks NPC, lore ras Human, deskripsi skill, lore map ----------
const RACE_LORE := "Human — ras penembak dari Velamina. Tidak punya sihir; mereka bertarung dengan senapan berenergi Electric Power (EP). Lemah dalam HP, tetapi mematikan dari jauh. Ahli memotong permata dan merakit perangkat kecil."

const NPCS := {
	"forge": {"name": "Dargan, Raja Tempa", "role": "Penempa", "greet": ["Hmph. Senjata yang tidak ditempa hanyalah besi mati, Penembak.", "Bawa senapanmu. Palu Dargan belum pernah menolak logam yang jujur."], "lore": "Dargan menempa senapan tiap pasukan Velamina sejak perang Moriath. Konon palunya menyala sendiri bila bertemu bahan langka."},
	"shop_class": {"name": "Senapan Sari", "role": "Penjual Senjata", "greet": ["Selamat datang, sesama Human! Senapan baru, zirah baru — pilih sesuai level-mu.", "Stok kami ikut level-mu. Jangan pamer Pistol Latihan di Gua Dekara, ya."], "lore": "Sari dulu penembak jitu garis depan. Kini ia menjual senjata kepada penembak muda dan menjaga rahasia Marksmanship."},
	"shop_potion": {"name": "Apoteker Rania", "role": "Penjual Ramuan", "greet": ["Potion HP dan MP segar, baru kuracik pagi ini.", "Jangan lupa Town Portal. Banyak yang pulang dalam peti karena hemat satu scroll."], "lore": "Rania meracik ramuan dari jamur Hutan Karnok. Ia selalu menolak menyebut resep rahasianya."},
	"market": {"name": "Pasar Campuran", "role": "Pedagang Barang", "greet": ["Barang drop? Aku beli, tiga puluh persen nilainya. Adil untuk kita berdua.", "Gem Kasar, gear bekas — bawa semua. Pasar tidak pernah tutup."], "lore": "Pasar Campuran dikelola para pedagang keliling yang menghidupi Velamina sejak kota berdiri."},
	"jewel": {"name": "Tukang Permata", "role": "Ahli Aetherial Jewel", "greet": ["Aetherial Jewel menyimpan opsi. Item tier tinggi bisa menampung hingga tiga.", "Gunakan Jewel G1 jika kau berani — peluangnya paling besar."], "lore": "Konon Tukang Permata mampu mendengar cahaya batu. Para Human memanggilnya Penjinak Kristal."},
	"karu": {"name": "Pedagang Karu", "role": "Penukar Koin Karu", "greet": ["Koin Karu bukan sekadar logam. Itu bukti kau pernah melawan hal yang menakutkan.", "Tukarkan Karu dengan barang yang tidak dijual siapa pun."], "lore": "Karu adalah koin langka yang jatuh dari makhluk-makhluk kuat. Hanya sedikit yang tahu asal tempanya."},
	"gate": {"name": "Penjaga Gerbang", "role": "Warp Stone", "greet": ["Gerbang terbuka ke tempat mana pun yang pernah kau datangi.", "Kunci yang belum terbuka akan terbuka bila levelmu mendekat."], "lore": "Warp Stone adalah pecahan menara kuno. Para penjaga gerbang bersumpah tidak pernah mengirim siapa pun ke tempat yang salah."},
	"quest": {"name": "Papan Misi", "role": "Misi Velamina", "greet": ["Tertulis: Padang Latihan butuh penembak. Tembak 25 monster dan ambil hadiahmu.", "Tertulis: Kota menghargai mereka yang pulang hidup-hidup."], "lore": "Papan Misi berdiri sejak raja pertama Velamina. Tiap pengumuman ditulis tangan oleh warga kota."},
	"camp": {"name": "Pedagang Camp", "role": "Perbekalan", "greet": ["Harga naik lima puluh persen — aku harus mengangkut ini lewat monster, bukan?", "Beli di sini, atau pulang jalan kaki ke kota. Terserah."], "lore": "Pedagang Camp nekat membuka tenda di zona berbahaya. Konon ia sudah selamat dari tiga serangan Elite."},
}

const SKILL_DESC := {
	"marks": "Dibutuhkan untuk menggunakan senapan. Makin tinggi level, makin besar bonus damage (hingga +200%).",
	"snipe": "Menembak musuh dari jauh. Jangkauan tembak bertambah di tiap level.",
	"pen": "Peluru menembus sebagian DEF musuh.",
	"power": "Tembakan terpusat, damage jauh lebih besar dari tembakan biasa.",
	"shield": "Electric Shield: menanggung sebagian damage fisik menggantikan HP. Menyerap hingga 50% damage.",
	"semi": "Semi-automatic Fire: menembak dua sampai tiga kali berturut-turut.",
	"frozen": "Tembakan beku: damage besar dan memperlambat target.",
	"air": "Air Raid: hujan peluru pada semua musuh di sekitar.",
	"fire": "Fire Blindly: tembakan membabi buta ke banyak target di area luas.",
	"eagle_eye": "Mata elang memperbesar jangkauan serang dan membuat setiap tembakan lebih presisi.",
	"overcharge": "Inti EP melampaui batas aman. Bonus damage meningkat dan proyektil meninggalkan jejak energi.",
	"phase_shift": "Tubuh bergeser sepersekian detik dari dimensi ini, meningkatkan peluang menghindar.",
	"pierce": "Piercing Barrage: rentetan peluru energi menembus beberapa musuh dalam satu garis.",
	"gravity": "Gravity Well: pusaran gravitasi menghantam dan menarik musuh di sekitar penembak.",
	"prism": "Crystal Prism: enam sinar prismatik membelah arena dan menghantam target terdekat.",
	"meteor": "Meteor Salvo: bombardir meteor EP menghujani area luas dengan ledakan berantai.",
	"void": "Void Rift: retakan dimensi melepaskan badai energi gelap berulang kali.",
}

const MAP_LORE := {
	0: "Kota Velamina — ibu kota para Human. Dinding bata tua, air mancur pusat, dan pohon emas yang menandai musim panen.",
	1: "Padang Latihan Velamina — padang hijau tempat penembak baru menguji bidikan pertama.",
	2: "Hutan Karnok — hutan pinus gelap. Jamur beracun dan serigala berkeliaran saat senja.",
	3: "Lembah Badai — tebing berbatu dengan petir yang tak pernah berhenti.",
	4: "Gua Dekara — lorong gelap penuh kristal biru dan rangka para penjaga lama.",
	5: "Gurun Tanduk Putih — lautan pasir dengan tulang raksasa dan banteng bertanduk gading.",
	6: "Rimba Magralis — hutan hujan pekat. Ular raksasa menjaga jantung rimba.",
	7: "Kota Terkutuk Moriath — reruntuhan bangsa yang terkena kutukan. Arwah gentayangan.",
	8: "Ngarai Abadi — jurang merah, lava, dan wyvern yang mengitari langit.",
	9: "Puncak Ragnok — puncak salju beku. Titan es menjaga puncaknya.",
	10: "Dimensi Chaos — retakan dunia. Pecahan kristal ungu melayang di kehampaan.",
}

const INTRO := [
	"Kau Arken, penembak Human dari Velamina.",
	"Dengan senapan berenergi Electric Power, kau akan menaklukkan Padang Latihan hingga Dimensi Chaos.",
	"Bicaralah dengan para NPC di kota. Papan Misi menunggumu.",
]

const HAIR_COLORS := [
	{"n": "Perak", "c": Color(0.8, 0.86, 0.98)},
	{"n": "Hitam", "c": Color(0.12, 0.1, 0.14)},
	{"n": "Cokelat", "c": Color(0.42, 0.26, 0.14)},
	{"n": "Pirang", "c": Color(0.95, 0.8, 0.4)},
	{"n": "Merah", "c": Color(0.8, 0.18, 0.15)},
	{"n": "Biru", "c": Color(0.25, 0.5, 0.95)},
]
const EXP_RATES := [1, 10, 100, 1000]
const RESERVED_NAMES := ["gm", "admin", "moderator", "system", "sistem", "npc", "laimhara"]
