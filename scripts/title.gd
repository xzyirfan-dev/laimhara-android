class_name Title
extends Node
## Layar judul Laimhara: Lanjutkan / Game Baru / Tentang / Keluar, pembuatan karakter
## (nama, warna rambut, rate EXP) dengan validasi, lalu intro cerita.

signal start_game(mode: String)

var scene3d: Node3D
var hero: Hero
var cam: Camera3D
var ui: CanvasLayer
var root: Control
var screen: Control
var _t := 0.0
var _name_edit: LineEdit
var _err: Label
var _go_btn: Button
var _hair := 0
var _rate_idx := 3
var _hair_btns: Array = []
var _rate_btns: Array = []
var _modal: Control
var _intro_i := 0
var _intro_lbl: Label

func _ready() -> void:
	_build_scene()
	ui = CanvasLayer.new()
	add_child(ui)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = Gfx.make_theme()
	ui.add_child(root)
	G.back_pressed.connect(_on_back)
	_show_main()

func _exit_tree() -> void:
	if G.back_pressed.is_connected(_on_back):
		G.back_pressed.disconnect(_on_back)

# ------------------------------------------------------------------ latar 3D
func _build_scene() -> void:
	scene3d = Node3D.new()
	add_child(scene3d)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.05, 0.07, 0.18)
	sm.sky_horizon_color = Color(0.45, 0.3, 0.38)
	sm.ground_horizon_color = Color(0.3, 0.2, 0.28)
	sm.ground_bottom_color = Color(0.04, 0.03, 0.06)
	var sky := Sky.new()
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.7)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color(0.3, 0.22, 0.32)
	env.fog_density = 0.02
	var we := WorldEnvironment.new()
	we.environment = env
	scene3d.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -40, 0)
	sun.light_color = Color(1.0, 0.8, 0.65)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	scene3d.add_child(sun)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-3.0, 3.0, -3.0)
	rim.light_color = Color(0.4, 0.8, 1.0)
	rim.light_energy = 2.0
	rim.omni_range = 12.0
	scene3d.add_child(rim)
	# lantai ubin batu + panggung
	var tex := Gfx.tex_tiles(Color(0.26, 0.22, 0.2), Color(0.07, 0.05, 0.05), 4, 0.03, "title_tiles")
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 120)
	fl.mesh = pm
	fl.material_override = Gfx.ground_material(tex, 120.0, 8.0)
	scene3d.add_child(fl)
	Gfx.cyl(scene3d, 2.1, 2.3, 0.35, Vector3(1.8, 0.17, 0), Color(0.4, 0.36, 0.34), false, 28)
	Gfx.ring(scene3d, 1.7, 1.95, Vector3(1.8, 0.37, 0), Color(0.4, 0.85, 1.0))
	# pilar & obor
	for i in 8:
		var a := TAU * float(i) / 8.0 + 0.4
		var p := Vector3(cos(a) * 11.0, 0, sin(a) * 11.0 - 4.0)
		Gfx.cyl(scene3d, 0.7, 0.85, 7.0, p + Vector3(0, 3.5, 0), Color(0.33, 0.35, 0.4), false, 8)
		Gfx.box(scene3d, Vector3(1.8, 0.4, 1.8), p + Vector3(0, 7.2, 0), Color(0.45, 0.42, 0.34))
		Gfx.sph(scene3d, 0.28, p + Vector3(0, 7.8, 0), Color(1.0, 0.6, 0.2), true, Vector3(0.8, 1.4, 0.8))
		var ol := OmniLight3D.new()
		ol.position = p + Vector3(0, 7.8, 0)
		ol.light_color = Color(1.0, 0.6, 0.3)
		ol.light_energy = 1.4
		ol.omni_range = 11.0
		scene3d.add_child(ol)
	# kristal melayang
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 16:
		var c := Gfx.cyl(scene3d, 0.0, 0.2, 0.8, Vector3(rng.randf_range(-12, 12), rng.randf_range(1.0, 6.0), rng.randf_range(-14, -2)), Color(0.5, 0.8, 1.0), true, 5)
		c.set_meta("ph", rng.randf() * TAU)
		c.add_to_group("title_crystal")
	# karakter
	hero = Hero.new()
	hero.position = Vector3(1.8, 0.35, 0)
	scene3d.add_child(hero)
	hero.hair_col = Data.HAIR_COLORS[0].c
	hero.build(200, 200)
	cam = Camera3D.new()
	cam.fov = 45
	scene3d.add_child(cam)
	cam.look_at_from_position(Vector3(-0.3, 2.3, 8.6), Vector3(1.2, 1.3, 0))

