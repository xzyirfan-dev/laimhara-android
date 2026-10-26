extends SceneTree
## Uji alur: godot --path . --script tools/flow.gd -- <prefix>
func _snap(name: String) -> void:
	for i in 12:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/shots/%s.png" % name)

func _initialize() -> void:
	var g = root.get_node("G")
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await _snap("f1_title")
	var t = m.title
	t._show_create()
	await _snap("f2_create_empty")
	t._name_edit.text = "A!"
	t._on_name_changed("A!")
	print("ERR1: ", t._err.text, " go_disabled=", t._go_btn.disabled)
	t._name_edit.text = "12345"
	t._on_name_changed("12345")
	print("ERR2: ", t._err.text)
	t._name_edit.text = "Admin"
	t._on_name_changed("Admin")
	print("ERR3: ", t._err.text)
	t._name_edit.text = "Zeraphine"
	t._on_name_changed("Zeraphine")
	t._pick_hair(4)
	t._pick_rate(2)
	print("OK: err='", t._err.text, "' go_disabled=", t._go_btn.disabled)
	await _snap("f3_create_filled")
	t._go()
	await _snap("f4_intro")
	t._intro_next()
	t._intro_next()
	t._intro_next()
	for i in 30:
		await process_frame
	print("in_game=", g.in_game, " name=", g.player_name, " hair=", g.hair_idx, " exp=", g.settings.exp_mult, " lv=", g.lv)
	await _snap("f5_game")
	m.hud.push_menu("Menu", m.hud._menu_pause)
	await _snap("f6_pause")
	m.hud.push_menu("Keluar Game?", m.hud._menu_quit_confirm)
	await _snap("f7_quit")
	m.hud.close_menu()
	g.save_game()
	print("SAVE_INFO: ", g.save_info())
	g.to_title.emit()
	await _snap("f8_back_title")
	print("TITLE_AGAIN has_save=", g.has_save(), " in_game=", g.in_game, " title=", m.title != null)
	m.title._start("load")
	for i in 30:
		await process_frame
	print("RELOAD name=", g.player_name, " in_game=", g.in_game, " lv=", g.lv, " map=", g.map_id)
	quit()
