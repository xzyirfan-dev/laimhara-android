class_name ItemDb
extends RefCounted
## Basis data perlengkapan: 9 slot, rarity, socket + gem, bonus bawaan, nama per tier.

const SLOTS := ["weapon", "helm", "armor", "gloves", "boots", "cloak", "belt", "neck", "ring"]
const SLOT_LABEL := {
	"weapon": "Senjata", "helm": "Helm", "armor": "Zirah", "gloves": "Sarung Tangan", "boots": "Sepatu",
	"cloak": "Jubah", "belt": "Sabuk", "neck": "Kalung", "ring": "Cincin",
}
## bobot DEF per slot (jumlah = 1.0 -> set penuh sama dengan zirah lama)
const DEF_W := {"armor": 0.32, "helm": 0.16, "gloves": 0.10, "boots": 0.10, "cloak": 0.12, "belt": 0.08, "neck": 0.06, "ring": 0.06}

const RARITY_NAME := ["Biasa", "Langka", "Epik", "Legenda", "Mitos"]
const RARITY_COL := [Color(0.82, 0.84, 0.88), Color(0.4, 0.85, 0.5), Color(0.38, 0.62, 1.0), Color(0.75, 0.42, 1.0), Color(1.0, 0.66, 0.2)]
const RARITY_MULT := [1.0, 1.04, 1.1, 1.18, 1.3]

const NAMES := {
	"weapon": ["Pistol Latihan", "Pistol Perunggu", "Senapan Badai", "Senapan Rantai", "Senapan GWH", "Senapan Magralis", "Senapan Ragnok"],
	"helm": ["Topi Latihan", "Helm Perunggu", "Helm Tanduk Badai", "Helm Penjaga", "Mahkota Tanduk Putih", "Mahkota Moriath", "Mahkota Ragnok"],
	"armor": ["Zirah Latihan", "Zirah Perunggu", "Zirah Badai", "Zirah Penjaga", "Zirah Tanduk Putih", "Zirah Moriath", "Zirah Ragnok"],
	"gloves": ["Sarung Kulit", "Sarung Perunggu", "Gauntlet Badai", "Gauntlet Penjaga", "Gauntlet Tanduk Putih", "Cakar Moriath", "Gauntlet Ragnok"],
	"boots": ["Sepatu Latihan", "Sepatu Perunggu", "Sepatu Badai", "Sepatu Penjaga", "Sepatu Tanduk Putih", "Sepatu Moriath", "Sepatu Ragnok"],
	"cloak": ["Jubah Latihan", "Jubah Perunggu", "Jubah Badai", "Jubah Penjaga", "Jubah Tanduk Putih", "Jubah Moriath", "Sayap Ragnok"],
	"belt": ["Sabuk Latihan", "Sabuk Perunggu", "Sabuk Badai", "Sabuk Penjaga", "Sabuk Tanduk Putih", "Sabuk Moriath", "Sabuk Ragnok"],
	"neck": ["Kalung Latihan", "Kalung Perunggu", "Kalung Badai", "Kalung Penjaga", "Kalung Tanduk Putih", "Kalung Moriath", "Kalung Ragnok"],
	"ring": ["Cincin Latihan", "Cincin Perunggu", "Cincin Badai", "Cincin Penjaga", "Cincin Tanduk Putih", "Cincin Moriath", "Cincin Ragnok"],
}

const GEM_TYPES := ["ruby", "topaz", "amethyst", "emerald", "sapphire"]
const GEM_GRADE := ["Kasar", "Biasa", "Halus", "Sempurna", "Agung"]
const GEMS := {
	"ruby": {"n": "Rubi", "k": "dmg", "v": [2, 4, 7, 11, 16], "c": Color(0.95, 0.15, 0.2)},
	"topaz": {"n": "Topaz", "k": "crit", "v": [1, 2, 3, 5, 8], "c": Color(1.0, 0.8, 0.15)},
	"amethyst": {"n": "Amethyst", "k": "fatal", "v": [1, 2, 3, 5, 8], "c": Color(0.7, 0.3, 1.0)},
	"emerald": {"n": "Zamrud", "k": "def", "v": [3, 6, 10, 15, 22], "c": Color(0.2, 0.9, 0.4)},
	"sapphire": {"n": "Safir", "k": "hp", "v": [3, 6, 10, 15, 22], "c": Color(0.25, 0.55, 1.0)},
}
const BONUS_NAME := {"dmg": "Total Damage", "crit": "Critical Hit", "fatal": "Fatal Hit", "def": "Total DEF", "hp": "Max HP", "speed": "Kecepatan Gerak", "evade": "Evasi"}

const OPT_OFF := ["dmg", "crit", "fatal"]
const OPT_DEF := ["def", "hp"]

