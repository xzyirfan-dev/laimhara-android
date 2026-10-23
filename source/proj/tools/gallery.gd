extends SceneTree
## Galeri model: godot --path . --script tools/gallery.gd -- <set> <out.png>   set = hero | mon1 | mon2 | mon3 | npc
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var set_name: String = args[0] if args.size() > 0 else "hero"
	var out: String = args[1] if args.size() > 1 else "/home/claude/shots/g.png"
	var g = root.get_node("G")
	g.new_game()
	var scene := Node3D.new()
	root.add_child(scene)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.45, 0.55)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.85)
	var we := WorldEnvironment.new()
	we.environment = env
	scene.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	scene.add_child(sun)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 30)
	floor.mesh = pm
	floor.material_override = Gfx.mat(Color(0.3, 0.3, 0.32))
	scene.add_child(floor)
	var items: Array = []
	if set_name == "hero":
		for t in [1, 10, 50, 100, 200, 320, 400]:
			var hr := Hero.new()
			scene.add_child(hr)
			hr.build(t, t)
			items.append(hr)
	elif set_name == "npc":
		for k in ["forge", "shop_class", "shop_potion", "market", "jewel", "karu", "gate", "quest", "camp"]:
			var d := Models.npc(k, Color(0.6, 0.5, 0.4))
			scene.add_child(d.root)
			items.append(d.root)
	else:
		var names: Array = []
		match set_name:
			"mon1": names = ["Slime Padang", "Tikus Taring", "Belalang Besar", "Goblin Hutan", "Serigala Karnok", "Jamur Beracun", "Elang Petir", "Troll Lembah", "Golem Batu", "Kelelawar Gua"]
			"mon2": names = ["Kalajengking Batu", "Skeleton Dekara", "Kalajengking Pasir", "Mumi Gurun", "Banteng Tanduk", "Ular Magralis", "Ent Rimba", "Harimau Hantu", "Zombie Moriath", "Wraith"]
			"mon3": names = ["Gargoyle", "Wyvern Muda", "Golem Magma", "Iblis Ngarai", "Yeti Ragnok", "Naga Es", "Titan Salju", "Chaos Spawn", "Void Walker", "Dimensi Horor"]
			_: names = ["Raja Slime", "Ratu Spora", "Elang Badai", "Dekara Warden", "Tanduk Putih", "Magralis", "Lich Moriath", "Wyrm Abadi", "Ragnok", "Chaos Emperor"]
		for n in names:
			var d := Models.monster(n, Color(0.5, 0.5, 0.5), 0)
			scene.add_child(d.root)
			items.append(d.root)
	var cnt := items.size()
	var sp := 3.0
	for i in cnt:
		var it: Node3D = items[i]
		var col := i % 5
		var row := i / 5
		if set_name == "hero":
			col = i
			row = 0
		it.position = Vector3((float(col) - (3.0 if set_name == "hero" else 2.0)) * sp, 0, row * -4.0)
		it.rotation.y = 0.4
	var cam := Camera3D.new()
	scene.add_child(cam)
	if set_name == "hero":
		cam.look_at_from_position(Vector3(0, 2.8, 10.5), Vector3(0, 1.0, 0))
		cam.fov = 60
	else:
		cam.look_at_from_position(Vector3(0, 7.5, 8.0), Vector3(0, 0.6, -2.0))
		cam.fov = 62
	for i in 20:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out)
	quit()