func _rebuild_hero(armor_t: int = 200) -> void:
	hero.hair_col = Data.HAIR_COLORS[_hair].c
	hero.build(armor_t, armor_t)

func _process(delta: float) -> void:
	_t += delta
	hero.rotation.y = -0.45 + sin(_t * 0.6) * 0.5
	hero.animate(delta, false, false)
	for c in get_tree().get_nodes_in_group("title_crystal"):
		var n: Node3D = c
		n.position.y += sin(_t * 1.2 + float(n.get_meta("ph"))) * delta * 0.4
		n.rotation.y += delta * 0.8

# ------------------------------------------------------------------ util UI
func _clear() -> void:
	_name_edit = null
	if screen != null:
		screen.queue_free()
	screen = Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(screen)

func _logo(parent: Control) -> void:
	var v := VBoxContainer.new()
	v.anchor_left = 0.05
	v.anchor_top = 0.05
	v.anchor_right = 0.5
	v.add_theme_constant_override("separation", -6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := Label.new()
	t.text = "LAIMHARA"
	t.add_theme_font_size_override("font_size", 84)
	t.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	t.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.02))
	t.add_theme_constant_override("outline_size", 14)
	v.add_child(t)
	var s := Label.new()
	s.text = "Penembak dari Velamina"
	s.add_theme_font_size_override("font_size", 28)
	s.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	s.add_theme_color_override("font_outline_color", Color.BLACK)
	s.add_theme_constant_override("outline_size", 8)
	v.add_child(s)
	parent.add_child(v)

func _panel(parent: Control, l: float, t: float, r: float, b: float) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.anchor_left = l
	pc.anchor_top = t
	pc.anchor_right = r
	pc.anchor_bottom = b
	parent.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	return vb

func _btn(parent: Control, text: String, cb: Callable, h: float = 64.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, h)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _lbl(parent: Control, text: String, size: int = 24, col: Color = Color(0.93, 0.9, 0.82)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l

func _footer(parent: Control) -> void:
	var f := Label.new()
	f.text = "Laimhara v1.0  |  Godot 4.3"
	f.add_theme_font_size_override("font_size", 18)
	f.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 0.8))
	f.anchor_left = 0.05
	f.anchor_top = 0.95
	f.anchor_right = 0.6
	f.anchor_bottom = 1.0
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(f)

# ------------------------------------------------------------------ layar utama
func _show_main() -> void:
	_clear()
	_rebuild_hero(200)
	_logo(screen)
	var vb := _panel(screen, 0.05, 0.36, 0.42, 0.93)
	var info := G.save_info()
	var has := info.size() > 0
	var cont := _btn(vb, "Lanjutkan", func(): _start("load"), 72)
	cont.disabled = not has
	if has:
		var ts: String = str(info.ts).replace("T", "  ")
		_lbl(vb, "%s  |  Lv %d  |  %s" % [info.name, info.lv, info.map], 21, Color(1.0, 0.88, 0.5))
		if ts != "":
			_lbl(vb, "Terakhir disimpan: " + ts, 18, Color(0.7, 0.75, 0.85))
	else:
		_lbl(vb, "Belum ada data tersimpan.", 20, Color(0.65, 0.65, 0.7))
	_btn(vb, "Game Baru", _on_new)
	_btn(vb, "Tentang Ras Human", _show_about)
	_btn(vb, "Keluar Game", _ask_quit)
	_footer(screen)

func _on_new() -> void:
	if G.has_save():
		_confirm("Mulai Game Baru?", "Data tersimpan yang lama akan ditimpa saat kamu memulai game baru.", "Lanjut Game Baru", _show_create)
	else:
		_show_create()

func _ask_quit() -> void:
	_confirm("Keluar dari Laimhara?", "Kamu akan keluar dari game. Progres yang sudah tersimpan tetap aman.", "Keluar", func(): get_tree().quit())