static func pal_idx(t: int) -> int:
	if t >= 400:
		return 6
	if t >= 320:
		return 5
	if t >= 200:
		return 4
	if t >= 100:
		return 3
	if t >= 50:
		return 2
	if t >= 10:
		return 1
	return 0

static func is_def_slot(slot: String) -> bool:
	return slot != "weapon"

static func base_name(slot: String, t: int) -> String:
	return NAMES[slot][pal_idx(t)]

static func rarity_color(it: Dictionary) -> Color:
	return RARITY_COL[clampi(int(it.get("rar", 0)), 0, 4)]

static func nsock(slot: String, t: int, rar: int) -> int:
	var p := pal_idx(t)
	var n := 1 + (1 if p >= 2 else 0) + (1 if p >= 4 else 0) + (1 if rar >= 3 else 0)
	if slot == "ring" or slot == "neck":
		n -= 1
	return clampi(n, 1, 4)

static func roll_rarity(luck: float = 1.0) -> int:
	var r := randf() / maxf(0.2, luck)
	if r < 0.01:
		return 4
	if r < 0.05:
		return 3
	if r < 0.15:
		return 2
	if r < 0.40:
		return 1
	return 0

# ---------- gem ----------
static func gem_id(type: String, grade: int) -> String:
	return "%s%d" % [type, grade]

static func gem_parse(gid: String) -> Dictionary:
	if gid == "":
		return {}
	var g := int(gid.substr(gid.length() - 1))
	var t := gid.substr(0, gid.length() - 1)
	return {"type": t, "grade": g}

static func gem_name(gid: String) -> String:
	var p := gem_parse(gid)
	if p.is_empty():
		return "-"
	return "%s %s" % [GEMS[p.type].n, GEM_GRADE[p.grade - 1]]

static func gem_bonus(gid: String) -> Dictionary:
	var p := gem_parse(gid)
	if p.is_empty():
		return {}
	var g: Dictionary = GEMS[p.type]
	return {"k": g.k, "v": float(g.v[p.grade - 1])}

static func gem_text(gid: String) -> String:
	var b := gem_bonus(gid)
	if b.is_empty():
		return ""
	return "%s +%d%%" % [BONUS_NAME[b.k], int(b.v)]

static func stack_name(id: String) -> String:
	if id.begins_with("g_"):
		return "Permata " + gem_name(id.substr(2))
	return Data.STACK_NAMES.get(id, id)

# ---------- bonus bawaan slot ----------
static func inherent(it: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	if it.is_empty():
		return out
	var p := pal_idx(int(it.tier))
	var sc: float = (1.0 + 0.04 * float(it.get("plus", 0))) * (1.0 + 0.08 * float(it.get("rar", 0)))
	match String(it.slot):
		"gloves":
			out["dmg"] = (1.0 + 1.5 * float(p)) * sc
		"boots":
			out["speed"] = (2.0 + 1.5 * float(p)) * sc
		"cloak":
			out["evade"] = (1.0 + 0.8 * float(p)) * sc
		"belt":
			out["hp"] = (2.0 + 1.5 * float(p)) * sc
		"neck":
			out["hp"] = (3.0 + 2.0 * float(p)) * sc
		"ring":
			out["crit"] = (1.0 + 0.9 * float(p)) * sc
	return out

## semua bonus satu item (bawaan + option + gem) sebagai {kunci: nilai}
static func item_bonuses(it: Dictionary) -> Dictionary:
	var out: Dictionary = inherent(it)
	if it.is_empty():
		return out
	for o in it.get("opts", []):
		out[o.k] = float(out.get(o.k, 0.0)) + float(o.v)
	for gid in it.get("soc", []):
		var b := gem_bonus(String(gid))
		if not b.is_empty():
			out[b.k] = float(out.get(b.k, 0.0)) + float(b.v)
	return out

# ---------- efek visual (level 0..4) ----------
static func weapon_fx(it: Dictionary) -> int:
	if it.is_empty():
		return 0
	var pl: int = int(it.plus)
	var lv := 0
	if pl >= 15:
		lv = 4
	elif pl >= 12:
		lv = 3
	elif pl >= 9:
		lv = 2
	elif pl >= 6:
		lv = 1
	if int(it.get("rar", 0)) >= 3 or int(it.get("setn", 0)) > 0:
		lv = maxi(lv, 1)
	return lv

static func armor_fx(eq: Dictionary) -> int:
	var tot := 0
	var cnt := 0
	for s in SLOTS:
		if s == "weapon" or not eq.has(s) or eq[s].is_empty():
			continue
		tot += int(eq[s].plus)
		cnt += 1
	if cnt == 0:
		return 0
	var avg := float(tot) / float(cnt)
	var lv := 0
	if avg >= 14.0:
		lv = 4
	elif avg >= 11.0:
		lv = 3
	elif avg >= 8.0:
		lv = 2
	elif avg >= 5.0:
		lv = 1
	return lv
