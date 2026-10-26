class_name Gfx
extends RefCounted
## Pustaka grafis prosedural (tanpa aset luar): material, mesh, tekstur lantai/dinding,
## bingkai UI perunggu ala jendela Laghaim (EXCHANGE / Inventory), dan ikon item.

static var _mats: Dictionary = {}
static var _tex: Dictionary = {}
static var _sty: Dictionary = {}
static var _ico: Dictionary = {}

const BRONZE_L := Color(0.22, 0.85, 1.0)
const BRONZE_M := Color(0.08, 0.35, 0.52)
const BRONZE_D := Color(0.015, 0.06, 0.1)
const INK := Color(0.008, 0.012, 0.02)

# ================= palet tier (satu palet untuk model, ikon, aura) =================
static func palette(t: int) -> Dictionary:
	if t >= 400:
			return {"main": Color(0.12, 0.2, 0.28), "dark": Color(0.025, 0.05, 0.09), "trim": Color(0.35, 0.9, 1.0), "glow": Color(0.2, 0.95, 1.0), "cape": Color(0.04, 0.12, 0.24), "wings": true, "name": "Ragnok"}
	if t >= 320:
			return {"main": Color(0.18, 0.06, 0.22), "dark": Color(0.055, 0.015, 0.08), "trim": Color(0.9, 0.2, 0.72), "glow": Color(1.0, 0.12, 0.65), "cape": Color(0.18, 0.025, 0.12), "wings": false, "name": "Moriath"}
	if t >= 200:
			return {"main": Color(0.22, 0.24, 0.27), "dark": Color(0.07, 0.075, 0.09), "trim": Color(1.0, 0.55, 0.14), "glow": Color(1.0, 0.42, 0.08), "cape": Color(0.18, 0.035, 0.025), "wings": false, "name": "Tanduk Putih"}
	if t >= 100:
			return {"main": Color(0.08, 0.22, 0.18), "dark": Color(0.02, 0.07, 0.055), "trim": Color(0.3, 0.95, 0.68), "glow": Color(0.15, 1.0, 0.55), "cape": Color(0.03, 0.16, 0.11), "wings": false, "name": "Penjaga"}
	if t >= 50:
			return {"main": Color(0.1, 0.19, 0.34), "dark": Color(0.025, 0.055, 0.13), "trim": Color(0.3, 0.7, 1.0), "glow": Color(0.2, 0.65, 1.0), "cape": Color(0.04, 0.09, 0.24), "wings": false, "name": "Badai"}
	if t >= 10:
			return {"main": Color(0.24, 0.16, 0.1), "dark": Color(0.07, 0.035, 0.02), "trim": Color(0.95, 0.48, 0.12), "glow": Color(1.0, 0.3, 0.08), "cape": Color(0.16, 0.035, 0.025), "wings": false, "name": "Perunggu"}
	return {"main": Color(0.16, 0.18, 0.23), "dark": Color(0.04, 0.05, 0.08), "trim": Color(0.35, 0.55, 0.75), "glow": Color(0.15, 0.75, 1.0), "cape": Color(0.05, 0.08, 0.15), "wings": false, "name": "Latihan"}

