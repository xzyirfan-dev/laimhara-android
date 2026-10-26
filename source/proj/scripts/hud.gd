class_name Hud
extends CanvasLayer
## HUD + jendela (Tas/Karakter/Toko/Tempa/Socket) bergaya RPG mobile modern.
## Semua tombol aksi digambar di canvas & ditangani multi-touch di _input.

var world: GameWorld
var root: Control
var canvas: Control
var ui_open := false
var menu_panel: PanelContainer
var menu_title: Label
var content: Control
var back_btn: Button
var menu_stack: Array = []
var toast_box: VBoxContainer
var interact_btn: Button
var near_npc: Node3D = null
var joy_idx := -1
var joy_center := Vector2.ZERO
var joy_pos := Vector2.ZERO
var pad_touch: Dictionary = {}
var cam_touch := -1
var cam_last := Vector2.ZERO
var cam_points: Dictionary = {}
var cam_pinch := -1.0
var forge_w := "none"
var forge_safe := false
var forge_msg := ""
var chat: Array = []
var saved_t := 0.0
var popup_layer: Control
var char_tab := "equip"        # equip | status
var bag_tab := "all"           # all | equip | gem | item
var slot_filter := ""
var sock_sel := ""
var sock_msg := ""
var doll_hero: Hero
var _upg_t := 0.0
var upg_flag := false
const R_JOY := 90.0
const GOLD := Color(0.95, 0.82, 0.45)
const LEFT_SLOTS := ["helm", "armor", "gloves", "belt", "boots"]
const RIGHT_SLOTS := ["weapon", "cloak", "neck", "ring"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiKit.make_theme()
	add_child(root)
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_on_draw)
	root.add_child(canvas)
	toast_box = VBoxContainer.new()
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_box)
	interact_btn = UiKit.btn("", "gold", Vector2(320, 68), 24)
	interact_btn.visible = false
	interact_btn.pressed.connect(_on_interact)
	root.add_child(interact_btn)
	_build_window()
	popup_layer = Control.new()
	popup_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.visible = false
	root.add_child(popup_layer)
	G.toast.connect(_on_toast)
	G.loot.connect(_on_loot)
	G.saved.connect(_on_saved)
	G.back_pressed.connect(_on_back)
	_chat("Selamat datang di Laimhara. Ketuk NPC/Warp Stone saat dekat untuk bicara.", Color(1, 0.9, 0.5))

