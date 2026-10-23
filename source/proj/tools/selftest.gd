extends Node

func _ready() -> void:
	var root := get_tree().root
	var g = root.get_node("G")
	g.in_game = true
	g.new_game()
	# 1) Simulasi leveling: bunuh monster selevel sampai Lv 400
	var kills := 0
	var marks := {50: 0, 100: 0, 200: 0, 300: 0, 400: 0}
	while g.lv < 400 and kills < 200000:
		var l: int = g.lv
		var xpv := int(Scaling.exp_kill(l) * 1.0)
		g.gain_xp(xpv)
		kills += 1
		if marks.has(g.lv) and marks[g.lv] == 0:
			marks[g.lv] = kills
	print("KILLS sampai Lv400: ", kills, "  milestone: ", marks)
	# 2) Waktu perkiraan (3.5 dtk per kill + jalan 1.5 dtk)
	print("Perkiraan jam main sampai Lv400: %.1f" % (kills * 5.0 / 3600.0))
	# 3) TTK dan damage taken per level
	for l in [1, 10, 50, 100, 200, 300, 400]:
		g.lv = l
		g.weapon = g.make_item("weapon", Scaling.tier_for(l))
		g.armor = g.make_item("armor", Scaling.tier_for(l))
		var hit: float = g.atk()
		var hp := Scaling.mons_hp(l, 0)
		var dmg: float = g.dmg_taken(Scaling.mons_atk(l, 0))
		print("Lv%d: atk=%d  monHP=%d  hit/kill=%.1f  TTK=%.1fs  dmg/hit=%d (%.1f%% HP)" % [l, int(hit), int(hp), hp / hit, hp / hit * 0.8, int(dmg), dmg / float(g.max_hp()) * 100.0])
	# 4) Forge
	g.new_game()
	var it = g.make_item("weapon", 100)
	g.laima = 100000000
	g.add_stack("w100", 20)
	var res := ""
	for i in 10:
		res = g.forge(it, "w100", false)
	print("Forge 10x W100: plus=", it.plus, " ", res)
	# 5) Drop test x1000 kill
	g.new_game()
	g.lv = 100
	var fake := {"kind": 0, "lv": 100, "map_max": 100, "map_sets": [], "exp_factor": 1.0}
	var eq := 0
	for i in 1000:
		var d = g.roll_drops(fake)
		for line in d:
			if str(line).begins_with("Drop"):
				eq += 1
	print("Drop equip per 1000 kill (x6): ", eq, "  bag=", g.bag.size())
	# 6) Save/load roundtrip
	g.save_game()
	var lv_before: int = g.lv
	g.lv = 1
	print("Load ok: ", g.load_game(), "  lv ", lv_before, "->", g.lv)
	# 7) Scene + semua menu
	g.new_game()
	var scn: PackedScene = load("res://main.tscn")
	var main = scn.instantiate()
	root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	main._start("test")
	await get_tree().process_frame
	await get_tree().process_frame
	var hud: Hud = main.hud
	var it2 = g.make_item("weapon", 360)
	g.bag.append(it2)
	g.sold.append({"item": g.make_item("armor", 20), "price": 5})
	for sl in ItemDb.SLOTS:
		var ni = g.make_item(sl, 360)
		g.bag.append(ni)
	g.stacks["g_ruby3"] = 5
	g.stacks["g_emerald2"] = 3
	g.laima = 999999999
	for m in ["_menu_pause", "_menu_skill", "_menu_settings", "_menu_scroll", "_menu_warp", "_menu_market", "_menu_buyback", "_menu_jewel", "_menu_combine", "_menu_karu", "_menu_quest"]:
		var rows = hud.call(m)
		print("menu ", m, " ", "control" if rows is Control else "rows=%d" % rows.size())
		hud.push_menu(m, Callable(hud, m))
		await get_tree().process_frame
		hud.close_menu()
	for m in ["_win_char", "_menu_class_shop", "_menu_forge_list", "_menu_gem_shop", "_menu_option_list"]:
		hud.push_menu(m, Callable(hud, m))
		await get_tree().process_frame
		print("menu ", m, " ok")
		hud.close_menu()
	print("potion rows=", hud._menu_potion(1.5).size())
	# socket + forge + tooltip
	hud.sock_sel = "ruby3"
	hud.push_menu("Socket", func(): return hud._menu_socket(it2))
	await get_tree().process_frame
	print(g.socket_gem(it2, 0, "ruby3"), " | dmg bonus item=", g.opt_sum(it2, "dmg"))
	print(g.combine_gem("emerald2"), " ", g.gem_stack("emerald3"))
	hud.close_menu()
	hud.push_menu("Tempa", func(): return hud._menu_forge_item(it2))
	await get_tree().process_frame
	hud.close_menu()
	hud._popup_item(it2)
	hud._popup_stack("hp")
	hud._popup_stack("g_ruby3")
	hud.close_popup()
	for i in 6:
		g.forge(it2, "w100", false)
	print("forge +", it2.plus, " power=", int(g.item_power(it2)), " fx=", ItemDb.weapon_fx(it2))
	# equip semua slot
	for sl in ItemDb.SLOTS:
		for bi in g.bag.duplicate():
			if bi.slot == sl and bi.tier == 360:
				g.lv = 400
				g.equip(bi)
				break
	print("equipped=", g.equipped_list().size(), " def=", int(g.def_value()), " atk=", int(g.atk()), " hp=", g.max_hp(), " evade=", g.evade_chance(), " speed=", g.move_mult(), " crit=", g.crit_chance())
	g.save_game()
	g.equipped = {}
	print("reload=", g.load_game(), " eq=", g.equipped_list().size())
	# 8) pindah ke semua map + spawn monster
	var w = main.world
	for id in range(0, 11):
		w.warp(id)
		g.lv = clampi(Data.MAPS[id].min + 2, 1, 400)
		for i in 30:
			await get_tree().process_frame
		print("map ", id, " ", Data.MAPS[id].name, " monster=", w.monsters.size())
	# 9) bunuh monster di map 1
	g.lv = 5
	w.warp(1)
	for i in 80:
		await get_tree().process_frame
	var killed := 0
	for m in w.monsters.duplicate():
		if is_instance_valid(m):
			m.hit(999999999.0)
			killed += 1
	print("Dibunuh: ", killed, "  lv sekarang=", g.lv, " laima=", g.laima)
	# cast semua skill
	g.lv = 400
	g.mp = 99999.0
	w.warp(10)
	for i in 80:
		await get_tree().process_frame
	w.player.position = Vector3.ZERO
	for i in 6:
		w.player.cast(i)
	await get_tree().create_timer(0.6).timeout
	print("Skill cast OK")
	get_tree().quit()