func _show_about() -> void:
	_clear()
	_logo(screen)
	var vb := _panel(screen, 0.05, 0.34, 0.5, 0.93)
	_lbl(vb, "Ras Human", 36, Color(1.0, 0.86, 0.45))
	_lbl(vb, Data.RACE_LORE, 23)
	_lbl(vb, "Skill utama: Marksmanship, Electric Shield, Sniping, Semi-automatic Fire, Frozen Shot, Air Raid, Fire Blindly.", 21, Color(0.7, 0.9, 1.0))
	_btn(vb, "< Kembali", _show_main)

# ------------------------------------------------------------------ pembuatan karakter
func _show_create() -> void:
	_clear()
	_rebuild_hero(1)
	var vb := _panel(screen, 0.04, 0.05, 0.5, 0.95)
	var hd := _lbl(vb, "Buat Karakter", 40, Color(1.0, 0.86, 0.45))
	hd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl(vb, "Nama Karakter", 24, Color(0.7, 0.9, 1.0))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Masukkan nama (3-12 karakter)"
	_name_edit.max_length = 12
	_name_edit.custom_minimum_size = Vector2(0, 64)
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_changed.connect(_on_name_changed)
	_name_edit.text_submitted.connect(func(_t: String): if not _go_btn.disabled: _go())
	hb.add_child(_name_edit)
	var rb := Button.new()
	rb.text = "Acak"
	rb.custom_minimum_size = Vector2(110, 64)
	rb.pressed.connect(func():
		_name_edit.text = _random_name()
		_on_name_changed(_name_edit.text))
	hb.add_child(rb)
	_err = _lbl(vb, " ", 20, Color(1.0, 0.45, 0.4))
	_lbl(vb, "Warna Rambut", 24, Color(0.7, 0.9, 1.0))
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 8)
	vb.add_child(hr)
	_hair_btns.clear()
	for i in Data.HAIR_COLORS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 54)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = Data.HAIR_COLORS[i].n
		var idx := i
		b.pressed.connect(func(): _pick_hair(idx))
		hr.add_child(b)
		_hair_btns.append(b)
	_lbl(vb, "Rate EXP", 24, Color(0.7, 0.9, 1.0))
	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 8)
	vb.add_child(rr)
	_rate_btns.clear()
	for i in Data.EXP_RATES.size():
		var b2 := Button.new()
		b2.text = "x%d" % Data.EXP_RATES[i]
		b2.custom_minimum_size = Vector2(0, 54)
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ri := i
		b2.pressed.connect(func(): _pick_rate(ri))
		rr.add_child(b2)
		_rate_btns.append(b2)
	_lbl(vb, "Ras: Human (Penembak)  |  Awal: Kota Velamina", 20, Color(0.8, 0.8, 0.85))
	var bb := HBoxContainer.new()
	bb.add_theme_constant_override("separation", 10)
	vb.add_child(bb)
	var back := Button.new()
	back.text = "< Kembali"
	back.custom_minimum_size = Vector2(0, 68)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(_show_main)
	bb.add_child(back)
	_go_btn = Button.new()
	_go_btn.text = "Mulai Petualangan"
	_go_btn.custom_minimum_size = Vector2(0, 68)
	_go_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_go_btn.size_flags_stretch_ratio = 1.4
	_go_btn.add_theme_stylebox_override("normal", Gfx.ui_button("green"))
	_go_btn.pressed.connect(_go)
	bb.add_child(_go_btn)
	_hair = 0
	_rate_idx = 3
	_pick_hair(0)
	_pick_rate(3)
	_name_edit.text = ""
	_on_name_changed("")

func _random_name() -> String:
	var syl := ["Ar", "Ken", "Zel", "Ra", "Vor", "Kai", "Lor", "Dax", "Mira", "Tor", "Sen", "Ryu", "Lan", "Ori", "Nax", "Bel", "Ruz"]
	return (str(syl.pick_random()) + str(syl.pick_random()).to_lower()).substr(0, 12)

func _pick_hair(i: int) -> void:
	_hair = i
	for k in _hair_btns.size():
		var b: Button = _hair_btns[k]
		var sb := StyleBoxFlat.new()
		sb.bg_color = Data.HAIR_COLORS[k].c
		sb.set_corner_radius_all(4)
		sb.set_border_width_all(6 if k == i else 2)
		sb.border_color = Color(1.0, 0.9, 0.4) if k == i else Color(0.25, 0.17, 0.08)
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sb)
	_rebuild_hero(1)