func _build_window() -> void:
	menu_panel = PanelContainer.new()
	menu_panel.anchor_left = 0.025
	menu_panel.anchor_right = 0.975
	menu_panel.anchor_top = 0.03
	menu_panel.anchor_bottom = 0.97
	menu_panel.visible = false
	root.add_child(menu_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	menu_panel.add_child(vb)
	var tb := PanelContainer.new()
	tb.add_theme_stylebox_override("panel", UiKit.box("title", 14, 6))
	vb.add_child(tb)
	var hb := HBoxContainer.new()
	tb.add_child(hb)
	back_btn = UiKit.btn("", "normal", Vector2(70, 52))
	back_btn.icon = UiKit.icon("g_back")
	back_btn.expand_icon = true
	back_btn.pressed.connect(_on_back)
	hb.add_child(back_btn)
	menu_title = UiKit.lbl("", 32, GOLD, HORIZONTAL_ALIGNMENT_CENTER, true)
	menu_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(menu_title)
	var cb := UiKit.btn("", "red", Vector2(70, 52))
	cb.icon = UiKit.icon("g_close")
	cb.expand_icon = true
	cb.pressed.connect(close_menu)
	hb.add_child(cb)
	content = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.clip_contents = true
	vb.add_child(content)

func _on_loot(t: String) -> void:
	_chat(t)

func _on_saved() -> void:
	saved_t = 2.6

func _exit_tree() -> void:
	for pair in [[G.toast, _on_toast], [G.loot, _on_loot], [G.saved, _on_saved], [G.back_pressed, _on_back]]:
		var s: Signal = pair[0]
		var c: Callable = pair[1]
		if s.is_connected(c):
			s.disconnect(c)

func _on_back() -> void:
	if popup_layer.visible:
		close_popup()
	elif not menu_stack.is_empty():
		pop_menu()
	else:
		push_menu("Menu", _menu_pause)

# ---------- chat + toast ----------
func _chat(msg: String, col: Color = Color(-1, 0, 0)) -> void:
	var c := col
	if col.r < 0.0:
		c = Color(1, 1, 1)
		if msg.begins_with("SET") or msg.begins_with("Warranty") or msg.begins_with("Safety"):
			c = Color(1, 0.8, 0.3)
		elif msg.begins_with("Drop"):
			c = Color(0.6, 1, 0.6)
		elif msg.begins_with("Permata"):
			c = Color(0.8, 0.6, 1)
		elif msg.begins_with("Erfahrung") or msg.begins_with("EXP"):
			c = Color(1, 0.95, 0.5)
	chat.append({"t": msg, "age": 0.0, "c": c})
	while chat.size() > 9:
		chat.pop_front()

func _on_toast(msg: String, big: bool) -> void:
	if not big:
		_chat(msg)
		return
	_chat(msg, Color(1, 0.9, 0.4))
	var l := UiKit.lbl(msg, 46, Color(1, 0.95, 0.5), HORIZONTAL_ALIGNMENT_CENTER, true, 10)
	toast_box.add_child(l)
	while toast_box.get_child_count() > 3:
		var old := toast_box.get_child(0)
		toast_box.remove_child(old)
		old.queue_free()
	var tw := l.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

# ---------- layout pad ----------
func _pads() -> Array:
	var s := canvas.size
	var out: Array = []
	var ac := Vector2(s.x - 118, s.y - 118)
	out.append({"id": "atk", "pos": ac, "r": 68.0, "t": "TEMBAK"})
	var acts := Data.actives()
	var ring_counts := [4, 4, 3]
	var ring_angles := [[186.0, 158.0, 130.0, 102.0], [174.0, 146.0, 118.0, 90.0], [162.0, 132.0, 102.0]]
	var ring_radii := [132.0, 190.0, 248.0]
	var ring := 0
	var in_ring := 0
	for i in acts.size():
		if in_ring >= ring_counts[ring]:
			ring += 1
			in_ring = 0
		var a: float = deg_to_rad(float(ring_angles[ring][in_ring]))
		var rad: float = ring_radii[ring]
		out.append({"id": "s%d" % i, "pos": ac + Vector2(cos(a), -sin(a)) * rad, "r": 36.0, "t": acts[i].short})
		in_ring += 1
	out.append({"id": "auto", "pos": ac + Vector2(58, -140), "r": 32.0, "t": "AUTO"})
	out.append({"id": "hunt", "pos": ac + Vector2(58, -214), "r": 32.0, "t": "HUNT"})
	var cx := s.x * 0.5 - 20.0
	for i in 4:
		out.append({"id": "q%d" % i, "pos": Vector2(cx - 117 + 78 * i, s.y - 44), "r": 34.0, "t": ["hp", "mp", "tp", "warp"][i]})
	var mb := [["m_bag", "Tas", "g_bag"], ["m_char", "Karakter", "g_char"], ["m_skill", "Skill", "g_skill"], ["m_quest", "Misi", "g_quest"], ["m_scroll", "Scroll", "g_scroll"], ["m_menu", "Menu", "g_gear"]]
	for i in mb.size():
		out.append({"id": mb[i][0], "pos": Vector2(s.x - 188 - 74 * i, 46), "r": 32.0, "t": mb[i][1], "ic": mb[i][2]})
	return out

func _pad_at(p: Vector2) -> String:
	for d in _pads():
		if p.distance_to(d.pos) <= d.r + 6.0:
			return d.id
	return ""

func _press_pad(id: String) -> void:
	var pl := world.player
	if id == "atk":
		pl.try_attack()
	elif id.begins_with("s"):
		pl.cast(int(id.substr(1)))
	elif id == "auto":
		G.settings.auto_attack = not G.settings.auto_attack
	elif id == "hunt":
		G.settings.auto_hunt = not G.settings.auto_hunt
		_on_toast("Auto-Hunt " + ("ON" if G.settings.auto_hunt else "OFF"), false)
	elif id == "q0":
		G.use_potion("hp")
	elif id == "q1":
		G.use_potion("mp")
	elif id == "q2":
		if G.stack_count("tp") > 0 and not world.map.town:
			G.take_stack("tp", 1)
			world.warp(0)
		else:
			_on_toast("Town Portal tidak bisa dipakai", false)
	elif id == "q3":
		push_menu("Scroll", _menu_scroll)
	elif id == "m_bag":
		open_char("equip")
	elif id == "m_char":
		open_char("status")
	elif id == "m_skill":
		push_menu("Skill", _menu_skill)
	elif id == "m_quest":
		push_menu("Misi", _menu_quest)
	elif id == "m_scroll":
		push_menu("Scroll", _menu_scroll)
	elif id == "m_menu":
		push_menu("Menu", _menu_pause)

func open_char(tab: String) -> void:
	char_tab = tab
	slot_filter = ""
	bag_tab = "all"
	push_menu("Karakter", _win_char)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_back()
		return
	if ui_open:
		return
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			cam_points[event.index] = p
			if cam_points.size() == 2:
				var cp: Array = cam_points.values()
				cam_pinch = Vector2(cp[0]).distance_to(Vector2(cp[1]))
			var pad := _pad_at(p)
			if pad != "":
				pad_touch[event.index] = pad
				_press_pad(pad)
			elif p.x < canvas.size.x * 0.5 and joy_idx == -1 and p.y > 100:
				joy_idx = event.index
				joy_center = p
				joy_pos = p
			elif p.x >= canvas.size.x * 0.5 and p.y > 120:
				cam_touch = event.index
				cam_last = p
		else:
			cam_points.erase(event.index)
			if cam_points.size() < 2:
				cam_pinch = -1.0
			pad_touch.erase(event.index)
			if event.index == joy_idx:
				joy_idx = -1
				G.joy = Vector2.ZERO
			if event.index == cam_touch:
				cam_touch = -1
	elif event is InputEventScreenDrag:
		cam_points[event.index] = event.position
		if cam_points.size() >= 2:
			var cp: Array = cam_points.values()
			var dist: float = Vector2(cp[0]).distance_to(Vector2(cp[1]))
			if cam_pinch > 0.0:
				world.camera_zoom((cam_pinch - dist) * 0.025)
			cam_pinch = dist
		elif event.index == joy_idx:
			joy_pos = event.position
			G.joy = ((joy_pos - joy_center) / R_JOY).limit_length(1.0)
		elif event.index == cam_touch:
			var delta_cam: Vector2 = event.position - cam_last
			world.camera_orbit(-delta_cam.x * 0.012, -delta_cam.y * 0.008)
			cam_last = event.position
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			world.camera_zoom(-1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			world.camera_zoom(1.0)

# ---------- draw ----------
func _text(pos: Vector2, t: String, size: int, col: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, w: float = -1.0) -> void:
	var f := UiKit.font_b()
	canvas.draw_string_outline(f, pos, t, align, w, size, 6, Color(0, 0, 0, 0.9))
	canvas.draw_string(f, pos, t, align, w, size, col)

func _bar(pos: Vector2, w: float, h: float, f: float, tex: String, txt: String) -> void:
	f = clampf(f, 0.0, 1.0)
	var fr := UiKit.ui("bar_frame")
	canvas.draw_texture_rect(fr, Rect2(pos - Vector2(3, 3), Vector2(w + 6, h + 6)), false)
	if f > 0.005:
		var t := UiKit.ui(tex)
		canvas.draw_texture_rect_region(t, Rect2(pos, Vector2(w * f, h)), Rect2(0, 0, 256.0 * f, 30))
	if txt != "":
		_text(pos + Vector2(-8, h - 5), txt, int(h * 0.72), Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, w)

func _pad_base(c: Vector2, r: float, tex: String, tint: Color = Color.WHITE) -> void:
	var sz := r * 2.35
	canvas.draw_texture_rect(UiKit.ui(tex), Rect2(c - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, tint)

func _icon_at(c: Vector2, sz: float, tex: Texture2D, tint: Color = Color.WHITE) -> void:
	if tex == null:
		canvas.draw_circle(c, sz * 0.36, Color(0.08, 0.16, 0.22, 0.95))
		canvas.draw_arc(c, sz * 0.36, 0.0, TAU, 16, Color(0.2, 0.85, 1.0, 0.9), 3.0)
		return
	canvas.draw_texture_rect(tex, Rect2(c - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, tint)

func _cooldown(c: Vector2, r: float, frac: float) -> void:
	if frac <= 0.0:
		return
	var pts := PackedVector2Array([c])
	var n := 28
	for i in n + 1:
		var a := -PI * 0.5 + TAU * frac * float(i) / float(n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	canvas.draw_colored_polygon(pts, Color(0, 0, 0, 0.6))

func _on_draw() -> void:
	var s := canvas.size
	var pl := world.player
	var mhp := float(G.max_hp())
	var mmp := float(G.max_mp())
	# --- potret + bar (kiri atas) ---
	var pc := Vector2(62, 62)
	canvas.draw_circle(pc, 46, Color(0.07, 0.1, 0.2))
	canvas.draw_circle(pc + Vector2(0, 38), 30, Color(0.25, 0.45, 0.85))
	canvas.draw_circle(pc + Vector2(0, -2), 21, Color(0.96, 0.78, 0.64))
	var hc: Color = Data.HAIR_COLORS[G.hair_idx].c
	canvas.draw_arc(pc + Vector2(0, -6), 20, PI * 1.0, PI * 2.0, 14, hc, 9.0)
	canvas.draw_texture_rect(UiKit.ui("ring_portrait"), Rect2(pc - Vector2(54, 54), Vector2(108, 108)), false)
	canvas.draw_circle(pc + Vector2(36, 36), 19, Color(0.08, 0.06, 0.04))
	canvas.draw_arc(pc + Vector2(36, 36), 19, 0, TAU, 24, GOLD, 3.0)
	_text(pc + Vector2(18, 43), str(G.lv), 19, Color(1, 0.95, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 36.0)
	_bar(Vector2(124, 16), 300, 24, G.hp / mhp, "bar_hp", "%s / %s" % [Scaling.fmt(int(G.hp)), Scaling.fmt(int(mhp))])
	_bar(Vector2(124, 46), 300, 20, G.mp / mmp, "bar_mp", "%s" % Scaling.fmt(int(G.mp)))
	var need := Scaling.exp_need(mini(G.lv, 399))
	var ef := float(G.xp) / float(need)
	_bar(Vector2(124, 73), 300, 9, ef, "bar_xp", "")
	_text(Vector2(124, 106), "%s  Lv.%d  EXP %.1f%%%s" % [G.player_name, G.lv, ef * 100.0, "  [x2]" if G.capsule_t > 0.0 else ""], 19, Color(0.9, 0.95, 1))
	# mata uang
	UiKit.box("pill", 12, 4).draw(canvas.get_canvas_item(), Rect2(10, 122, 200, 32))
	_icon_at(Vector2(28, 138), 26, UiKit.icon("laima"))
	_text(Vector2(46, 146), Scaling.fmt(G.laima), 19, Color(1, 0.95, 0.6))
	UiKit.box("pill", 12, 4).draw(canvas.get_canvas_item(), Rect2(216, 122, 120, 32))
	_icon_at(Vector2(234, 138), 26, UiKit.icon("karu"))
	_text(Vector2(252, 146), str(G.karu), 19, Color(0.95, 0.7, 1))
	if G.shield_t > 0.0:
		_icon_at(Vector2(30, 180), 34, UiKit.icon("sk_shield"))
		_text(Vector2(52, 188), "%.0fs" % G.shield_t, 19, Color(0.5, 0.8, 1))
	# --- tracker misi ---
	var qy := 206.0 if G.shield_t > 0.0 else 170.0
	UiKit.box("panel_hud", 18, 8).draw(canvas.get_canvas_item(), Rect2(10, qy, 290, 64))
	_icon_at(Vector2(38, qy + 32), 34, UiKit.icon("g_quest"))
	_text(Vector2(64, qy + 26), "Misi Harian", 17, GOLD)
	var hunt_progress: int = mini(G.daily_value("kills"), 20)
	_text(Vector2(64, qy + 50), "Bunuh monster  %d / 20  (otomatis)" % hunt_progress, 17, Color(0.9, 0.95, 1) if hunt_progress < 20 else Color(0.5, 1, 0.6))
	# --- bar target (tengah atas) ---
	var tg := pl.nearest(14.0)
	if tg != null:
		var tx := s.x * 0.5 - 150.0
		_bar(Vector2(tx - 40, 84), 260, 14, tg.hp / tg.max_hp, "bar_tg", "")
		_text(Vector2(tx - 40, 124), "Lv%d %s" % [tg.lv, tg.mname], 22, Color(1, 0.95, 0.3), HORIZONTAL_ALIGNMENT_CENTER, 260.0)
	# --- minimap (kanan atas) ---
	var mc := Vector2(s.x - 88, 92)
	var mr := 72.0
	canvas.draw_circle(mc, mr, Color(0.08, 0.11, 0.18, 0.88))
	var pp := pl.position
	for n in get_tree().get_nodes_in_group("npc"):
		var d := Vector2(n.position.x - pp.x, n.position.z - pp.z) / 32.0 * mr
		if d.length() < mr - 6.0:
			canvas.draw_circle(mc + d, 4.5, Color(0.3, 0.9, 1.0))
	for m in world.monsters:
		if is_instance_valid(m) and not m.dead:
			var d := Vector2(m.position.x - pp.x, m.position.z - pp.z) / 32.0 * mr
			if d.length() < mr - 6.0:
				canvas.draw_circle(mc + d, 3.5 if m.kind == 0 else 5.5, Color(1, 0.2, 0.15) if m.kind < 2 else Color(1, 0.8, 0.1))
	canvas.draw_circle(mc, 5, Color(0.2, 1, 0.3))
	canvas.draw_texture_rect(UiKit.ui("ring_map"), Rect2(mc - Vector2(mr + 12, mr + 12), Vector2(mr + 12, mr + 12) * 2.0), false)
	var half := pl.half + 2.0
	_text(Vector2(mc.x - mr, mc.y + mr + 28), "%d, %d" % [int(pp.x + half), int(pp.z + half)], 20, Color(1, 0.85, 0.4), HORIZONTAL_ALIGNMENT_CENTER, mr * 2.0)
	_text(Vector2(mc.x - 220, mc.y + mr + 52), world.map.name, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 300.0)
	# --- chat log (kiri bawah) ---
	var cy := s.y - 262.0
	var shown := 0
	for i in range(chat.size() - 1, -1, -1):
		var e: Dictionary = chat[i]
		var a := clampf((14.0 - float(e.age)) / 4.0, 0.0, 1.0)
		if a <= 0.0:
			continue
		var col: Color = e.c
		col.a = a
		_text(Vector2(16, cy - shown * 24.0), e.t, 19, col)
		shown += 1
	if saved_t > 0.0:
		_text(Vector2(s.x * 0.5 - 150, 100), "Tersimpan otomatis", 20, Color(0.6, 1.0, 0.7, clampf(saved_t, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, 300.0)
	# --- joystick ---
	var jc := joy_center if joy_idx != -1 else Vector2(170, s.y - 140)
	canvas.draw_texture_rect(UiKit.ui("joy_base"), Rect2(jc - Vector2(R_JOY, R_JOY) * 1.3, Vector2(R_JOY, R_JOY) * 2.6), false, Color(1, 1, 1, 0.75))
	var kp := jc + (G.joy * R_JOY if joy_idx != -1 else Vector2.ZERO)
	canvas.draw_texture_rect(UiKit.ui("joy_knob"), Rect2(kp - Vector2(48, 48), Vector2(96, 96)), false, Color(1, 1, 1, 0.9))
	# --- pad aksi ---
	var acts := Data.actives()
	for d in _pads():
		var id: String = d.id
		var c: Vector2 = d.pos
		var r: float = d.r
		if id == "atk":
			_pad_base(c, r, "pad_atk")
			if not G.weapon.is_empty():
				_icon_at(c + Vector2(0, -4), r * 1.25, UiKit.item_icon(G.weapon))
			else:
				_icon_at(c, r * 1.0, UiKit.icon("sk_marks"))
		elif id.begins_with("s"):
			var i := int(id.substr(1))
			var a: Dictionary = acts[i]
			var locked: bool = G.lv < a.unlock
			var cd: float = float(pl.cds.get(a.id, 0.0))
			_pad_base(c, r, "pad_skill" if cd > 0.0 or locked else "pad_skill_on")
			_icon_at(c, r * 1.35, UiKit.icon("sk_" + String(a.id)), Color(0.45, 0.45, 0.5) if locked else Color.WHITE)
			if cd > 0.0:
				_cooldown(c, r * 0.95, clampf(cd / float(a.cd), 0.0, 1.0))
				_text(c + Vector2(-r, 8), "%.0f" % cd, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0)
			elif locked:
				_text(c + Vector2(-r, 8), "Lv%d" % a.unlock, 17, Color(1, 0.8, 0.5), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0)
			else:
				_text(c + Vector2(-r, r + 2.0), "L%d" % G.skill_lv(a.id), 15, Color(1, 0.95, 0.6), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0)
		elif id == "auto" or id == "hunt":
			var on: bool = G.settings.auto_attack if id == "auto" else G.settings.auto_hunt
			if on:
				canvas.draw_texture_rect(UiKit.ui("soft"), Rect2(c - Vector2(r, r) * 1.6, Vector2(r, r) * 3.2), false, Color(0.3, 1, 0.5, 0.6))
			_pad_base(c, r, "pad_menu", Color(1, 1, 1) if on else Color(0.7, 0.72, 0.8))
			_icon_at(c, r * 1.15, UiKit.icon("g_auto" if id == "auto" else "g_hunt"))
			_text(c + Vector2(-r, r + 14.0), d.t, 14, Color(0.6, 1, 0.7) if on else Color(0.8, 0.8, 0.85), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0)
		elif id.begins_with("q"):
			_pad_base(c, r, "pad_quick")
			var sid: String = d.t
			_icon_at(c, r * 1.3, UiKit.icon(sid))
			_text(c + Vector2(-r, r - 2.0), str(G.stack_count(sid)), 17, Color(1, 0.95, 0.6), HORIZONTAL_ALIGNMENT_RIGHT, r * 2.0 - 4.0)
		elif id.begins_with("m_"):
			_pad_base(c, r, "pad_menu")
			_icon_at(c, r * 1.15, UiKit.icon(d.ic))
			_text(c + Vector2(-40, r + 17.0), d.t, 14, Color(0.88, 0.92, 1), HORIZONTAL_ALIGNMENT_CENTER, 80.0)
			if id == "m_bag" and upg_flag:
				canvas.draw_circle(c + Vector2(22, -22), 9, Color(1, 0.25, 0.2))
				_text(c + Vector2(17, -16), "!", 15, Color.WHITE)

func _process(delta: float) -> void:
	saved_t = maxf(0.0, saved_t - delta)
	for e in chat:
		e.age = float(e.age) + delta
	canvas.queue_redraw()
	var s := canvas.size
	toast_box.position = Vector2(s.x * 0.5 - 300, 160)
	toast_box.size = Vector2(600, 10)
	_upg_t -= delta
	if _upg_t <= 0.0:
		_upg_t = 1.0
		upg_flag = false
		for it in G.bag:
			if G.lv >= int(it.tier) and G.is_upgrade(it):
				upg_flag = true
				break
	if doll_hero != null and is_instance_valid(doll_hero):
		doll_hero.rotation.y += delta * 0.6
		doll_hero.animate(delta, false, false)
	near_npc = null
	if not ui_open and world.player != null:
		var bd := 4.5
		for n in get_tree().get_nodes_in_group("npc"):
			var d := world.player.position.distance_to(n.position)
			if d < bd:
				bd = d
				near_npc = n
	interact_btn.visible = near_npc != null and not ui_open
	if near_npc != null:
		interact_btn.text = "Bicara: " + str(near_npc.get_meta("title"))
		interact_btn.position = Vector2(s.x * 0.5 - 160, s.y - 178)

func _on_interact() -> void:
	if near_npc == null:
		return
	var kind: String = near_npc.get_meta("kind")
	var title: String = near_npc.get_meta("title")
	match kind:
		"forge": push_menu(title, _menu_forge_list)
		"shop_class": push_menu(title, _menu_class_shop)
		"shop_potion": push_menu(title, _menu_potion.bind(1.0))
		"camp": push_menu(title + " (harga +50%)", _menu_potion.bind(1.5))
		"market": push_menu(title, _menu_market)
		"jewel": push_menu(title, _menu_jewel)
		"karu": push_menu(title, _menu_karu)
		"gate": push_menu(title, _menu_warp)
		"dungeon": push_menu(title, _menu_dungeon)
		"dungeon_exit": push_menu(title, _menu_dungeon_exit)
		"quest": push_menu(title, _menu_quest)

# ---------- menu engine ----------
func push_menu(title: String, builder: Callable) -> void:
	menu_stack.append({"t": title, "b": builder})
	_show_menu()

func refresh() -> void:
	_show_menu()

func pop_menu() -> void:
	if not menu_stack.is_empty():
		menu_stack.pop_back()
	_show_menu()

func close_menu() -> void:
	close_popup()
	menu_stack.clear()
	menu_panel.visible = false
	ui_open = false
	doll_hero = null
	get_tree().paused = false

func _show_menu() -> void:
	if menu_stack.is_empty():
		close_menu()
		return
	var top: Dictionary = menu_stack.back()
	menu_title.text = top.t
	back_btn.visible = menu_stack.size() > 1
	var keep := 0
	var old_sc := content.find_child("KeepScroll", true, false)
	if old_sc != null:
		keep = (old_sc as ScrollContainer).scroll_vertical
	doll_hero = null
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	var res = top.b.call()
	var node: Control
	if res is Control:
		node = res
	else:
		node = _rows_view(res)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(node)
	menu_panel.visible = true
	ui_open = true
	G.joy = Vector2.ZERO
	joy_idx = -1
	get_tree().paused = true
	if keep > 0:
		var sc := content.find_child("KeepScroll", true, false)
		if sc != null:
			(sc as ScrollContainer).set_deferred("scroll_vertical", keep)

func _msg(t: String) -> void:
	forge_msg = t
	_on_toast(t, false)
	refresh()

# ---------- popup ----------
func close_popup() -> void:
	popup_layer.visible = false
	for c in popup_layer.get_children():
		popup_layer.remove_child(c)
		c.queue_free()

## content: Control; buttons: [{t, f, kind, d}]
func show_popup(body: Control, buttons: Array, width: float = 540.0) -> void:
	close_popup()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			close_popup())
	popup_layer.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_layer.add_child(cc)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiKit.box("panel_tip", 28, 18))
	pc.custom_minimum_size = Vector2(width, 0)
	cc.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pc.add_child(vb)
	vb.add_child(body)
	var hb := HFlowContainer.new()
	hb.add_theme_constant_override("h_separation", 8)
	hb.add_theme_constant_override("v_separation", 8)
	hb.alignment = FlowContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	for b in buttons:
		var bb := UiKit.btn(b.t, b.get("kind", "normal"), Vector2(150, 58), 21)
		bb.disabled = b.get("d", false)
		var f: Callable = b.f
		bb.pressed.connect(func():
			close_popup()
			f.call())
		hb.add_child(bb)
	var xb := UiKit.btn("Tutup", "normal", Vector2(120, 58), 21)
	xb.pressed.connect(close_popup)
	hb.add_child(xb)
	popup_layer.visible = true

# ---------- baris generik ----------
func _rows_view(rows: Array) -> Control:
	var sc := ScrollContainer.new()
	sc.name = "KeepScroll"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var m := MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_theme_constant_override("margin_left", 6)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 4)
	m.add_theme_constant_override("margin_bottom", 8)
	sc.add_child(m)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(vb)
	for r in rows:
		vb.add_child(_row_node(r))
	return sc

func _icon_of(v) -> Texture2D:
	if v is Texture2D:
		return v
	if v == null:
		return UiKit.icon("g_skill")
	return UiKit.stack_icon(String(v))

func _row_node(r: Dictionary) -> Control:
	if r.has("label"):
		var l := UiKit.lbl(String(r.label), 22, UiKit.TXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return l
	if r.has("rich"):
		var rt := UiKit.rich(String(r.rich), 22)
		rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return rt
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiKit.box("inset", 14, 8))
	pc.custom_minimum_size = Vector2(0, 80)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(hb)
	if r.has("ic"):
		var ic := UiKit.tr_rect(_icon_of(r.ic), Vector2(64, 64))
		hb.add_child(ic)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vb)
	var disabled: bool = r.get("d", false)
	var tcol: Color = r.get("col", GOLD if not disabled else UiKit.TXT_DIM)
	var tl := UiKit.lbl(String(r.t), 24, tcol, HORIZONTAL_ALIGNMENT_LEFT, true)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(tl)
	if r.has("s"):
		var sl := UiKit.lbl(String(r.s), 18, UiKit.TXT_DIM)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(sl)
	if r.has("bar"):
		var bg := ColorRect.new()
		bg.color = Color(0, 0, 0, 0.6)
		bg.custom_minimum_size = Vector2(0, 10)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fg := ColorRect.new()
		fg.color = Color(0.4, 0.8, 1.0)
		fg.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		fg.anchor_right = clampf(float(r.bar), 0.0, 1.0)
		fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(fg)
		vb.add_child(bg)
	if r.has("rt"):
		var rl := UiKit.lbl(String(r.rt), 22, Color(1, 0.95, 0.6), HORIZONTAL_ALIGNMENT_RIGHT, true)
		hb.add_child(rl)
	if r.has("f"):
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = disabled
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", UiKit.flat(Color(1, 1, 1, 0.05), 8))
		b.add_theme_stylebox_override("pressed", UiKit.flat(Color(1, 0.9, 0.5, 0.18), 8))
		var f: Callable = r.f
		b.pressed.connect(f)
		pc.add_child(b)
	if disabled:
		pc.modulate = Color(1, 1, 1, 0.6)
	return pc

# ---------- grid item generik ----------
func _grid(cells: Array, cols: int = 5, cell: float = 84.0, min_cells: int = 0) -> Control:
	var sc := ScrollContainer.new()
	sc.name = "KeepScroll"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var gc := GridContainer.new()
	gc.columns = cols
	gc.add_theme_constant_override("h_separation", 6)
	gc.add_theme_constant_override("v_separation", 6)
	sc.add_child(gc)
	for c in cells:
		gc.add_child(c)
	var n: int = cells.size()
	var total := maxi(min_cells, int(ceil(float(n) / float(cols))) * cols)
	total = int(ceil(float(total) / float(cols))) * cols
	for i in range(n, total):
		gc.add_child(ItemSlot.new(cell))
	return sc

func _slot_for_item(it: Dictionary, cell: float = 84.0) -> ItemSlot:
	var sl := ItemSlot.new(cell)
	sl.item = it
	sl.equipped_mark = G.is_equipped(it)
	if G.lv < int(it.tier):
		sl.tag = "Lv%d" % int(it.tier)
	return sl

# ---------- jendela Karakter (paper-doll + tas) ----------
func _win_char() -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.add_child(_char_left())
	hb.add_child(_bag_right())
	return hb

func _tab_btn(text: String, on: bool, f: Callable, w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(w, 46)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var n := "tab_on" if on else "tab"
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, UiKit.box(n, 14, 6))
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", GOLD if on else UiKit.TXT_DIM)
	b.add_theme_color_override("font_hover_color", GOLD if on else UiKit.TXT)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.pressed.connect(f)
	return b

func _char_left() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiKit.box("panel_dark", 24, 10))
	pc.custom_minimum_size = Vector2(620, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pc.add_child(vb)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	tabs.add_child(_tab_btn("Perlengkapan", char_tab == "equip", func():
		char_tab = "equip"
		refresh()))
	tabs.add_child(_tab_btn("Status", char_tab == "status", func():
		char_tab = "status"
		refresh()))
	vb.add_child(tabs)
	if char_tab == "equip":
		vb.add_child(_paper_doll())
	else:
		vb.add_child(_status_view())
	return pc

func _equip_cell(sl: String) -> ItemSlot:
	var it: Dictionary = G.equipped.get(sl, {})
	var c := ItemSlot.new(80.0)
	c.ghost = sl
	c.item = it
	c.equipped_mark = false
	c.selected = slot_filter == sl
	if it.is_empty():
		c.tag = ""
	c.tapped.connect(func(_s):
		if it.is_empty():
			slot_filter = sl
			bag_tab = "equip"
			_on_toast("Slot %s kosong - pilih item di tas" % ItemDb.SLOT_LABEL[sl], false)
			refresh()
		else:
			_popup_item(it))
	return c

func _paper_doll() -> Control:
	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 6)
	var lv := VBoxContainer.new()
	lv.alignment = BoxContainer.ALIGNMENT_CENTER
	lv.add_theme_constant_override("separation", 6)
	for sl in LEFT_SLOTS:
		lv.add_child(_equip_cell(sl))
	hb.add_child(lv)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(UiKit.lbl("%s   Lv.%d" % [G.player_name, G.lv], 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER, true))
	var doll := _make_doll(Vector2(300, 300))
	doll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	doll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(doll)
	var sc := G.set_count()
	var st := "ATK %s   DEF %s" % [Scaling.fmt(int(G.atk())), Scaling.fmt(int(G.def_value()))]
	mid.add_child(UiKit.lbl(st, 22, UiKit.TXT, HORIZONTAL_ALIGNMENT_CENTER, true))
	mid.add_child(UiKit.lbl(("Set aktif %d/9  (x%.2f)" % [sc, G.set_mult()]) if sc >= 2 else "HP %s   MP %s" % [Scaling.fmt(G.max_hp()), Scaling.fmt(G.max_mp())], 18, UiKit.TXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	hb.add_child(mid)
	var rv := VBoxContainer.new()
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_theme_constant_override("separation", 6)
	for sl in RIGHT_SLOTS:
		rv.add_child(_equip_cell(sl))
	var fx := G.equipped_list().size()
	var info := UiKit.lbl("%d/9\nterpasang" % fx, 17, UiKit.TXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	info.custom_minimum_size = Vector2(80, 60)
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rv.add_child(info)
	hb.add_child(rv)
	return hb

func _make_doll(size: Vector2) -> Control:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = size
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.transparent_bg = true
	sv.size = Vector2i(int(size.x), int(size.y))
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(sv)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.68, 0.85)
	env.ambient_light_energy = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	sv.add_child(we)
	var cam := Camera3D.new()
	cam.fov = 34.0
	cam.position = Vector3(0, 1.25, 5.6)
	cam.rotation_degrees = Vector3(-3, 0, 0)
	sv.add_child(cam)
	var li := DirectionalLight3D.new()
	li.rotation_degrees = Vector3(-35, 35, 0)
	li.light_energy = 1.3
	sv.add_child(li)
	var li2 := DirectionalLight3D.new()
	li2.rotation_degrees = Vector3(-20, -140, 0)
	li2.light_energy = 0.5
	li2.light_color = Color(0.5, 0.7, 1.0)
	sv.add_child(li2)
	# panggung
	var stage := Node3D.new()
	sv.add_child(stage)
	var pal := Gfx.palette(int(G.armor.get("tier", 1)))
	Gfx.cyl(stage, 0.95, 1.05, 0.08, Vector3(0, -0.06, 0), Color(0.12, 0.14, 0.2), false, 28, 0.5, 0.4)
	Gfx.ring(stage, 0.8, 0.93, Vector3(0, 0.0, 0), pal.glow)
	var hero := Hero.new()
	hero.portrait_mode = true
	hero.hair_col = Data.HAIR_COLORS[G.hair_idx].c
	hero.rotation.y = -0.5
	sv.add_child(hero)
	hero.build_eq(G.equipped)
	doll_hero = hero
	return svc

func _stat_line(name: String, val: String, col: Color = UiKit.TXT) -> Control:
	var hb := HBoxContainer.new()
	var a := UiKit.lbl(name, 21, UiKit.TXT_DIM)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(a)
	hb.add_child(UiKit.lbl(val, 22, col, HORIZONTAL_ALIGNMENT_RIGHT, true))
	return hb

func _status_view() -> Control:
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 14)
	sc.add_child(hb)
	var doll := _make_doll(Vector2(250, 420))
	hb.add_child(doll)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 5)
	hb.add_child(vb)
	vb.add_child(UiKit.lbl("%s" % G.player_name, 30, GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
	vb.add_child(UiKit.lbl("Human - Penembak   Lv %d / 400" % G.lv, 19, UiKit.TXT_DIM))
	vb.add_child(UiKit.hdiv())
	vb.add_child(_stat_line("HP", Scaling.fmt(G.max_hp()), Color(1, 0.5, 0.5)))
	vb.add_child(_stat_line("MP", Scaling.fmt(G.max_mp()), Color(1, 0.9, 0.4)))
	vb.add_child(_stat_line("ATK", Scaling.fmt(int(G.atk())), Color(1, 0.75, 0.4)))
	vb.add_child(_stat_line("DEF", Scaling.fmt(int(G.def_value())), Color(0.6, 0.85, 1)))
	vb.add_child(_stat_line("Critical", "%.1f%%" % (G.crit_chance() * 100.0)))
	vb.add_child(_stat_line("Fatal Hit", "%.1f%%" % minf(50.0, G.bonus("fatal"))))
	vb.add_child(_stat_line("Evasi", "%.1f%%" % (G.evade_chance() * 100.0)))
	vb.add_child(_stat_line("Kecepatan gerak", "+%.0f%%" % (G.move_mult() * 100.0 - 100.0)))
	vb.add_child(_stat_line("Jangkauan", "%.0f m" % world.player.attack_range()))
	vb.add_child(_stat_line("STR / VIT", "%d / %d" % [G.str_val(), G.vit_val()]))
	vb.add_child(_stat_line("Bonus SET", ("x%.2f (%d/9)" % [G.set_mult(), G.set_count()]) if G.set_count() >= 2 else "tidak aktif", UiKit.GOOD if G.set_count() >= 2 else UiKit.TXT_DIM))
	vb.add_child(UiKit.hdiv())
	var gem_n := 0
	for it in G.equipped_list():
		for g in it.soc:
			if String(g) != "":
				gem_n += 1
	vb.add_child(_stat_line("Permata terpasang", str(gem_n), Color(0.85, 0.6, 1)))
	vb.add_child(_stat_line("Bonus dmg / HP / DEF", "+%.0f%% / +%.0f%% / +%.0f%%" % [G.bonus("dmg"), G.bonus("hp"), G.bonus("def")], UiKit.CYAN))
	return sc

# ---- kolom kanan: tas ----
func _filtered_bag() -> Array:
	var out: Array = []
	for it in G.bag:
		if slot_filter != "" and it.slot != slot_filter:
			continue
		out.append(it)
	out.sort_custom(func(a, b):
		var ia: int = ItemDb.SLOTS.find(a.slot)
		var ib: int = ItemDb.SLOTS.find(b.slot)
		if ia != ib:
			return ia < ib
		return G.item_score(a) > G.item_score(b))
	return out

func _bag_right() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiKit.box("panel_dark", 24, 10))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pc.add_child(vb)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	for e in [["all", "Semua"], ["equip", "Gear"], ["gem", "Permata"], ["item", "Item"]]:
		var key: String = e[0]
		tabs.add_child(_tab_btn(e[1], bag_tab == key, func():
			bag_tab = key
			if key != "equip":
				slot_filter = ""
			refresh()))
	vb.add_child(tabs)
	if slot_filter != "":
		var fb := UiKit.btn("Filter: %s  (ketuk untuk hapus)" % ItemDb.SLOT_LABEL[slot_filter], "normal", Vector2(0, 40), 18)
		fb.pressed.connect(func():
			slot_filter = ""
			refresh())
		vb.add_child(fb)
	var cells: Array = []
	if bag_tab == "all" or bag_tab == "equip":
		for it in _filtered_bag():
			var sl := _slot_for_item(it)
			sl.tapped.connect(func(_s): _popup_item(it))
			cells.append(sl)
	if bag_tab == "all" or bag_tab == "gem" or bag_tab == "item":
		var ids: Array = G.stacks.keys()
		ids.sort()
		for id in ids:
			var n: int = G.stack_count(id)
			if n <= 0:
				continue
			var is_gem: bool = String(id).begins_with("g_")
			if (bag_tab == "gem" and not is_gem) or (bag_tab == "item" and is_gem):
				continue
			var sl := ItemSlot.new(84.0)
			sl.set_stack(id, n)
			var sid: String = id
			sl.tapped.connect(func(_s): _popup_stack(sid))
			cells.append(sl)
	var grid := _grid(cells, 5, 84.0, 25)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)
	# footer
	var fh := HBoxContainer.new()
	fh.add_theme_constant_override("separation", 8)
	fh.add_child(UiKit.tr_rect(UiKit.icon("laima"), Vector2(30, 30)))
	fh.add_child(UiKit.lbl(Scaling.fmt(G.laima), 20, Color(1, 0.95, 0.6), HORIZONTAL_ALIGNMENT_LEFT, true))
	fh.add_child(UiKit.tr_rect(UiKit.icon("karu"), Vector2(30, 30)))
	fh.add_child(UiKit.lbl(str(G.karu), 20, Color(0.95, 0.7, 1), HORIZONTAL_ALIGNMENT_LEFT, true))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fh.add_child(sp)
	fh.add_child(UiKit.lbl("Tas %d/%d" % [G.bag.size(), G.BAG_MAX], 18, UiKit.TXT_DIM))
	vb.add_child(fh)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 8)
	var junk := _junk_items()
	var b1 := UiKit.btn("Jual Sampah (%d)" % junk.size(), "red", Vector2(0, 52), 20)
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b1.disabled = junk.is_empty()
	b1.pressed.connect(func():
		var tot := 0
		for it in junk:
			tot += G.sell_value(it)
			G.bag.erase(it)
		G.laima += tot
		_on_toast("Terjual %d item = %s Laima" % [junk.size(), Scaling.fmt(tot)], false)
		refresh())
	bh.add_child(b1)
	var b2 := UiKit.btn("Auto-Equip", "gold", Vector2(0, 52), 20)
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b2.pressed.connect(func():
		var n := _auto_equip()
		_on_toast("%d item dipasang otomatis" % n if n > 0 else "Tidak ada upgrade", false)
		refresh())
	bh.add_child(b2)
	vb.add_child(bh)
	return pc

func _junk_items() -> Array:
	var out: Array = []
	for it in G.bag:
		if G.sell_filter_allowed(it):
			out.append(it)
	return out

func _auto_equip() -> int:
	var n := 0
	for sl in ItemDb.SLOTS:
		var best: Dictionary = {}
		for it in G.bag:
			if it.slot == sl and G.lv >= int(it.tier) and G.is_upgrade(it):
				if best.is_empty() or G.item_score(it) > G.item_score(best):
					best = it
		if not best.is_empty():
			G.equip(best)
			n += 1
	return n

# ---------- popup item / stack ----------
func _popup_item(it: Dictionary) -> void:
	var cur: Dictionary = G.equipped.get(String(it.slot), {})
	var body := ItemCard.build_item(it, cur if not G.is_equipped(it) else {})
	var btns: Array = []
	if G.is_equipped(it):
		btns.append({"t": "Lepas", "kind": "normal", "f": func():
			if not G.unequip(it.slot):
				_on_toast("Tas penuh", false)
			refresh()})
	else:
		btns.append({"t": "Pasang", "kind": "gold", "d": G.lv < int(it.tier), "f": func():
			G.equip(it)
			refresh()})
	btns.append({"t": "Socket", "kind": "green", "f": func():
		sock_sel = ""
		sock_msg = ""
		push_menu("Socket Permata", func(): return _menu_socket(it))})
	btns.append({"t": "Tempa", "kind": "normal", "f": func():
		forge_w = "none"
		forge_safe = false
		forge_msg = ""
		push_menu("Tempa", func(): return _menu_forge_item(it))})
	if not G.is_equipped(it):
		btns.append({"t": "Jual %s" % Scaling.fmt(G.sell_value(it)), "kind": "red", "f": func():
			G.laima += G.sell_value(it)
			G.sold.append({"item": it, "price": G.sell_value(it)})
			if G.sold.size() > 10:
				G.sold.pop_front()
			G.bag.erase(it)
			refresh()})
	show_popup(body, btns)

func _popup_stack(id: String) -> void:
	var n := G.stack_count(id)
	var body := ItemCard.build_stack(id, n)
	var btns: Array = []
	if id == "hp" or id == "mp":
		btns.append({"t": "Pakai", "kind": "gold", "f": func():
			if not G.use_potion(id):
				_on_toast("Tidak bisa dipakai sekarang", false)
			refresh()})
	elif id == "tp":
		btns.append({"t": "Pakai", "kind": "gold", "d": world.map.town, "f": func():
			if G.take_stack("tp", 1):
				close_menu()
				world.warp(0)})
	elif id == "warp":
		btns.append({"t": "Pilih Map", "kind": "gold", "f": func(): push_menu("Warp (pakai 1 Warp Scroll)", _menu_warp_scroll)})
	elif id == "capsule":
		btns.append({"t": "Pakai", "kind": "gold", "f": func():
			if G.take_stack("capsule", 1):
				G.capsule_t = 1800.0
			refresh()})
	elif id.begins_with("g_"):
		var gid := id.substr(2)
		var p := ItemDb.gem_parse(gid)
		btns.append({"t": "Gabung 3→1", "kind": "gold", "d": n < 3 or int(p.grade) >= 5, "f": func(): _msg(G.combine_gem(gid))})
	show_popup(body, btns)

# ---------- socket ----------
func _menu_socket(it: Dictionary) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiKit.box("panel_dark", 24, 12))
	left.custom_minimum_size = Vector2(430, 0)
	left.add_child(ItemCard.build_item(it, {}, 84.0))
	hb.add_child(left)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	hb.add_child(vb)
	var hint := UiKit.lbl("Pilih permata di bawah, lalu ketuk socket untuk memasang. Ketuk socket terisi (tanpa pilihan) untuk melepas - permata hancur.", 18, UiKit.TXT_DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(hint)
	var sr := HBoxContainer.new()
	sr.add_theme_constant_override("separation", 12)
	for i in it.soc.size():
		var idx: int = i
		var c := ItemSlot.new(90.0)
		c.gem_id = String(it.soc[i])
		c.tag = "#%d" % (i + 1)
		c.tapped.connect(func(_s):
			if sock_sel != "":
				sock_msg = G.socket_gem(it, idx, sock_sel)
				if G.gem_stack(sock_sel) < 1:
					sock_sel = ""
			elif String(it.soc[idx]) != "":
				sock_msg = G.unsocket_gem(it, idx)
			else:
				sock_msg = "Pilih permata dulu"
			refresh())
		sr.add_child(c)
	vb.add_child(sr)
	if sock_msg != "":
		vb.add_child(UiKit.lbl(">> " + sock_msg, 20, UiKit.GOOD))
	if sock_sel != "":
		var p := ItemDb.gem_parse(sock_sel)
		var sl := UiKit.lbl("Dipilih: %s (%s)\nBiaya pasang %s Laima" % [ItemDb.gem_name(sock_sel), ItemDb.gem_text(sock_sel), Scaling.fmt(G.socket_cost(it, int(p.grade)))], 19, Color(1, 0.9, 0.5))
		vb.add_child(sl)
	var cells: Array = []
	var ids: Array = G.stacks.keys()
	ids.sort()
	for id in ids:
		if String(id).begins_with("g_") and G.stack_count(id) > 0:
			var sl := ItemSlot.new(84.0)
			sl.set_stack(id, G.stack_count(id))
			var gid: String = String(id).substr(2)
			sl.selected = sock_sel == gid
			sl.tapped.connect(func(_s):
				sock_sel = gid
				refresh())
			cells.append(sl)
	if cells.is_empty():
		vb.add_child(UiKit.lbl("Belum punya permata. Dapatkan dari drop monster atau beli di Tukang Permata.", 20, UiKit.BAD))
	var grid := _grid(cells, 5, 84.0, 10)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_child(hb)
	return m

# ---------- tempa ----------
func _pick_grid(items: Array, on_pick: Callable, hint: String) -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.add_child(UiKit.lbl(hint, 20, UiKit.TXT_DIM))
	var cells: Array = []
	for it in items:
		var sl := _slot_for_item(it)
		sl.tapped.connect(func(_s): on_pick.call(it))
		cells.append(sl)
	var grid := _grid(cells, 5, 84.0, 15)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_child(vb)
	return m

func _menu_forge_list() -> Control:
	return _pick_grid(G.all_items(), func(it):
		forge_w = "none"
		forge_safe = false
		forge_msg = ""
		push_menu("Tempa", func(): return _menu_forge_item(it)), "Pilih item untuk ditempa (+0 s/d +15). Makin tinggi +, makin kuat dan efek visual makin menyala.")

func _menu_forge_item(it: Dictionary) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiKit.box("panel_dark", 24, 12))
	left.custom_minimum_size = Vector2(430, 0)
	left.add_child(ItemCard.build_item(it, {}, 92.0))
	hb.add_child(left)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	hb.add_child(vb)
	if forge_msg != "":
		var ml := UiKit.lbl(">> " + forge_msg, 22, Color(1, 0.9, 0.5), HORIZONTAL_ALIGNMENT_LEFT, true)
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(ml)
	if int(it.plus) >= 15:
		vb.add_child(UiKit.lbl("Sudah +15 (maksimal)", 24, UiKit.GOOD, HORIZONTAL_ALIGNMENT_CENTER, true))
	else:
		var rate: float = G.forge_rate(it, forge_w, forge_safe)
		vb.add_child(UiKit.lbl("+%d  →  +%d" % [int(it.plus), int(it.plus) + 1], 34, GOLD, HORIZONTAL_ALIGNMENT_CENTER, true))
		vb.add_child(UiKit.rich("Peluang sukses [b][color=#%s]%.1f%%[/color][/b]\nBiaya [b]%s[/b] Laima   Gagal beruntun %d" % [UiKit.hex(UiKit.GOOD if rate >= 50.0 else UiKit.BAD), rate, Scaling.fmt(G.forge_cost(it)), int(it.fails)], 22))
		var wn := {"none": "Tanpa Warranty", "w50": "Warranty 50%% (%d)" % G.stack_count("w50"), "w100": "Warranty 100%% (%d)" % G.stack_count("w100")}
		var wb := UiKit.btn(wn[forge_w], "normal", Vector2(0, 56), 20)
		if forge_w != "none":
			wb.icon = UiKit.icon(forge_w)
			wb.expand_icon = true
		wb.pressed.connect(func():
			var order := ["none", "w50", "w100"]
			forge_w = order[(order.find(forge_w) + 1) % 3]
			refresh())
		vb.add_child(wb)
		var sb := UiKit.btn("Safety Stone: %s (%d)" % ["PAKAI" if forge_safe else "tidak", G.stack_count("safety")], "green" if forge_safe else "normal", Vector2(0, 56), 20)
		sb.pressed.connect(func():
			forge_safe = not forge_safe
			refresh())
		vb.add_child(sb)
		var fb := UiKit.btn("TEMPA SEKARANG", "gold", Vector2(0, 72), 28)
		fb.pressed.connect(func(): _msg(G.forge(it, forge_w, forge_safe)))
		vb.add_child(fb)
		if int(it.tier) >= 260:
			var cb := UiKit.btn("Confusion: acak stat ±10%%  (%s L + 3 Gem)" % Scaling.fmt(int(Scaling.price(int(it.tier)) * 0.5)), "normal", Vector2(0, 52), 18)
			cb.pressed.connect(func(): _msg(G.confusion(it)))
			vb.add_child(cb)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_child(hb)
	return m

# ---------- menu rows ----------
func _menu_pause() -> Array:
	var r: Array = []
	r.append({"label": "%s  |  Lv %d  |  %s\nTersimpan otomatis tiap 20 detik, saat pindah map, dan saat keluar.%s" % [G.player_name, G.lv, world.map.name, ("\nTerakhir disimpan: " + G.last_save) if G.last_save != "" else ""]})
	r.append({"t": "Lanjutkan Permainan", "ic": UiKit.icon("g_back"), "f": close_menu})
	r.append({"t": "Simpan Sekarang", "ic": UiKit.icon("g_save"), "f": func():
		G.save_game()
		_on_toast("Tersimpan", false)
		refresh()})
	r.append({"t": "Pengaturan", "ic": UiKit.icon("g_gear"), "f": func(): push_menu("Pengaturan", _menu_settings)})
	r.append({"t": "Kembali ke Menu Utama", "ic": UiKit.icon("g_info"), "f": func(): push_menu("Kembali ke Menu Utama?", _menu_title_confirm)})
	r.append({"t": "Keluar Game", "ic": UiKit.icon("g_close"), "col": UiKit.BAD, "f": func(): push_menu("Keluar Game?", _menu_quit_confirm)})
	return r

func _menu_title_confirm() -> Array:
	return [
		{"label": "Progres kamu disimpan otomatis sebelum kembali ke layar judul."},
		{"t": "Simpan dan Kembali ke Menu Utama", "f": func():
			close_menu()
			G.to_title.emit()},
		{"t": "Batal", "f": pop_menu},
	]

func _menu_quit_confirm() -> Array:
	return [
		{"label": "Game akan disimpan otomatis, lalu ditutup. Kamu bisa melanjutkan dari titik ini lain kali."},
		{"t": "Simpan dan Keluar", "f": func():
			G.save_game()
			get_tree().quit()},
		{"t": "Batal", "f": pop_menu},
	]

func _menu_status() -> Array:
	return [{"label": "Gunakan tombol Karakter."}]

func _menu_skill() -> Array:
	var r: Array = []
	for s in Data.SKILLS:
		var sl: int = G.skill_lv(s.id)
		var need: float = 20.0 * pow(float(sl), 1.3)
		var sub: String = String(Data.SKILL_DESC.get(s.id, ""))
		var rt := "Lv %d/%d" % [sl, s.max]
		var row := {"t": String(s.name), "s": sub, "ic": UiKit.icon("sk_" + String(s.id)), "rt": rt}
		if G.lv < s.unlock:
			row["rt"] = "Terbuka Lv %d" % s.unlock
			row["d"] = true
		elif sl < s.max:
			row["bar"] = float(G.skills[s.id].xp) / need
		else:
			row["rt"] = "MAX"
		r.append(row)
	r.append({"label": "Skill naik level karena dipakai."})
	return r

func _menu_settings() -> Array:
	var r: Array = []
	var em := [1, 10, 100, 1000]
	var dm := [1, 2, 4, 6]
	r.append({"t": "Rate EXP: x%d" % G.settings.exp_mult, "s": "Ketuk untuk ganti", "ic": UiKit.icon("g_up"), "f": func():
		G.settings.exp_mult = em[(em.find(int(G.settings.exp_mult)) + 1) % 4]
		refresh()})
	r.append({"t": "Rate Drop: x%d" % G.settings.drop_mult, "s": "x6 = +500%", "ic": UiKit.icon("gem"), "f": func():
		G.settings.drop_mult = dm[(dm.find(int(G.settings.drop_mult)) + 1) % 4]
		refresh()})
	for e in [["death_penalty", "Penalti mati (-0.5% Laima)"], ["auto_potion", "Auto-Potion"], ["auto_sell", "Auto-jual (filter aktif)"], ["auto_attack", "Auto-serang"], ["auto_hunt", "Auto-Hunt"]]:
		var key: String = e[0]
		var nm: String = e[1]
		r.append({"t": nm, "rt": "ON" if G.settings[key] else "OFF", "col": UiKit.GOOD if G.settings[key] else UiKit.TXT_DIM, "f": func():
				G.settings[key] = not G.settings[key]
				refresh()})
	r.append({"t": "Filter Auto-Selling", "s": _auto_sell_summary(), "ic": UiKit.icon("g_sell"), "f": func(): push_menu("Filter Auto-Selling", _menu_auto_sell_filter)})
	r.append({"t": "Simpan sekarang", "ic": UiKit.icon("g_save"), "f": func():
		G.save_game()
		_on_toast("Tersimpan", false)})
	return r

func _auto_sell_summary() -> String:
	var rarity: int = clampi(int(G.settings.get("auto_sell_max_rarity", 1)), 0, ItemDb.RARITY_NAME.size() - 1)
	return "Jual sampai %s, tier ≤ %d" % [ItemDb.RARITY_NAME[rarity], int(G.settings.get("auto_sell_max_tier", 400))]

func _menu_auto_sell_filter() -> Array:
	var r: Array = []
	r.append({"label": "Item Set, Option, Plus, socket, dan upgrade dilindungi sesuai sakelar di bawah."})
	r.append({"t": "Batas rarity", "s": "Rarity sampai batas ini boleh dijual", "rt": ItemDb.RARITY_NAME[int(G.settings.auto_sell_max_rarity)], "f": func():
		G.settings.auto_sell_max_rarity = (int(G.settings.auto_sell_max_rarity) + 1) % 4
		refresh()})
	var tier_options := [10, 50, 100, 200, 320, 400]
	r.append({"t": "Batas tier", "s": "Item di atas batas selalu disimpan", "rt": "≤ %d" % int(G.settings.auto_sell_max_tier), "f": func():
		var idx: int = tier_options.find(int(G.settings.auto_sell_max_tier))
		G.settings.auto_sell_max_tier = tier_options[(idx + 1) % tier_options.size()]
		refresh()})
	for e in [["auto_sell_keep_sets", "Simpan item Set"], ["auto_sell_keep_options", "Simpan item ber-Option"], ["auto_sell_keep_plus", "Simpan item Plus"], ["auto_sell_keep_socket", "Simpan item bersocket"], ["auto_sell_keep_upgrades", "Simpan item Upgrade"]]:
		var key: String = e[0]
		var title: String = e[1]
		r.append({"t": title, "rt": "ON" if G.settings[key] else "OFF", "col": UiKit.GOOD if G.settings[key] else UiKit.TXT_DIM, "f": func():
			G.settings[key] = not G.settings[key]
			refresh()})
	return r

func _menu_scroll() -> Array:
	var r: Array = []
	r.append({"t": "Town Portal Scroll", "s": "Pulang ke kota", "ic": "tp", "rt": "x%d" % G.stack_count("tp"), "d": G.stack_count("tp") < 1 or world.map.town, "f": func():
		if G.take_stack("tp", 1):
			close_menu()
			world.warp(0)})
	r.append({"t": "Warp Scroll", "s": "Pilih map tujuan", "ic": "warp", "rt": "x%d" % G.stack_count("warp"), "d": G.stack_count("warp") < 1, "f": func():
		push_menu("Warp (pakai 1 Warp Scroll)", _menu_warp_scroll)})
	r.append({"t": "Double EXP Capsule", "s": "EXP x2 selama 30 menit", "ic": "capsule", "rt": "x%d" % G.stack_count("capsule"), "d": G.stack_count("capsule") < 1, "f": func():
		if G.take_stack("capsule", 1):
			G.capsule_t = 1800.0
			refresh()})
	return r

func _warp_rows(cost_scroll: bool) -> Array:
	var r: Array = []
	for m in Data.MAPS:
		if m.id == 0:
			continue
		var ok: bool = G.visited.has(m.id) or G.lv >= m.min - 10
		var cb: Callable = func():
			if cost_scroll and not G.take_stack("warp", 1):
				return
			close_menu()
			world.warp(m.id)
		r.append({"t": String(m.name), "s": "Level %d - %d%s" % [m.min, m.max, "" if ok else "   (terkunci)"], "ic": UiKit.icon("g_map"), "d": not ok, "f": cb})
	var cb2: Callable = func():
		close_menu()
		world.warp(0)
	r.append({"t": "Kota Velamina", "s": "Zona aman", "ic": UiKit.icon("g_map"), "f": cb2, "d": world.map.id == 0})
	return r

func _menu_warp() -> Control:
	return _warp_picker(false)

func _menu_warp_scroll() -> Control:
	return _warp_picker(true)

func _warp_picker(cost_scroll: bool) -> Control:
	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 8)
	var hint := "Pilih map tujuan" if not cost_scroll else "Pilih map tujuan • 1 Warp Scroll"
	root_box.add_child(UiKit.lbl(hint, 22, UiKit.TXT_DIM, HORIZONTAL_ALIGNMENT_CENTER, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for m in Data.MAPS:
		var map_id: int = int(m.id)
		var map_name: String = String(m.name)
		var map_min: int = int(m.min)
		var map_max: int = int(m.max)
		var is_town: bool = bool(m.town)
		var unlocked: bool = is_town or G.visited.has(map_id) or G.lv >= map_min - 10
		var current: bool = not world.map.get("dungeon", false) and world.map.id == map_id
		var can_warp: bool = unlocked and not current and (not cost_scroll or is_town or G.stack_count("warp") > 0)
		var text := "%s\n%s" % [map_name, "Zona aman" if is_town else "Lv %d – %d" % [map_min, map_max]]
		if current:
			text += "\n(LOKASI SAAT INI)"
		elif not unlocked:
			text += "\nTERKUNCI"
		elif cost_scroll and not is_town:
			text += "\nWarp x%d" % G.stack_count("warp")
		var b := UiKit.btn(text, "gold" if current else "normal", Vector2(0, 86), 19)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.disabled = not can_warp
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.tooltip_text = "Map %d" % map_id
		b.pressed.connect(func():
			if cost_scroll and not is_town and not G.take_stack("warp", 1):
				_on_toast("Warp Scroll habis", false)
				return
			close_menu()
			world.warp(map_id))
		grid.add_child(b)
	root_box.add_child(grid)
	return root_box

func _menu_dungeon() -> Array:
	var d: Dictionary = Data.dungeon_for(world.map.id)
	var ok: bool = G.lv >= int(d.min)
	return [{"t": str(d.name), "s": "Monster spesial • EXP x2 • Loot tier %d • Boss dungeon" % int(d.drop_tier), "ic": UiKit.icon("g_map"), "d": not ok, "f": func():
		if not ok:
			return
		close_menu()
		world.enter_dungeon(world.map.id)}]

func _menu_dungeon_exit() -> Array:
	return [{"t": "Keluar dari dungeon", "s": "Kembali ke map asal", "ic": UiKit.icon("g_map"), "f": func():
		close_menu()
		world.exit_dungeon()}]

func _menu_inv() -> Control:
	return _win_char()

# ---- shops ----
func _menu_class_shop() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.add_child(UiKit.lbl("Laima: %s   |   Stok tetap semua tier. Ketuk item untuk melihat detail & membeli." % Scaling.fmt(G.laima), 20, UiKit.TXT_DIM))
	var cells: Array = []
	for t in Data.NPC_EQUIPMENT_TIERS:
		for slot in ItemDb.SLOTS:
			var tt: int = t
			var sl: String = slot
			var it := G.make_item(sl, tt, 0, 0)
			var cell := _slot_for_item(it, 96.0)
			cell.tag = Scaling.fmt(Scaling.price(tt))
			cell.tapped.connect(func(_s): _popup_buy(it))
			cells.append(cell)
	var grid := _grid(cells, 9, 96.0, 27)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_child(vb)
	return m

func _popup_buy(it: Dictionary) -> void:
	var price := Scaling.price(int(it.tier))
	var cur: Dictionary = G.equipped.get(String(it.slot), {})
	var body := ItemCard.build_item(it, cur)
	show_popup(body, [{"t": "Beli %s" % Scaling.fmt(price), "kind": "gold", "d": G.laima < price or G.bag.size() >= G.BAG_MAX, "f": func(): _buy_equip(it, price)}])

func _buy_equip(it: Dictionary, price: int) -> void:
	if G.laima < price:
		_on_toast("Laima tidak cukup", false)
		return
	if G.bag.size() >= G.BAG_MAX:
		_on_toast("Tas penuh", false)
		return
	G.laima -= price
	G.bag.append(it)
	_on_toast("Dibeli: " + G.item_name(it), false)
	refresh()

func _buy_stack(id: String, n: int, unit: int) -> void:
	var cost := unit * n
	if G.laima < cost:
		_on_toast("Laima tidak cukup", false)
		return
	G.laima -= cost
	G.add_stack(id, n)
	refresh()

func _menu_potion(mult: float) -> Array:
	var r: Array = []
	r.append({"label": "Laima: %s" % Scaling.fmt(G.laima)})
	for e in Data.NPC_SUPPORT_STOCK:
		var id: String = e[0]
		var unit: int = maxi(1, int(float(e[2]) * mult))
		for n in e[1]:
			var nn: int = n
			r.append({"t": "%s x%d" % [ItemDb.stack_name(id), nn], "s": "Punya %d" % G.stack_count(id), "ic": id, "rt": "%s L" % Scaling.fmt(unit * nn), "d": G.laima < unit * nn, "f": func(): _buy_stack(id, nn, unit)})
	return r

func _menu_market() -> Array:
	var r: Array = []
	r.append({"label": "Pasar membeli barang drop 30%% nilai. Laima: %s" % Scaling.fmt(G.laima)})
	var junk := _junk_items()
	var total := 0
	for it in junk:
		total += G.sell_value(it)
	r.append({"t": "Jual semua gear tak terpakai", "s": "%d item" % junk.size(), "ic": UiKit.icon("g_sell"), "rt": "%s L" % Scaling.fmt(total), "d": junk.is_empty(), "f": func():
		for it in junk:
			G.bag.erase(it)
		G.laima += total
		refresh()})
	var gems := G.stack_count("gem")
	var gv := int(Scaling.laima_kill(G.lv) * 2.0)
	r.append({"t": "Jual semua Gem Kasar", "s": "%d buah" % gems, "ic": "gem", "rt": "%s L" % Scaling.fmt(gems * gv), "d": gems < 1, "f": func():
		G.laima += gems * gv
		G.stacks["gem"] = 0
		refresh()})
	r.append({"t": "Beli kembali", "s": "10 item terakhir yang dijual", "ic": UiKit.icon("g_back"), "f": func(): push_menu("Beli Kembali", _menu_buyback)})
	return r

func _menu_buyback() -> Array:
	var r: Array = []
	for e in G.sold:
		var rec: Dictionary = e
		r.append({"t": G.item_name(rec.item), "s": ItemDb.SLOT_LABEL[rec.item.slot], "ic": UiKit.item_icon(rec.item), "rt": "%s L" % Scaling.fmt(rec.price), "d": G.laima < rec.price or G.bag.size() >= G.BAG_MAX, "f": func():
			G.laima -= rec.price
			G.bag.append(rec.item)
			G.sold.erase(rec)
			refresh()})
	if r.is_empty():
		r.append({"label": "(kosong)"})
	return r

func _menu_jewel() -> Array:
	var r: Array = []
	r.append({"label": "Laima: %s\nPermata dipasang ke socket perlengkapan. Aetherial Jewel menambah Option (item tier 350+, maks 3)." % Scaling.fmt(G.laima)})
	r.append({"t": "Pasang Permata (Socket)", "s": "Pilih item lalu pasang permata", "ic": UiKit.icon("g_socket"), "f": func():
		push_menu("Pilih item", func(): return _pick_grid(G.all_items(), func(it):
			sock_sel = ""
			sock_msg = ""
			push_menu("Socket Permata", func(): return _menu_socket(it)), "Pilih item untuk dipasangi permata."))})
	r.append({"t": "Gabung Permata", "s": "3 permata sama jadi 1 tingkat lebih tinggi", "ic": "g_ruby3", "f": func(): push_menu("Gabung Permata", _menu_combine)})
	r.append({"t": "Beli Permata", "s": "Rubi, Topaz, Amethyst, Zamrud, Safir", "ic": "g_topaz2", "f": func(): push_menu("Beli Permata", _menu_gem_shop)})
	for e in [["aeth4", Data.NPC_JEWEL_PRICES.aeth4], ["aeth3", Data.NPC_JEWEL_PRICES.aeth3], ["aeth2", Data.NPC_JEWEL_PRICES.aeth2], ["aeth1", Data.NPC_JEWEL_PRICES.aeth1]]:
		var id: String = e[0]
		var unit: int = int(e[1])
		r.append({"t": "Beli %s" % ItemDb.stack_name(id), "s": "Punya %d" % G.stack_count(id), "ic": id, "rt": "%s L" % Scaling.fmt(unit), "d": G.laima < unit, "f": func(): _buy_stack(id, 1, unit)})
	r.append({"t": "Pasang Option pada item (tier 350+)", "ic": UiKit.icon("g_up"), "f": func(): push_menu("Pilih item", _menu_option_list)})
	return r

func _menu_gem_shop() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.add_child(UiKit.lbl("Laima: %s   |   Ketuk permata untuk membeli (tingkat Kasar & Biasa)." % Scaling.fmt(G.laima), 20, UiKit.TXT_DIM))
	var cells: Array = []
	for g in [1, 2]:
		for t in ItemDb.GEM_TYPES:
			var gid := ItemDb.gem_id(t, g)
			var price: int = int(Data.NPC_GEM_PRICES[g])
			var sl := ItemSlot.new(96.0)
			sl.set_stack("g_" + gid, G.gem_stack(gid))
			sl.tag = Scaling.fmt(price)
			sl.tapped.connect(func(_s):
				show_popup(ItemCard.build_stack("g_" + gid, G.gem_stack(gid)), [{"t": "Beli %s" % Scaling.fmt(price), "kind": "gold", "d": G.laima < price, "f": func(): _buy_stack("g_" + gid, 1, price)}]))
			cells.append(sl)
	var grid := _grid(cells, 5, 96.0, 10)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_child(vb)
	return m

func _menu_combine() -> Array:
	var r: Array = []
	r.append({"label": "Gabungkan 3 permata sama menjadi 1 tingkat berikutnya. Laima: %s" % Scaling.fmt(G.laima)})
	var any := false
	for t in ItemDb.GEM_TYPES:
		for g in range(1, 5):
			var gid := ItemDb.gem_id(t, g)
			var n := G.gem_stack(gid)
			if n > 0:
				any = true
				r.append({"t": ItemDb.gem_name(gid), "s": ItemDb.gem_text(gid), "ic": UiKit.gem_icon(gid), "rt": "x%d  (%s L)" % [n, Scaling.fmt(G.combine_cost(g))], "d": n < 3, "f": func(): _msg(G.combine_gem(gid))})
	if not any:
		r.append({"label": "Belum punya permata."})
	return r

func _menu_option_list() -> Control:
	var items: Array = []
	for it in G.all_items():
		if int(it.tier) >= 350:
			items.append(it)
	if items.is_empty():
		return _rows_view([{"label": "Belum ada item tier 350+"}])
	return _pick_grid(items, func(it): push_menu("Option", func(): return _menu_option_item(it)), "Pilih item tier 350+.")

func _menu_option_item(it: Dictionary) -> Array:
	var r: Array = []
	r.append({"rich": ItemCard.item_title(it) + "\n" + ItemCard.item_body(it)})
	if forge_msg != "":
		r.append({"label": ">> " + forge_msg})
	for g in ["aeth4", "aeth3", "aeth2", "aeth1"]:
		var gg: String = g
		r.append({"t": "Pakai %s" % ItemDb.stack_name(gg), "s": "Punya %d" % G.stack_count(gg), "ic": gg, "d": G.stack_count(gg) < 1, "f": func(): _msg(G.add_option(it, gg))})
	r.append({"t": "Reset Option", "rt": "%s L" % Scaling.fmt(int(Scaling.price(int(it.tier)) * 0.2)), "d": it.opts.is_empty(), "f": func():
		var c := int(Scaling.price(int(it.tier)) * 0.2)
		if G.laima >= c:
			G.laima -= c
			it.opts = []
			_msg("Option direset")
		else:
			_msg("Laima tidak cukup")})
	return r

func _menu_karu() -> Array:
	var r: Array = []
	r.append({"label": "Koin Karu: %d (dari boss, elite, quest)" % G.karu})
	for e in [["safety", 2], ["w100", 6], ["aeth1", 10], ["capsule", 1]]:
		var id: String = e[0]
		var c: int = e[1]
		r.append({"t": ItemDb.stack_name(id), "ic": id, "rt": "%d Koin" % c, "d": G.karu < c, "f": func():
			G.karu -= c
			G.add_stack(id, 1)
			refresh()})
	return r

func _menu_quest() -> Array:
	var r: Array = []
	r.append({"label": "QUEST HARIAN  •  Reset otomatis setiap hari", "ic": UiKit.icon("g_quest")})
	for q in Data.DAILY_QUESTS:
		var qid: String = q.id
		var progress: int = mini(G.daily_value(String(q.key)), int(q.target))
		var claimed: bool = bool(G.daily_claimed.get(qid, false))
		r.append({"t": q.name, "s": "%s  •  Hadiah: %s" % [q.desc, q.reward], "rt": "%d / %d" % [progress, int(q.target)], "bar": float(progress) / float(q.target), "ic": UiKit.icon("g_quest")})
		if qid == "daily_hunt":
			continue
		r.append({"t": "Klaim Quest: " + q.name, "s": "Sudah diklaim" if claimed else "Selesaikan target untuk mengambil hadiah", "ic": "safety", "d": claimed or progress < int(q.target), "f": func():
			G.claim_daily(qid)
			refresh()})
	r.append({"label": "ACHIEVEMENT  •  Progres permanen karakter"})
	for a in Data.ACHIEVEMENTS:
		var aid: String = a.id
		var ap: int = mini(G.achievement_value(String(a.stat)), int(a.target))
		var done: bool = bool(G.achievement_claimed.get(aid, false))
		r.append({"t": a.name, "s": "%s  •  Hadiah: %s" % [a.desc, a.reward], "rt": "SELESAI" if done else "%d / %d" % [ap, int(a.target)], "bar": float(ap) / float(a.target), "ic": UiKit.icon("g_quest")})
		r.append({"t": "Klaim Achievement: " + a.name, "s": "Hadiah sudah diambil" if done else "Target tercapai — klaim sekarang" if ap >= int(a.target) else "Teruskan petualanganmu", "ic": "safety", "d": done or ap < int(a.target), "f": func():
			G.claim_achievement(aid)
			refresh()})
	return r
