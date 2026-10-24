extends Node
## Autoload "G": state game, inventori, drop, tempa, save/load.

signal toast(msg: String, big: bool)
signal loot(msg: String)
signal leveled
signal look_changed
signal saved
signal back_pressed
signal to_title

const SAVE_PATH := "user://laimhara_save.txt"
const BAG_MAX := 120

var lv := 1
var xp := 0
var hp := 100.0
var mp := 60.0
var laima := 5000
var karu := 0
var equipped: Dictionary = {}
var weapon: Dictionary:
	get:
		return equipped.get("weapon", {})
	set(v):
		equipped["weapon"] = v
var armor: Dictionary:
	get:
		return equipped.get("armor", {})
	set(v):
		equipped["armor"] = v
var bag: Array = []
var stacks: Dictionary = {}
var sold: Array = []
var skills: Dictionary = {}
var visited: Array = [0, 1]
var map_id := 0
var quest_kills := 0
var daily_date := ""
var daily_progress: Dictionary = {}
var daily_claimed: Dictionary = {}
var achievement_claimed: Dictionary = {}
var total_kills := 0
var dungeon_kills := 0
var elite_kills := 0
var capsule_t := 0.0
var shield_t := 0.0
var shield_frac := 0.0
var joy := Vector2.ZERO
var settings := {"exp_mult": 1000, "drop_mult": 6, "death_penalty": true, "auto_potion": true, "auto_sell": true, "auto_attack": true, "auto_hunt": false,
	"auto_sell_max_rarity": 1, "auto_sell_max_tier": 400, "auto_sell_keep_sets": true, "auto_sell_keep_options": true,
	"auto_sell_keep_plus": true, "auto_sell_keep_socket": true, "auto_sell_keep_upgrades": true}
var _uid := 1
var player_name := "Arken"
var hair_idx := 0
var in_game := false
var last_save := ""
var _save_t := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_daily_reset_if_needed()
	capsule_t = maxf(0.0, capsule_t - delta)
	shield_t = maxf(0.0, shield_t - delta)
	_save_t += delta
	if _save_t > 20.0:
		_save_t = 0.0
		save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back_pressed.emit()

func has_save() -> bool:
	return save_info().size() > 0