func _pick_rate(i: int) -> void:
	_rate_idx = i
	for k in _rate_btns.size():
		var b: Button = _rate_btns[k]
		b.add_theme_stylebox_override("normal", Gfx.ui_button("green" if k == i else "normal"))

func _validate(raw: String) -> String:
	var n := raw.strip_edges()
	if n.length() == 0:
		return ""
	if n.length() < 3:
		return "Nama minimal 3 karakter."
	if n.length() > 12:
		return "Nama maksimal 12 karakter."
	var rx := RegEx.new()
	rx.compile("^[A-Za-z0-9 _-]+$")
	if rx.search(n) == null:
		return "Hanya huruf, angka, spasi, _ dan -."
	if n.contains("  "):
		return "Jangan memakai spasi ganda."
	if n.replace(" ", "").is_valid_int():
		return "Nama tidak boleh hanya angka."
	var low := n.to_lower().replace(" ", "")
	for r in Data.RESERVED_NAMES:
		if low == r or low.begins_with("admin") or low.begins_with("moderator"):
			return "Nama ini dicadangkan, pilih nama lain."
	return ""

func _on_name_changed(t: String) -> void:
	var msg := _validate(t)
	_err.text = msg if msg != "" else " "
	_go_btn.disabled = t.strip_edges().length() < 3 or msg != ""

func _go() -> void:
	var n := _name_edit.text.strip_edges()
	if _validate(n) != "" or n.length() < 3:
		return
	G.in_game = false
	G.new_game(n, _hair, Data.EXP_RATES[_rate_idx])
	_show_intro()

# ------------------------------------------------------------------ intro
func _show_intro() -> void:
	_clear()
	_rebuild_hero(1)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(dim)
	var vb := _panel(screen, 0.12, 0.62, 0.88, 0.95)
	var head := _lbl(vb, G.player_name, 30, Color(1.0, 0.86, 0.45))
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_intro_lbl = _lbl(vb, "", 28)
	_intro_lbl.custom_minimum_size = Vector2(0, 110)
	var bb := HBoxContainer.new()
	bb.add_theme_constant_override("separation", 10)
	vb.add_child(bb)
	var skip := Button.new()
	skip.text = "Lewati"
	skip.custom_minimum_size = Vector2(0, 60)
	skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip.pressed.connect(func(): _start("new"))
	bb.add_child(skip)
	var nx := Button.new()
	nx.text = "Lanjut >"
	nx.custom_minimum_size = Vector2(0, 60)
	nx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nx.pressed.connect(_intro_next)
	bb.add_child(nx)
	_intro_i = -1
	_intro_next()

func _intro_next() -> void:
	_intro_i += 1
	var lines: Array = Data.INTRO
	if _intro_i >= lines.size():
		_start("new")
		return
	var line: String = str(lines[_intro_i]).replace("Arken", G.player_name)
	_intro_lbl.text = line
	_intro_lbl.visible_ratio = 0.0
	var tw := create_tween()
	tw.tween_property(_intro_lbl, "visible_ratio", 1.0, 0.04 * float(line.length()) + 0.2)

func _start(mode: String) -> void:
	start_game.emit(mode)

# ------------------------------------------------------------------ dialog konfirmasi
func _confirm(title: String, msg: String, yes_text: String, yes: Callable) -> void:
	if _modal != null:
		_modal.queue_free()
	_modal = Control.new()
	_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(dim)
	var vb := _panel(_modal, 0.2, 0.28, 0.8, 0.72)
	var h := _lbl(vb, title, 36, Color(1.0, 0.86, 0.45))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl(vb, msg, 24)
	var bb := HBoxContainer.new()
	bb.add_theme_constant_override("separation", 10)
	bb.size_flags_vertical = Control.SIZE_SHRINK_END
	vb.add_child(bb)
	var no := Button.new()
	no.text = "Batal"
	no.custom_minimum_size = Vector2(0, 66)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(_close_modal)
	bb.add_child(no)
	var ok := Button.new()
	ok.text = yes_text
	ok.custom_minimum_size = Vector2(0, 66)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.add_theme_stylebox_override("normal", Gfx.ui_button("red"))
	ok.pressed.connect(func():
		_close_modal()
		yes.call())
	bb.add_child(ok)
	root.add_child(_modal)

func _close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null

func _on_back() -> void:
	if _modal != null:
		_close_modal()
	elif _name_edit != null:
		_show_main()
	else:
		_ask_quit()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		_on_back()
