extends Node
## Screenshot semua layar UI: godot --path . res://tools/uishots.tscn
func _snap(name: String, frames: int = 10) -> void:
	for i in frames:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/home/claude/shots/%s.png" % name)
	print("snap ", name)

func _ready() -> void:
	var g = get_tree().root.get_node("G")
	g.new_game("Zeraphine", 4, 1000)
	g.in_game = true
	g.lv = 210
	g.laima = 123456789
	g.karu = 12
	for sl in ItemDb.SLOTS:
		g.equipped[sl] = g.make_item(sl, 200, 0, 3)
	g.equipped["weapon"].plus = 12
	g.equipped["armor"].plus = 9
	g.equipped["helm"].plus = 7
	g.equipped["weapon"].soc[0] = "ruby3"
	g.equipped["weapon"].soc[1] = "topaz2"
	g.equipped["ring"] = g.make_item("ring", 100, 0, 2)
	g.equipped["cloak"] = g.make_item("cloak", 320, 0, 4)
	g.equipped["boots"] = {}
	for t in [10, 50, 100, 200, 320, 400]:
		for sl in ["weapon", "helm", "armor", "gloves", "boots", "cloak", "neck", "ring", "belt"]:
			g.bag.append(g.make_item(sl, t))
	for id in ["hp", "mp", "tp", "warp", "safety", "w50", "w100", "capsule", "aeth3", "gem"]:
		g.stacks[id] = 7
	for t in ["ruby", "topaz", "amethyst", "emerald", "sapphire"]:
		g.stacks["g_%s%d" % [t, 1 + randi() % 4]] = 4
	g.hp = g.max_hp() * 0.7
	g.xp = int(Scaling.exp_need(210) * 0.4)
	var main = load("res://main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	main._start("test")
	for i in 40:
		await get_tree().process_frame
	var w = main.world
	w.warp(2)
	for i in 80:
		await get_tree().process_frame
	await _snap("u1_hud", 20)
	var hud: Hud = main.hud
	hud.open_char("equip")
	await _snap("u2_char_equip", 30)
	hud.open_char("status")
	await _snap("u3_char_status", 30)
	hud.close_menu()
	hud.open_char("equip")
	await _snap("u3b", 5)
	hud._popup_item(g.equipped["weapon"])
	await _snap("u4_popup_equipped", 8)
	hud.close_popup()
	hud._popup_item(g.bag[20])
	await _snap("u5_popup_bag", 8)
	hud.close_popup()
	hud.close_menu()
	hud.sock_sel = "ruby3"
	hud.push_menu("Socket Permata", func(): return hud._menu_socket(g.equipped["weapon"]))
	await _snap("u6_socket", 10)
	hud.close_menu()
	hud.forge_msg = "Gagal, turun ke +11"
	hud.push_menu("Tempa", func(): return hud._menu_forge_item(g.equipped["weapon"]))
	await _snap("u7_forge", 10)
	hud.close_menu()
	hud.push_menu("Toko", hud._menu_class_shop)
	await _snap("u8_shop", 10)
	hud.close_menu()
	hud.push_menu("Skill", hud._menu_skill)
	await _snap("u9_skill", 10)
	hud.close_menu()
	hud.push_menu("Menu", hud._menu_pause)
	await _snap("u10_pause", 10)
	hud.close_menu()
	hud.push_menu("Jewel", hud._menu_jewel)
	await _snap("u11_jewel", 10)
	get_tree().quit()