## Ringkasan save untuk layar judul (tanpa memuat ke state game).
func save_info() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var d = str_to_var(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY or not d.has("lv"):
		return {}
	var mid := clampi(int(d.get("map_id", 0)), 0, Data.MAPS.size() - 1)
	return {"name": str(d.get("name", "Arken")), "lv": int(d.get("lv", 1)), "map": str(Data.MAPS[mid].name), "ts": str(d.get("ts", ""))}

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

# ---------- new / save / load ----------
func new_game(pname: String = "Arken", hair: int = 0, exp_rate: int = 1000) -> void:
	player_name = pname
	hair_idx = hair
	settings.exp_mult = exp_rate
	lv = 1
	xp = 0
	laima = 5000
	karu = 0
	equipped = {}
	for sl in ItemDb.SLOTS:
		equipped[sl] = {}
	for sl in ["weapon", "armor", "helm", "boots"]:
		equipped[sl] = make_item(sl, 1, 0, 0)
	bag = []
	stacks = {"hp": 10, "mp": 5, "tp": 3, "warp": 5, "g_ruby1": 1, "g_emerald1": 1}
	sold = []
	quest_kills = 0
	daily_date = Time.get_date_string_from_system()
	daily_progress = {"kills": 0, "dungeon_kills": 0, "elite_kills": 0}
	daily_claimed = {}
	achievement_claimed = {}
	total_kills = 0
	dungeon_kills = 0
	elite_kills = 0
	visited = [0, 1]
	map_id = 0
	_init_skills()
	hp = float(max_hp())
	mp = float(max_mp())

func _init_skills() -> void:
	for s in Data.SKILLS:
		if not skills.has(s.id):
			skills[s.id] = {"lv": 1, "xp": 0.0}

func save_game() -> void:
	if not in_game:
		return
	last_save = Time.get_time_string_from_system()
	var d := {"name": player_name, "hair": hair_idx, "ts": Time.get_datetime_string_from_system(false, true), "lv": lv, "xp": xp, "hp": hp, "mp": mp, "laima": laima, "karu": karu, "eq": equipped,
		"bag": bag, "stacks": stacks, "skills": skills, "visited": visited, "map_id": map_id, "quest": quest_kills,
		"settings": settings, "capsule": capsule_t, "uid": _uid, "daily_date": daily_date, "daily_progress": daily_progress,
		"daily_claimed": daily_claimed, "achievement_claimed": achievement_claimed, "total_kills": total_kills,
		"dungeon_kills": dungeon_kills, "elite_kills": elite_kills}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(var_to_str(d))
		f.close()
		saved.emit()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var d = str_to_var(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return false
	player_name = str(d.get("name", "Arken"))
	hair_idx = clampi(int(d.get("hair", 0)), 0, Data.HAIR_COLORS.size() - 1)
	lv = int(d.get("lv", 1))
	xp = int(d.get("xp", 0))
	hp = float(d.get("hp", 100.0))
	mp = float(d.get("mp", 60.0))
	laima = int(d.get("laima", 0))
	karu = int(d.get("karu", 0))
	equipped = {}
	if d.has("eq"):
		equipped = d.get("eq", {})
	else:
		equipped = {"weapon": d.get("weapon", {}), "armor": d.get("armor", {})}
	for sl in ItemDb.SLOTS:
		if not equipped.has(sl):
			equipped[sl] = {}
		elif not equipped[sl].is_empty():
			_fix_item(equipped[sl])
	bag = d.get("bag", [])
	for it in bag:
		_fix_item(it)
	stacks = d.get("stacks", {})
	skills = d.get("skills", {})
	visited = d.get("visited", [0, 1])
	map_id = int(d.get("map_id", 0))
	quest_kills = int(d.get("quest", 0))
	daily_date = str(d.get("daily_date", Time.get_date_string_from_system()))
	daily_progress = d.get("daily_progress", {"kills": 0, "dungeon_kills": 0, "elite_kills": 0})
	daily_claimed = d.get("daily_claimed", {})
	achievement_claimed = d.get("achievement_claimed", {})
	total_kills = int(d.get("total_kills", quest_kills))
	dungeon_kills = int(d.get("dungeon_kills", 0))
	elite_kills = int(d.get("elite_kills", 0))
	capsule_t = float(d.get("capsule", 0.0))
	_uid = int(d.get("uid", 1))
	var st: Dictionary = d.get("settings", {})
	for k in st.keys():
		settings[k] = st[k]
	_daily_reset_if_needed()
	_init_skills()
	if equipped_list().is_empty() and bag.is_empty():
		return false
	hp = clampf(hp, 1.0, float(max_hp()))
	return true

func _daily_reset_if_needed() -> void:
	var today := Time.get_date_string_from_system()
	if daily_date == "":
		daily_date = today
	if daily_date != today:
		daily_date = today
		daily_progress = {"kills": 0, "dungeon_kills": 0, "elite_kills": 0}
		daily_claimed = {}
		toast.emit("Quest harian telah diperbarui!", true)

func daily_value(key: String) -> int:
	_daily_reset_if_needed()
	return int(daily_progress.get(key, 0))

func achievement_value(stat: String) -> int:
	match stat:
		"kills": return total_kills
		"dungeon_kills": return dungeon_kills
		"elite_kills": return elite_kills
		"maps": return visited.size()
		"level": return lv
		"tier400":
			for it in equipped_list() + bag:
				if int(it.get("tier", 0)) >= 400:
					return 1
	return 0

func claim_daily(id: String) -> bool:
	_daily_reset_if_needed()
	for q in Data.DAILY_QUESTS:
		if String(q.id) != id or bool(daily_claimed.get(id, false)):
			continue
		if daily_value(String(q.key)) < int(q.target):
			return false
		daily_claimed[id] = true
		match id:
			"daily_hunt":
				laima += int(Scaling.laima_kill(lv) * 40.0)
				gain_xp(Scaling.exp_need(lv) / 2)
			"daily_dungeon":
				karu += 3
				add_stack("safety", 1)
			"daily_elite":
				laima += int(Scaling.laima_kill(lv) * 80.0)
				add_stack("aeth1", 1)
		toast.emit("Quest selesai: %s" % q.name, true)
		return true
	return false

func claim_achievement(id: String) -> bool:
	if bool(achievement_claimed.get(id, false)):
		return false
	for a in Data.ACHIEVEMENTS:
		if String(a.id) != id:
			continue
		if achievement_value(String(a.stat)) < int(a.target):
			return false
		achievement_claimed[id] = true
		match id:
			"first_blood", "monster_hunter", "thousand_souls":
				laima += int(Scaling.laima_kill(lv) * 100.0)
				karu += 2
			"dungeon_runner":
				karu += 5
				add_stack("aeth1", 1)
			"boss_breaker":
				add_stack("safety", 1)
				add_stack("w100", 1)
			"world_tour":
				laima += int(Scaling.laima_kill(lv) * 250.0)
				karu += 10
			"level_master":
				laima += int(Scaling.laima_kill(lv) * 500.0)
				add_stack("aeth1", 2)
			"arsenal":
				karu += 5
				add_stack("safety", 1)
		toast.emit("Achievement terbuka: %s" % a.name, true)
		return true
	return false

# ---------- items ----------
func make_item(slot: String, tier: int, set_t: int = 0, rar: int = -1) -> Dictionary:
	_uid += 1
	var r := rar
	if r < 0:
		r = ItemDb.roll_rarity()
	if set_t > 0:
		r = maxi(r, 3)
	var n := ItemDb.nsock(slot, tier, r)
	var soc: Array = []
	for i in n:
		soc.append("")
	return {"uid": _uid, "slot": slot, "tier": tier, "plus": 0, "roll": 1.0, "setn": set_t, "opts": [], "fails": 0, "rar": r, "soc": soc}

func _fix_item(it: Dictionary) -> void:
	if not it.has("rar"):
		it["rar"] = 0
	if not it.has("soc"):
		var soc: Array = []
		for i in ItemDb.nsock(String(it.slot), int(it.tier), int(it.rar)):
			soc.append("")
		it["soc"] = soc
	if not it.has("opts"):
		it["opts"] = []

func equipped_list() -> Array:
	var out: Array = []
	for sl in ItemDb.SLOTS:
		var it: Dictionary = equipped.get(sl, {})
		if not it.is_empty():
			out.append(it)
	return out

func all_items() -> Array:
	var out: Array = equipped_list()
	out.append_array(bag)
	return out

func look_key() -> String:
	var parts: Array = []
	for sl in ItemDb.SLOTS:
		var it: Dictionary = equipped.get(sl, {})
		if it.is_empty():
			parts.append("-")
		else:
			parts.append("%d.%d.%d.%d" % [int(it.tier), int(it.plus), int(it.rar), int(it.get("setn", 0))])
	return "|".join(parts)

func forge_mult(plus: int) -> float:
	return 1.0 + 0.12 * float(mini(plus, 10)) + 0.2 * float(maxi(plus - 10, 0))

func item_power(it: Dictionary) -> float:
	if it.is_empty():
		return 0.0
	var base: float
	if it.slot == "weapon":
		base = Scaling.weapon_atk(int(it.tier))
	else:
		base = Scaling.armor_def(int(it.tier)) * float(ItemDb.DEF_W[it.slot])
	return base * float(it.roll) * ItemDb.RARITY_MULT[int(it.get("rar", 0))] * forge_mult(int(it.plus))

func item_score(it: Dictionary) -> float:
	if it.is_empty():
		return 0.0
	var s: float = item_power(it)
	var tot := 0.0
	for k in ItemDb.item_bonuses(it).values():
		tot += float(k)
	return s * (1.0 + tot / 100.0) + 0.001

func item_name(it: Dictionary) -> String:
	var s: String = "%s T%d" % [ItemDb.base_name(it.slot, int(it.tier)), int(it.tier)]
	if it.plus > 0:
		s += " +%d" % it.plus
	if it.setn > 0:
		s = "[SET] " + s
	return s

func opt_text(o: Dictionary) -> String:
	return "%s +%d%%" % [ItemDb.BONUS_NAME[o.k], int(o.v)]

func item_stat_text(it: Dictionary) -> String:
	return ("ATK " if it.slot == "weapon" else "DEF ") + Scaling.fmt(int(item_power(it)))

func item_desc(it: Dictionary) -> String:
	var s: String = item_name(it) + "  (" + item_stat_text(it) + ")"
	for o in it.opts:
		s += "\n   + " + opt_text(o)
	return s

## total satu jenis bonus pada SATU item (bawaan + option + gem)
func opt_sum(it: Dictionary, k: String) -> float:
	return float(ItemDb.item_bonuses(it).get(k, 0.0))

## total bonus dari semua perlengkapan yang dipakai
func bonus(k: String) -> float:
	var s := 0.0
	for it in equipped_list():
		s += opt_sum(it, k)
	return s

func sell_value(it: Dictionary) -> int:
	var gem_v := 0.0
	for gid in it.get("soc", []):
		if String(gid) != "":
			gem_v += float(ItemDb.gem_parse(String(gid)).grade)
	return int(Scaling.price(int(it.tier)) * 0.3 * (1.0 + 0.5 * float(it.plus)) * (1.0 + 0.5 * float(it.get("rar", 0))) * (1.0 + 0.1 * gem_v))

func set_count() -> int:
	var cnt: Dictionary = {}
	var best := 0
	for it in equipped_list():
		var sn: int = int(it.get("setn", 0))
		if sn > 0:
			cnt[sn] = int(cnt.get(sn, 0)) + 1
			best = maxi(best, int(cnt[sn]))
	return best

func set_mult() -> float:
	var c := set_count()
	if c >= 2:
		return minf(1.3, 1.0 + 0.04 * float(c))
	return 1.0

func equip(it: Dictionary) -> void:
	var sl: String = it.slot
	var cur: Dictionary = equipped.get(sl, {})
	bag.erase(it)
	if not cur.is_empty():
		bag.append(cur)
	equipped[sl] = it
	hp = minf(hp, float(max_hp()))

func unequip(slot: String) -> bool:
	if bag.size() >= BAG_MAX:
		return false
	var cur: Dictionary = equipped.get(slot, {})
	if not cur.is_empty():
		bag.append(cur)
		equipped[slot] = {}
	hp = minf(hp, float(max_hp()))
	return true

func is_equipped(it: Dictionary) -> bool:
	var cur: Dictionary = equipped.get(String(it.slot), {})
	return not cur.is_empty() and int(cur.uid) == int(it.uid)

func is_upgrade(it: Dictionary) -> bool:
	var cur: Dictionary = equipped.get(String(it.slot), {})
	return item_score(it) > item_score(cur)

func auto_sell_allowed(it: Dictionary) -> bool:
	if not settings.auto_sell:
		return false
	return sell_filter_allowed(it)

func sell_filter_allowed(it: Dictionary) -> bool:
	if int(it.get("tier", 1)) > int(settings.auto_sell_max_tier):
		return false
	if int(it.get("rar", 0)) > int(settings.auto_sell_max_rarity):
		return false
	if bool(settings.auto_sell_keep_sets) and int(it.get("setn", 0)) > 0:
		return false
	if bool(settings.auto_sell_keep_options) and not it.get("opts", []).is_empty():
		return false
	if bool(settings.auto_sell_keep_plus) and int(it.get("plus", 0)) > 0:
		return false
	if bool(settings.auto_sell_keep_socket):
		for gid in it.get("soc", []):
			if String(gid) != "":
				return false
	if bool(settings.auto_sell_keep_upgrades) and is_upgrade(it):
		return false
	return true

func add_equip(it: Dictionary) -> String:
	if auto_sell_allowed(it):
		laima += sell_value(it)
		return "sold"
	if bag.size() >= BAG_MAX:
		laima += sell_value(it)
		return "full"
	bag.append(it)
	return "bag"

func remove_item(it: Dictionary) -> void:
	if is_equipped(it):
		equipped[String(it.slot)] = {}
	else:
		bag.erase(it)

# ---------- gem / socket ----------
func gem_stack(gid: String) -> int:
	return stack_count("g_" + gid)

func socket_cost(it: Dictionary, grade: int) -> int:
	return int(Scaling.price(int(it.tier)) * 0.04 * float(grade))

func socket_gem(it: Dictionary, idx: int, gid: String) -> String:
	if idx < 0 or idx >= it.soc.size():
		return "Socket tidak ada"
	if gem_stack(gid) < 1:
		return "Permata habis"
	var p := ItemDb.gem_parse(gid)
	var cost := socket_cost(it, int(p.grade))
	if laima < cost:
		return "Laima tidak cukup (%s)" % Scaling.fmt(cost)
	laima -= cost
	take_stack("g_" + gid, 1)
	var old: String = String(it.soc[idx])
	it.soc[idx] = gid
	hp = minf(hp, float(max_hp()))
	if old != "":
		return "Dipasang %s (permata lama %s hancur)" % [ItemDb.gem_name(gid), ItemDb.gem_name(old)]
	return "Dipasang %s: %s" % [ItemDb.gem_name(gid), ItemDb.gem_text(gid)]

func unsocket_gem(it: Dictionary, idx: int) -> String:
	if idx < 0 or idx >= it.soc.size() or String(it.soc[idx]) == "":
		return "Socket kosong"
	var cost := int(Scaling.price(int(it.tier)) * 0.06)
	if laima < cost:
		return "Laima tidak cukup (%s)" % Scaling.fmt(cost)
	laima -= cost
	var old: String = String(it.soc[idx])
	it.soc[idx] = ""
	hp = minf(hp, float(max_hp()))
	return "%s dilepas (hancur)" % ItemDb.gem_name(old)

func combine_cost(grade: int) -> int:
	return int(Scaling.laima_kill(lv) * 3.0 * float(grade))

func combine_gem(gid: String) -> String:
	var p := ItemDb.gem_parse(gid)
	if int(p.grade) >= 5:
		return "Sudah tingkat tertinggi"
	if gem_stack(gid) < 3:
		return "Butuh 3 permata sama"
	var cost := combine_cost(int(p.grade))
	if laima < cost:
		return "Laima tidak cukup (%s)" % Scaling.fmt(cost)
	laima -= cost
	take_stack("g_" + gid, 3)
	var nid := ItemDb.gem_id(String(p.type), int(p.grade) + 1)
	add_stack("g_" + nid, 1)
	return "Jadi %s!" % ItemDb.gem_name(nid)

# ---------- stacks ----------
func stack_count(id: String) -> int:
	return int(stacks.get(id, 0))

func add_stack(id: String, n: int) -> void:
	stacks[id] = stack_count(id) + n

func take_stack(id: String, n: int) -> bool:
	if stack_count(id) < n:
		return false
	stacks[id] = stack_count(id) - n
	return true

func use_potion(kind: String) -> bool:
	if stack_count(kind) < 1:
		return false
	if kind == "hp":
		if hp >= float(max_hp()):
			return false
		take_stack("hp", 1)
		hp = minf(float(max_hp()), hp + 0.4 * float(max_hp()))
	else:
		if mp >= float(max_mp()):
			return false
		take_stack("mp", 1)
		mp = minf(float(max_mp()), mp + 0.4 * float(max_mp()))
	return true

# ---------- stats ----------
func str_val() -> int:
	return 5 + 2 * lv

func vit_val() -> int:
	return 5 + 2 * lv

func max_hp() -> int:
	return int(Scaling.player_base_hp(lv) * (1.0 + bonus("hp") / 100.0))

func max_mp() -> int:
	return 60 + 10 * lv

func skill_lv(id: String) -> int:
	return int(skills[id].lv)

func marks_bonus() -> float:
	return 0.10 + float(skill_lv("marks") - 1) * 1.9 / 24.0

func pen_bonus() -> float:
	if lv < 110:
		return 0.0
	return 0.2 + float(skill_lv("pen") - 1) * 0.2

func snipe_range() -> float:
	if lv < 15:
		return 0.0
	return 2.0 + float(skill_lv("snipe") - 1) * 1.75

func eagle_bonus() -> float:
	if lv < 30:
		return 0.0
	return 1.0 + float(skill_lv("eagle_eye") - 1) * 0.55

func overcharge_bonus() -> float:
	if lv < 120:
		return 0.0
	return 0.08 + float(skill_lv("overcharge") - 1) * 0.035

func phase_evade_bonus() -> float:
	if lv < 220:
		return 0.0
	return 0.02 + float(skill_lv("phase_shift") - 1) * 0.012

func atk() -> float:
	var s := float(str_val())
	var a: float = (item_power(weapon) + 2.5 * float(lv)) * (1.0 + s / (s + 600.0)) * set_mult()
	a *= 1.0 + marks_bonus() + pen_bonus() + overcharge_bonus() + bonus("dmg") / 100.0
	return a

func def_value() -> float:
	var d := 0.0
	for it in equipped_list():
		if it.slot != "weapon":
			d += item_power(it)
	return d * (1.0 + bonus("def") / 100.0) * set_mult()

func evade_chance() -> float:
	return minf(0.5, bonus("evade") / 100.0 + phase_evade_bonus())

func move_mult() -> float:
	return 1.0 + minf(0.5, bonus("speed") / 100.0)

func crit_chance() -> float:
	return minf(0.8, 0.05 + float(lv) * 0.0003 + bonus("crit") / 100.0)

func calc_hit(mult: float) -> Dictionary:
	var a: float = atk() * mult * randf_range(0.92, 1.08)
	var crit := false
	if randf() < crit_chance():
		a *= 1.5
		crit = true
	if randf() < minf(0.5, bonus("fatal") / 100.0):
		a *= 2.0
		crit = true
	return {"dmg": maxi(1, int(a)), "crit": crit}

func dmg_taken(raw: float) -> float:
	var d := def_value()
	var red := d / (d + 6.0 * float(lv) + 30.0)
	return maxf(1.0, raw * (1.0 - red))

# ---------- exp / level ----------
func gain_xp(amount: int) -> void:
	if lv >= Scaling.MAX_LEVEL:
		return
	if capsule_t > 0.0:
		amount *= 2
	xp += amount
	var old := lv
	while lv < Scaling.MAX_LEVEL and xp >= Scaling.exp_need(lv):
		xp -= Scaling.exp_need(lv)
		lv += 1
	if lv != old:
		hp = float(max_hp())
		mp = float(max_mp())
		toast.emit("LEVEL UP!  Lv %d" % lv, true)
		for s in Data.SKILLS:
			if s.unlock > old and s.unlock <= lv:
				toast.emit("Skill baru: " + s.name, false)
		leveled.emit()
	if lv >= Scaling.MAX_LEVEL:
		xp = 0

func skill_use(id: String) -> void:
	var s: Dictionary = skills[id]
	var def: Dictionary = Data.skill(id)
	if s.lv >= def.max:
		return
	var gain: float = 10.0 * (1.0 + 0.05 * float(s.lv))
	if int(settings.exp_mult) < 100:
		gain *= 0.1
	s.xp = float(s.xp) + gain
	var need: float = 20.0 * pow(float(s.lv), 1.3)
	while float(s.xp) >= need and s.lv < def.max:
		s.xp = float(s.xp) - need
		s.lv += 1
		toast.emit("%s naik ke Lv %d" % [def.name.get_slice(" (", 0), s.lv], false)
		need = 20.0 * pow(float(s.lv), 1.3)

# ---------- kill / drops ----------
func _monster_is_dungeon(m) -> bool:
	if m is Dictionary:
		return bool(m.get("dungeon", false))
	return bool(m.dungeon)

func _monster_drop_tier(m, fallback: int) -> int:
	if m is Dictionary:
		return int(m.get("drop_tier", m.get("map_max", fallback)))
	return int(m.drop_tier)

func on_kill(m) -> void:
	var kmul: float = [1.0, 3.0, 20.0][m.kind]
	var dungeon_mult: float = 2.0 if _monster_is_dungeon(m) else 1.0
	var xpv := int(Scaling.exp_kill(m.lv) * float(settings.exp_mult) / 1000.0 * kmul * m.exp_factor * dungeon_mult)
	gain_xp(xpv)
	var lg := int(Scaling.laima_kill(m.lv) * [1.0, 2.0, 10.0][m.kind])
	laima += lg
	quest_kills += 1
	total_kills += 1
	_daily_reset_if_needed()
	daily_progress["kills"] = daily_value("kills") + 1
	if _monster_is_dungeon(m):
		dungeon_kills += 1
		daily_progress["dungeon_kills"] = daily_value("dungeon_kills") + 1
	if int(m.kind) >= 1:
		elite_kills += 1
		daily_progress["elite_kills"] = daily_value("elite_kills") + 1
	loot.emit("Erfahrung : %s,  Laima : %s" % [Scaling.fmt(xpv), Scaling.fmt(lg)])
	for line in roll_drops(m):
		loot.emit(line)

func roll_drops(m) -> Array:
	var out: Array = []
	var dm := float(settings.drop_mult)
	var k: int = m.kind
	var mk: float = [1.0, 3.0, 5.0][k]
	var l: int = m.lv
	var dungeon: bool = _monster_is_dungeon(m)
	if randf() < minf(0.95, 0.15 * dm):
		var id := "hp" if randf() < 0.6 else "mp"
		var n := randi_range(1, 2)
		add_stack(id, n)
		out.append("%s x%d" % [Data.STACK_NAMES[id], n])
	if dungeon and k == 2:
		var boss_tier: int = clampi(_monster_drop_tier(m, l), 1, Scaling.MAX_LEVEL)
		var set_tier: int = int(m.map_sets[0]) if not m.map_sets.is_empty() and int(m.map_sets[0]) <= boss_tier else 0
		var boss_item := make_item(ItemDb.SLOTS.pick_random(), boss_tier, set_tier, 4)
		var boss_res := add_equip(boss_item)
		out.append("DUNGEON BOSS: " + item_name(boss_item) + (" (dijual otomatis)" if boss_res != "bag" else ""))
		add_stack("safety", 1)
		out.append("Dungeon: Safety Stone x1")
	elif k == 2 or randf() < minf(0.95, 0.03 * dm * mk):
		var t := Scaling.tier_for(l)
		if dungeon:
			t = clampi(maxi(t, _monster_drop_tier(m, l) - 10), 1, Scaling.MAX_LEVEL)
		var r := randf()
		if r < 0.15:
			t = Scaling.tier_down(t)
		elif r > 0.95:
			t = mini(Scaling.tier_up(t), Scaling.tier_for(m.map_max))
		var it := make_item(ItemDb.SLOTS.pick_random(), t)
		var res := add_equip(it)
		out.append("Drop: " + item_name(it) + (" (dijual otomatis)" if res != "bag" else ""))
	if k == 2 or dungeon:
		for st in m.map_sets:
			if l >= st and randf() < 0.25:
				var si := make_item(ItemDb.SLOTS.pick_random(), st, st)
				add_equip(si)
				out.append("SET DROP: " + item_name(si))
	if randf() < minf(0.95, 0.04 * dm * mk):
		add_stack("gem", 1)
		out.append("Gem Kasar")
	if randf() < minf(0.9, 0.025 * dm * mk):
		var gg := 1 + mini(4, l / 80)
		if randf() < 0.2 and gg > 1:
			gg -= 1
		elif randf() < 0.06 and gg < 5:
			gg += 1
		var gid := ItemDb.gem_id(ItemDb.GEM_TYPES.pick_random(), gg)
		add_stack("g_" + gid, 1)
		out.append("Permata: " + ItemDb.gem_name(gid))
	if randf() < 0.002 * dm * mk:
		add_stack("safety", 1)
		out.append("Safety Stone!")
	if randf() < 0.002 * dm * mk:
		add_stack("w50", 1)
		out.append("Warranty 50%!")
	if k == 2 and randf() < 0.005 * dm:
		add_stack("w100", 1)
		out.append("Warranty 100%!!")
	if k == 2:
		var c := randi_range(3, 10)
		karu += c
		out.append("Koin Karu x%d" % c)
	elif k == 1 and randf() < 0.1:
		karu += 1
		out.append("Koin Karu x1")
	return out

func on_death() -> void:
	if settings.death_penalty:
		laima -= int(float(laima) * 0.005)
	hp = float(max_hp())
	mp = float(max_mp())
	toast.emit("Kamu kalah! Kembali ke kota.", true)

# ---------- forge ----------
func forge_rate(it: Dictionary, wmode: String, safe: bool) -> float:
	var arr: Array = Scaling.RATES_W if it.slot == "weapon" else Scaling.RATES_A
	var r: float = float(arr[it.plus])
	r += float(Scaling.PITY[mini(int(it.fails), 5)])
	if wmode == "w100":
		return 100.0
	if wmode == "w50":
		r += 50.0
	if safe:
		r -= 10.0
	return clampf(r, 1.0, 99.99)

func forge_cost(it: Dictionary) -> int:
	return int(Scaling.price(it.tier) * 0.3 * (1.0 + float(it.plus)))

func forge(it: Dictionary, wmode: String, safe: bool) -> String:
	if it.plus >= 15:
		return "Sudah maksimal (+15)"
	var cost := forge_cost(it)
	if laima < cost:
		return "Laima tidak cukup"
	if wmode != "none" and stack_count(wmode) < 1:
		return "Warranty habis"
	if safe and stack_count("safety") < 1:
		return "Safety Stone habis"
	laima -= cost
	if wmode != "none":
		take_stack(wmode, 1)
	if safe:
		take_stack("safety", 1)
	if randf() * 100.0 < forge_rate(it, wmode, safe):
		it.plus += 1
		it.fails = 0
		return "BERHASIL! " + item_name(it)
	it.fails += 1
	if safe:
		return "Gagal... Safety Stone melindungi item."
	if it.slot != "weapon" and it.plus >= 5 and randf() < 0.03:
		var nm := item_name(it)
		remove_item(it)
		return "ITEM HANCUR: " + nm
	it.plus = maxi(0, it.plus - 1)
	return "Gagal, turun ke +%d" % it.plus

func confusion(it: Dictionary) -> String:
	var cost := int(Scaling.price(it.tier) * 0.5)
	if it.tier < 260:
		return "Confusion hanya untuk tier 260+"
	if laima < cost or stack_count("gem") < 3:
		return "Butuh %s Laima + 3 Gem Kasar" % Scaling.fmt(cost)
	laima -= cost
	take_stack("gem", 3)
	it.roll = snappedf(randf_range(0.9, 1.1), 0.001)
	return "Stat diacak: x%.3f" % it.roll

func add_option(it: Dictionary, grade: String) -> String:
	if it.tier < 350:
		return "Option hanya untuk item tier 350+"
	if it.opts.size() >= 3:
		return "Slot option penuh (Reset dulu)"
	if not take_stack(grade, 1):
		return "Jewel habis"
	var chances := {"aeth4": 0.10, "aeth3": 0.20, "aeth2": 0.40, "aeth1": 0.80}
	if randf() > float(chances[grade]):
		return "Gagal, jewel hancur"
	var kinds: Array = ItemDb.OPT_OFF if (it.slot == "weapon" or it.slot == "gloves" or it.slot == "ring") else ItemDb.OPT_DEF
	var kk: String = kinds.pick_random()
	var vals := {"dmg": [2, 5, 10], "crit": [3, 6, 12], "fatal": [3, 6, 12], "def": [5, 10, 15], "hp": [5, 10, 15]}
	var rr := randf()
	var idx := 0 if rr < 0.6 else (1 if rr < 0.9 else 2)
	var o := {"k": kk, "v": float(vals[kk][idx])}
	it.opts.append(o)
	return "Option: " + opt_text(o)