# ================= material & mesh =================
static func mat(c: Color, emis: bool = false, rough: float = 0.85, metal: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%s|%.2f|%.2f" % [c.to_html(), emis, rough, metal]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emis:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 1.6
	_mats[key] = m
	return m

static func part(parent: Node, mesh: Mesh, pos: Vector3, c: Color, emis: bool = false, rough: float = 0.85, metal: float = 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	m.material_override = mat(c, emis, rough, metal)
	parent.add_child(m)
	return m

static func box(parent: Node, size: Vector3, pos: Vector3, c: Color, emis: bool = false, rough: float = 0.85, metal: float = 0.0) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return part(parent, bm, pos, c, emis, rough, metal)

static func sph(parent: Node, r: float, pos: Vector3, c: Color, emis: bool = false, sc: Vector3 = Vector3.ONE, rough: float = 0.85, metal: float = 0.0) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 7
	var mi := part(parent, sm, pos, c, emis, rough, metal)
	mi.scale = sc
	return mi

static func cyl(parent: Node, top: float, bottom: float, h: float, pos: Vector3, c: Color, emis: bool = false, seg: int = 10, rough: float = 0.85, metal: float = 0.0) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = bottom
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	return part(parent, cm, pos, c, emis, rough, metal)

static func prism(parent: Node, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var pm := PrismMesh.new()
	pm.size = size
	return part(parent, pm, pos, c)

static func pivot(parent: Node, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n

static func ring(parent: Node, r_in: float, r_out: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = r_in
	tm.outer_radius = r_out
	tm.ring_segments = 6
	tm.rings = 28
	var mi := part(parent, tm, pos, c, true)
	mi.scale = Vector3(1, 0.25, 1)
	return mi

# ================= tekstur permukaan =================
static func _clamp_c(c: Color) -> Color:
	return Color(clampf(c.r, 0, 1), clampf(c.g, 0, 1), clampf(c.b, 0, 1), 1.0)

static func tex_noise(base: Color, vary: float, spk: Color, spk_p: float, key: String) -> ImageTexture:
	if _tex.has(key):
		return _tex[key]
	var img := Image.create(128, 128, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	for y in 128:
		for x in 128:
			var k := rng.randf_range(-vary, vary)
			var c := Color(base.r + k, base.g + k, base.b + k)
			if rng.randf() < spk_p:
				c = c.lerp(spk, rng.randf_range(0.4, 0.9))
			img.set_pixel(x, y, _clamp_c(c))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex[key] = t
	return t

## Lantai ubin batu besar (seperti lantai kota di screenshot Biosfear): ubin dengan sela gelap + bevel.
static func tex_tiles(base: Color, grout: Color, n: int, vary: float, key: String) -> ImageTexture:
	if _tex.has(key):
		return _tex[key]
	var sz := 128
	var img := Image.create(sz, sz, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var tp := sz / n
	var tint: Array = []
	for i in n * n:
		tint.append(rng.randf_range(-vary, vary))
	for y in sz:
		for x in sz:
			var tx := x / tp
			var ty := y / tp
			var lx := x % tp
			var ly := y % tp
			var k: float = tint[ty * n + tx] + rng.randf_range(-0.018, 0.018)
			var c := Color(base.r + k, base.g + k, base.b + k)
			if lx < 2 or ly < 2:
				c = grout
			elif lx < 4 or ly < 4:
				c = c.lightened(0.12)
			elif lx > tp - 4 or ly > tp - 4:
				c = c.darkened(0.2)
			img.set_pixel(x, y, _clamp_c(c))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex[key] = t
	return t

## Dinding bata (tembok kota).
static func tex_brick(base: Color, grout: Color, key: String) -> ImageTexture:
	if _tex.has(key):
		return _tex[key]
	var img := Image.create(128, 128, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var rows := 8
	var bh := 128 / rows
	var bw := 32
	for y in 128:
		var r := y / bh
		var off := (bw / 2) if r % 2 == 1 else 0
		for x in 128:
			var bx := (x + off) % bw
			var bid := ((x + off) / bw + r * 7) % 5
			var k := (float(bid) - 2.0) * 0.012 + rng.randf_range(-0.02, 0.02)
			var c := Color(base.r + k, base.g + k, base.b + k)
			if y % bh < 2 or bx < 2:
				c = grout
			elif y % bh > bh - 3:
				c = c.darkened(0.18)
			img.set_pixel(x, y, _clamp_c(c))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex[key] = t
	return t

static func ground_material(tex: Texture2D, size: float, tile_world: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(size / tile_world, size / tile_world, 1)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.95
	return m

static func tex_material(tex: Texture2D, scale: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.95
	return m

# ================= bingkai UI perunggu =================
static func _tex_style(img: Image, margin: int, content: int, key: String) -> StyleBoxTexture:
	if _sty.has(key):
		return _sty[key]
	var s := StyleBoxTexture.new()
	s.texture = ImageTexture.create_from_image(img)
	s.texture_margin_left = margin
	s.texture_margin_right = margin
	s.texture_margin_top = margin
	s.texture_margin_bottom = margin
	s.content_margin_left = content
	s.content_margin_right = content
	s.content_margin_top = content * 0.6
	s.content_margin_bottom = content * 0.6
	_sty[key] = s
	return s

static func _bevel_frame(img: Image, w: int, h: int, outer: int, light: Color, mid: Color, dark: Color, inset: bool) -> void:
	## bingkai: garis gelap luar, bevel perunggu (terang kiri-atas / gelap kanan-bawah), garis gelap dalam
	for y in h:
		for x in w:
			var d := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
			if d >= outer:
				continue
			var tl := float(x + y) / float(w + h)
			var c: Color
			if d < 1:
				c = INK
			elif d < outer - 1:
				var t := tl if not inset else 1.0 - tl
				c = light.lerp(dark, t) if d < outer - 3 else mid.lerp(dark, t)
			else:
				c = INK
			img.set_pixel(x, y, c)

static func _rivet(img: Image, cx: int, cy: int, r: int) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			var d := Vector2(x - cx, y - cy).length()
			if d <= r and x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				var l := 1.0 - d / float(r)
				img.set_pixel(x, y, BRONZE_D.lerp(BRONZE_L, clampf(l + 0.25 - float(y - cy) * 0.04, 0.0, 1.0)))

static func ui_panel() -> StyleBoxTexture:
	if _sty.has("panel"):
		return _sty["panel"]
	var sz := 96
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in sz:
		for x in sz:
			var k := rng.randf_range(-0.012, 0.012)
			var g := 0.075 + k
			img.set_pixel(x, y, Color(g + 0.012, g, g - 0.006, 0.97))
	_bevel_frame(img, sz, sz, 10, BRONZE_L, BRONZE_M, BRONZE_D, false)
	# garis dalam tipis
	for i in range(10, sz - 10):
		img.set_pixel(i, 11, Color(0.2, 0.13, 0.06))
		img.set_pixel(i, sz - 12, Color(0.2, 0.13, 0.06))
		img.set_pixel(11, i, Color(0.2, 0.13, 0.06))
		img.set_pixel(sz - 12, i, Color(0.2, 0.13, 0.06))
	for p in [Vector2i(7, 7), Vector2i(sz - 8, 7), Vector2i(7, sz - 8), Vector2i(sz - 8, sz - 8)]:
		_rivet(img, p.x, p.y, 4)
	return _tex_style(img, 22, 22, "panel")

static func ui_title() -> StyleBoxTexture:
	if _sty.has("title"):
		return _sty["title"]
	var w := 64
	var h := 56
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var t := float(y) / float(h)
		for x in w:
			img.set_pixel(x, y, Color(0.62, 0.1, 0.09).lerp(Color(0.24, 0.02, 0.03), t))
	for y in range(2, 14):
		for x in range(2, w - 2):
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, c.lerp(Color(1, 0.6, 0.5), 0.14 * (1.0 - float(y) / 14.0)))
	_bevel_frame(img, w, h, 6, BRONZE_L, BRONZE_M, BRONZE_D, false)
	return _tex_style(img, 12, 10, "title")

static func ui_button(state: String) -> StyleBoxTexture:
	var key := "btn_" + state
	if _sty.has(key):
		return _sty[key]
	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var top := Color(0.30, 0.19, 0.12)
	var bot := Color(0.13, 0.075, 0.055)
	var light := BRONZE_L
	var mid := BRONZE_M
	var dark := BRONZE_D
	var inset := false
	match state:
		"hover":
			top = Color(0.4, 0.25, 0.14)
			bot = Color(0.2, 0.11, 0.07)
		"pressed":
			top = Color(0.5, 0.14, 0.1)
			bot = Color(0.28, 0.06, 0.05)
			inset = true
		"disabled":
			top = Color(0.17, 0.15, 0.14)
			bot = Color(0.1, 0.09, 0.09)
			light = Color(0.4, 0.36, 0.3)
			mid = Color(0.28, 0.25, 0.2)
			dark = Color(0.14, 0.12, 0.1)
		"red":
			top = Color(0.62, 0.12, 0.1)
			bot = Color(0.3, 0.04, 0.04)
		"green":
			top = Color(0.16, 0.45, 0.2)
			bot = Color(0.06, 0.2, 0.09)
	for y in sz:
		var t := float(y) / float(sz)
		for x in sz:
			img.set_pixel(x, y, top.lerp(bot, t))
	_bevel_frame(img, sz, sz, 6, light, mid, dark, inset)
	return _tex_style(img, 12, 14, key)

static func ui_slot(sel: bool = false) -> StyleBoxTexture:
	var key := "slot_sel" if sel else "slot"
	if _sty.has(key):
		return _sty[key]
	var sz := 48
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for y in sz:
		for x in sz:
			var g := 0.05 + 0.03 * float(y) / float(sz)
			img.set_pixel(x, y, Color(g, g * 0.9, g * 0.8))
	if sel:
		_bevel_frame(img, sz, sz, 4, Color(1, 0.9, 0.5), Color(0.9, 0.7, 0.2), Color(0.5, 0.35, 0.05), false)
	else:
		_bevel_frame(img, sz, sz, 4, Color(0.1, 0.07, 0.04), Color(0.2, 0.14, 0.07), Color(0.55, 0.4, 0.2), true)
	var s := _tex_style(img, 6, 2, key)
	return s

static func ui_field() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.02, 0.015, 0.012, 0.95)
	s.border_color = BRONZE_M
	s.set_border_width_all(2)
	s.set_corner_radius_all(2)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s

# ================= raster kecil untuk ikon =================
static func _poly(img: Image, pts: Array, top: Color, bot: Color) -> void:
	var pv := PackedVector2Array(pts)
	var minx := 999.0
	var miny := 999.0
	var maxx := -999.0
	var maxy := -999.0
	for p in pv:
		minx = minf(minx, p.x)
		miny = minf(miny, p.y)
		maxx = maxf(maxx, p.x)
		maxy = maxf(maxy, p.y)
	for y in range(maxi(0, int(miny)), mini(img.get_height(), int(maxy) + 1)):
		var t := (float(y) - miny) / maxf(1.0, maxy - miny)
		for x in range(maxi(0, int(minx)), mini(img.get_width(), int(maxx) + 1)):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pv):
				img.set_pixel(x, y, top.lerp(bot, t))

static func _disc(img: Image, cx: float, cy: float, r: float, top: Color, bot: Color) -> void:
	for y in range(maxi(0, int(cy - r)), mini(img.get_height(), int(cy + r) + 1)):
		for x in range(maxi(0, int(cx - r)), mini(img.get_width(), int(cx + r) + 1)):
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			if d <= r:
				var t := (float(y) - (cy - r)) / (2.0 * r)
				var c := top.lerp(bot, clampf(t, 0.0, 1.0))
				img.set_pixel(x, y, c.lightened(0.25 * (1.0 - d / r) * 0.5))

static func _outline(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.1:
				continue
			var near := false
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1)]:
				var nx: int = x + o.x
				var ny: int = y + o.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.5:
					near = true
					break
			if near:
				img.set_pixel(x, y, Color(0.02, 0.01, 0.01, 0.95))

static func item_icon(slot: String, tier: int, plus: int = 0) -> ImageTexture:
	var pal := palette(tier)
	var key := "%s|%s|%d" % [slot, pal.name, plus > 0]
	if _ico.has(key):
		return _ico[key]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var m: Color = pal.main
	var d: Color = pal.dark
	var tr: Color = pal.trim
	var gl: Color = pal.glow
	if slot == "weapon":
		# senapan panjang diagonal ala gun Human
		_poly(img, [Vector2(8, 46), Vector2(18, 40), Vector2(24, 46), Vector2(14, 54)], d.darkened(0.1), d.darkened(0.3))
		_poly(img, [Vector2(16, 40), Vector2(40, 30), Vector2(46, 36), Vector2(24, 48)], m.lightened(0.1), d)
		_poly(img, [Vector2(36, 26), Vector2(56, 14), Vector2(58, 19), Vector2(40, 33)], tr, d)
		_poly(img, [Vector2(28, 33), Vector2(36, 29), Vector2(38, 33), Vector2(30, 37)], gl, gl.darkened(0.3))
		_poly(img, [Vector2(22, 44), Vector2(28, 41), Vector2(30, 52), Vector2(24, 54)], d, d.darkened(0.4))
	else:
		# zirah dada + bahu
		_poly(img, [Vector2(10, 18), Vector2(22, 10), Vector2(42, 10), Vector2(54, 18), Vector2(50, 30), Vector2(40, 26), Vector2(24, 26), Vector2(14, 30)], tr, d)
		_poly(img, [Vector2(20, 22), Vector2(44, 22), Vector2(46, 54), Vector2(32, 58), Vector2(18, 54)], m.lightened(0.08), d)
		_poly(img, [Vector2(26, 12), Vector2(32, 20), Vector2(38, 12)], INK, INK)
		_disc(img, 32.0, 32.0, 5.0, gl, gl.darkened(0.35))
		_poly(img, [Vector2(20, 46), Vector2(44, 46), Vector2(43, 52), Vector2(21, 52)], tr, tr.darkened(0.4))
	if plus > 0:
		_disc(img, 52.0, 52.0, 8.0, Color(1, 0.85, 0.2), Color(0.7, 0.4, 0.0))
	_outline(img)
	var t := ImageTexture.create_from_image(img)
	_ico[key] = t
	return t

static func stack_icon(id: String) -> ImageTexture:
	var key := "st_" + id
	if _ico.has(key):
		return _ico[key]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match id:
		"hp", "mp":
			var col := Color(0.95, 0.15, 0.15) if id == "hp" else Color(0.2, 0.45, 1.0)
			_poly(img, [Vector2(26, 6), Vector2(38, 6), Vector2(38, 18), Vector2(48, 30), Vector2(48, 54), Vector2(16, 54), Vector2(16, 30), Vector2(26, 18)], Color(0.75, 0.82, 0.85), Color(0.4, 0.45, 0.5))
			_poly(img, [Vector2(19, 34), Vector2(45, 34), Vector2(45, 52), Vector2(19, 52)], col.lightened(0.2), col.darkened(0.3))
			_poly(img, [Vector2(24, 2), Vector2(40, 2), Vector2(40, 8), Vector2(24, 8)], Color(0.6, 0.4, 0.2), Color(0.35, 0.2, 0.08))
		"tp", "warp":
			var col2 := Color(0.9, 0.85, 0.65) if id == "tp" else Color(0.75, 0.55, 0.95)
			_poly(img, [Vector2(12, 16), Vector2(52, 16), Vector2(52, 48), Vector2(12, 48)], col2.lightened(0.15), col2.darkened(0.25))
			_poly(img, [Vector2(8, 12), Vector2(16, 12), Vector2(16, 52), Vector2(8, 52)], Color(0.7, 0.5, 0.25), Color(0.4, 0.25, 0.1))
			_poly(img, [Vector2(48, 12), Vector2(56, 12), Vector2(56, 52), Vector2(48, 52)], Color(0.7, 0.5, 0.25), Color(0.4, 0.25, 0.1))
			_poly(img, [Vector2(22, 26), Vector2(42, 26), Vector2(42, 30), Vector2(22, 30)], Color(0.6, 0.15, 0.1), Color(0.6, 0.15, 0.1))
		"gem":
			_poly(img, [Vector2(32, 8), Vector2(50, 22), Vector2(32, 56), Vector2(14, 22)], Color(0.8, 0.6, 1.0), Color(0.35, 0.15, 0.6))
			_poly(img, [Vector2(32, 8), Vector2(38, 22), Vector2(32, 56), Vector2(26, 22)], Color(1, 1, 1, 0.5), Color(0.8, 0.6, 1.0, 0.1))
		"aeth4", "aeth3", "aeth2", "aeth1":
			var cols := {"aeth4": Color(0.5, 0.8, 1.0), "aeth3": Color(0.5, 1.0, 0.6), "aeth2": Color(1.0, 0.75, 0.3), "aeth1": Color(1.0, 0.35, 0.5)}
			var jc: Color = cols[id]
			_poly(img, [Vector2(32, 6), Vector2(54, 28), Vector2(32, 58), Vector2(10, 28)], jc.lightened(0.3), jc.darkened(0.3))
			_poly(img, [Vector2(10, 28), Vector2(54, 28), Vector2(32, 36)], Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.05))
		"safety":
			_disc(img, 32.0, 32.0, 22.0, Color(0.6, 0.65, 0.75), Color(0.25, 0.28, 0.35))
			_disc(img, 32.0, 32.0, 10.0, Color(0.3, 0.9, 1.0), Color(0.1, 0.4, 0.6))
		"w50", "w100":
			var wc := Color(0.7, 0.8, 0.95) if id == "w50" else Color(1.0, 0.8, 0.3)
			_poly(img, [Vector2(32, 6), Vector2(54, 14), Vector2(50, 40), Vector2(32, 58), Vector2(14, 40), Vector2(10, 14)], wc.lightened(0.15), wc.darkened(0.35))
			_poly(img, [Vector2(30, 18), Vector2(34, 18), Vector2(34, 44), Vector2(30, 44)], INK, INK)
		"capsule":
			_poly(img, [Vector2(10, 24), Vector2(32, 24), Vector2(32, 42), Vector2(10, 42)], Color(1.0, 0.85, 0.2), Color(0.8, 0.5, 0.1))
			_poly(img, [Vector2(32, 24), Vector2(54, 24), Vector2(54, 42), Vector2(32, 42)], Color(0.95, 0.95, 1.0), Color(0.6, 0.65, 0.8))
			_disc(img, 10.0, 33.0, 9.0, Color(1.0, 0.85, 0.2), Color(0.8, 0.5, 0.1))
			_disc(img, 54.0, 33.0, 9.0, Color(0.95, 0.95, 1.0), Color(0.6, 0.65, 0.8))
		_:
			_disc(img, 32.0, 32.0, 20.0, Color(0.7, 0.7, 0.7), Color(0.3, 0.3, 0.3))
	_outline(img)
	var t := ImageTexture.create_from_image(img)
	_ico[key] = t
	return t


static func make_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 26
	for st in ["normal", "hover", "pressed", "disabled"]:
		th.set_stylebox(st, "Button", ui_button(st))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_stylebox("panel", "PanelContainer", ui_panel())
	th.set_stylebox("normal", "LineEdit", ui_field())
	th.set_stylebox("focus", "LineEdit", ui_field())
	th.set_color("font_color", "Button", Color(0.97, 0.9, 0.72))
	th.set_color("font_hover_color", "Button", Color(1, 1, 0.85))
	th.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	th.set_color("font_disabled_color", "Button", Color(0.5, 0.46, 0.4))
	th.set_color("font_color", "Label", Color(0.93, 0.9, 0.82))
	th.set_color("font_color", "LineEdit", Color(1, 0.95, 0.8))
	th.set_color("caret_color", "LineEdit", Color(1, 0.85, 0.4))
	th.set_color("font_placeholder_color", "LineEdit", Color(0.55, 0.5, 0.42))
	th.set_font_size("font_size", "LineEdit", 30)
	return th
