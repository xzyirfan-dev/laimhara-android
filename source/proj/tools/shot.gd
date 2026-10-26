extends SceneTree
## Tangkapan layar headless: godot --path . --script tools/shot.gd -- <map_id> <lv> <out.png>
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var map_id := int(args[0]) if args.size() > 0 else 0
	var lv := int(args[1]) if args.size() > 1 else 1
	var out: String = args[2] if args.size() > 2 else "/home/claude/shots/a.png"
	var g = root.get_node("G")
	g.new_game()
	g.lv = lv
	g.map_id = map_id
	g.weapon = g.make_item("weapon", Scaling.tier_for(lv))
	g.armor = g.make_item("armor", Scaling.tier_for(lv))
	g.hp = float(g.max_hp())
	g.mp = float(g.max_mp())
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 90:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	quit()
