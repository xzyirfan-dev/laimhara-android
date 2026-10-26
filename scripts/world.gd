class_name GameWorld
extends Node3D

var player: Player
var cam: Camera3D
var env: Environment
var sun: DirectionalLight3D
var torch: OmniLight3D
var map: Dictionary = {}
var map_root: Node3D
var monsters: Array = []
var spawns: Array = []
var peace_c := Vector3.ZERO
var peace_r := 0.0
var npc_anims: Array = []
var _fx_t := 0.0
var _rng := RandomNumberGenerator.new()
const MAX_ACTIVE_WILD := 18
const MAX_ACTIVE_DUNGEON := 28
var cam_yaw := 0.0
var cam_pitch := 0.72
var cam_distance := 14.0

# tema tiap map: tekstur lantai, pohon, prop, cahaya  (diambil dari gaya map Laghaim: kota batu, hutan, gua, gurun, salju, dimensi)
const THEME := {
	0: {"g": "tiles", "base": Color(0.3, 0.25, 0.21), "grout": Color(0.1, 0.08, 0.07), "tile": 8.0, "sun": Color(1.0, 0.93, 0.8), "e": 1.15, "amb": 0.6},
	1: {"g": "noise", "base": Color(0.3, 0.55, 0.24), "spk": Color(0.55, 0.75, 0.3), "tile": 7.0, "sun": Color(1.0, 0.96, 0.85), "e": 1.15, "amb": 0.6},
	2: {"g": "noise", "base": Color(0.14, 0.32, 0.17), "spk": Color(0.06, 0.18, 0.1), "tile": 7.0, "sun": Color(0.85, 1.0, 0.85), "e": 0.9, "amb": 0.5},
	3: {"g": "noise", "base": Color(0.42, 0.47, 0.36), "spk": Color(0.55, 0.58, 0.6), "tile": 7.0, "sun": Color(0.8, 0.85, 1.0), "e": 0.85, "amb": 0.55},
	4: {"g": "noise", "base": Color(0.2, 0.19, 0.24), "spk": Color(0.35, 0.35, 0.45), "tile": 7.0, "sun": Color(0.6, 0.65, 1.0), "e": 0.45, "amb": 0.35, "torch": Color(1.0, 0.65, 0.3)},
	5: {"g": "noise", "base": Color(0.86, 0.75, 0.5), "spk": Color(0.7, 0.58, 0.35), "tile": 7.0, "sun": Color(1.0, 0.95, 0.8), "e": 1.3, "amb": 0.65},
	6: {"g": "noise", "base": Color(0.12, 0.32, 0.24), "spk": Color(0.3, 0.7, 0.45), "tile": 7.0, "sun": Color(0.8, 1.0, 0.9), "e": 0.8, "amb": 0.5},
	7: {"g": "tiles", "base": Color(0.27, 0.22, 0.3), "grout": Color(0.06, 0.04, 0.08), "tile": 8.0, "sun": Color(0.75, 0.6, 1.0), "e": 0.6, "amb": 0.4, "torch": Color(0.7, 0.4, 1.0)},
	8: {"g": "noise", "base": Color(0.5, 0.27, 0.21), "spk": Color(1.0, 0.5, 0.15), "tile": 7.0, "sun": Color(1.0, 0.7, 0.5), "e": 1.0, "amb": 0.5, "torch": Color(1.0, 0.45, 0.15)},
	9: {"g": "noise", "base": Color(0.9, 0.93, 0.98), "spk": Color(0.65, 0.78, 0.95), "tile": 7.0, "sun": Color(0.9, 0.95, 1.0), "e": 1.2, "amb": 0.7},
	10: {"g": "tiles", "base": Color(0.14, 0.07, 0.22), "grout": Color(0.6, 0.2, 0.85), "tile": 8.0, "sun": Color(0.8, 0.5, 1.0), "e": 0.5, "amb": 0.4, "torch": Color(0.9, 0.3, 1.0)},
}

func _ready() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.fog_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 38, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 38.0
	sun.shadow_bias = 0.06
	add_child(sun)
	cam = Camera3D.new()
	cam.fov = 52
	cam.far = 220
	add_child(cam)
	player = Player.new()
	player.world = self
	add_child(player)
	torch = OmniLight3D.new()
	torch.omni_range = 11.0
	torch.light_energy = 0.0
	torch.position = Vector3(0, 2.6, 0)
	player.add_child(torch)
	G.leveled.connect(fx_levelup)
	load_map(G.map_id)

func _mat(c: Color, emissive: bool = false) -> StandardMaterial3D:
	return Gfx.mat(c, emissive)

func in_peace(p: Vector3) -> bool:
	return peace_r > 0.0 and Vector3(p.x, 0, p.z).distance_to(peace_c) < peace_r

func load_map(id: int, dungeon_mode: bool = false) -> void:
	if map_root != null:
		map_root.queue_free()
	monsters.clear()
	spawns.clear()
	npc_anims.clear()
	map_root = Node3D.new()
	add_child(map_root)
	G.map_id = id
	if not G.visited.has(id):
		G.visited.append(id)
	map = Data.dungeon_for(id) if dungeon_mode else Data.MAPS[id].duplicate(true)
	var th: Dictionary = THEME[id]
	var sky: Color = map.sky
	var dark: bool = id == 4 or id == 7 or id == 10
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = sky.darkened(0.25) if not dark else sky.darkened(0.1)
	sm.sky_horizon_color = sky.lightened(0.15) if not dark else sky.lightened(0.05)
	sm.ground_horizon_color = sm.sky_horizon_color
	sm.ground_bottom_color = sky.darkened(0.4)
	sm.sun_angle_max = 25.0
	var skyr := Sky.new()
	skyr.sky_material = sm
	env.sky = skyr
	env.ambient_light_color = sky.lerp(Color(0.85, 0.78, 0.7), 0.45)
	env.ambient_light_energy = float(th.amb) * 0.8
	env.fog_light_color = sm.sky_horizon_color
	env.fog_density = 0.011 if not dark else 0.026
	sun.light_color = th.sun
	sun.light_energy = float(th.e) * 0.8
	if th.has("torch"):
		torch.light_color = th.torch
		torch.light_energy = 1.6
	else:
		torch.light_energy = 0.0
	var half := 45.0 if map.town else 60.0
	player.half = half - 2.0
	player.position = Vector3(0, 0, 4 if map.town else 0)
	player.dead = false
	_rng.seed = int(id) * 977 + 13
	_build_ground(half, th)
	if map.town:
		peace_r = 0.0
		_build_town(half)
	else:
		peace_c = Vector3(0, 0, -3)
		peace_r = 9.0
		_build_wild(id, half)
		_build_camp()
		_npc("Pedagang Camp", "camp", Vector3(5, 0, -3), Color(0.9, 0.7, 0.3))
		if map.get("dungeon", false):
			_npc("Pintu Keluar Dungeon", "dungeon_exit", Vector3(-5, 0, -3), Color(1.0, 0.35, 0.5))
		else:
			_npc("Warp Stone", "gate", Vector3(-5, 0, -3), Color(0.4, 0.8, 1.0))
			_npc("Gerbang Dungeon", "dungeon", Vector3(0, 0, -7), Color(0.8, 0.25, 0.9))
		_build_spawns(half)
		G.toast.emit("Zona tetap %s - monster Lv %d–%d" % [map.name, int(map.min), int(map.max)], true)
	if map.town:
		G.toast.emit("Kota Velamina - zona aman", false)
	G.save_game()

# ------------------------------------------------------------------ tanah
func _build_ground(half: float, th: Dictionary) -> void:
	var size := half * 2.0 + 90.0
	var tex: Texture2D
	if th.g == "tiles":
		tex = Gfx.tex_tiles(th.base, th.grout, 4, 0.03, "tiles%d" % int(map.id))
	else:
		tex = Gfx.tex_noise(th.base, 0.035, th.spk, 0.1, "noise%d" % int(map.id))
	var g := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 38
	var span := size * 0.5
	var step := size / float(steps)
	for z in range(steps):
		for x in range(steps):
			var x0 := -span + float(x) * step
			var z0 := -span + float(z) * step
			var a := Vector3(x0, _terrain_height(x0, z0, half), z0)
			var b := Vector3(x0 + step, _terrain_height(x0 + step, z0, half), z0)
			var c := Vector3(x0 + step, _terrain_height(x0 + step, z0 + step, half), z0 + step)
			var d := Vector3(x0, _terrain_height(x0, z0 + step, half), z0 + step)
			var uv_a := Vector2(float(x) / steps, float(z) / steps) * float(th.tile)
			var uv_b := Vector2(float(x + 1) / steps, float(z) / steps) * float(th.tile)
			var uv_c := Vector2(float(x + 1) / steps, float(z + 1) / steps) * float(th.tile)
			var uv_d := Vector2(float(x) / steps, float(z + 1) / steps) * float(th.tile)
			var n1 := (b - a).cross(c - a).normalized()
			st.set_normal(n1); st.set_uv(uv_a); st.add_vertex(a)
			st.set_normal(n1); st.set_uv(uv_b); st.add_vertex(b)
			st.set_normal(n1); st.set_uv(uv_c); st.add_vertex(c)
			var n2 := (c - a).cross(d - a).normalized()
			st.set_normal(n2); st.set_uv(uv_a); st.add_vertex(a)
			st.set_normal(n2); st.set_uv(uv_c); st.add_vertex(c)
			st.set_normal(n2); st.set_uv(uv_d); st.add_vertex(d)
	g.mesh = st.commit()
	g.material_override = Gfx.ground_material(tex, size, float(th.tile))
	map_root.add_child(g)
	_build_river(size, half, int(map.id))
	if map.get("dungeon", false):
		_build_dungeon_ridges(size, half, int(map.id))

func _terrain_height(x: float, z: float, half: float) -> float:
	var id := int(map.id)
	if map.get("town", false):
		return sin(x * 0.035 + id) * 0.12 + cos(z * 0.04) * 0.1
	var h := sin(x * 0.075 + float(id) * 1.7) * cos(z * 0.055) * 1.7
	h += sin((x + z) * 0.14 + float(id)) * 0.55
	if map.get("dungeon", false):
		var lane_axis: float = z if id % 2 == 0 else x
		var lane_curve: float = sin(lane_axis * 0.045 + float(id)) * 7.0
		var lane_offset: float = abs((x if id % 2 == 0 else z) - lane_curve)
		var wall_factor: float = clampf((lane_offset - 6.0) / 5.0, 0.0, 1.0)
		h += wall_factor * wall_factor * 4.5
		h -= exp(-pow(lane_offset / 4.5, 2.0)) * 0.8
		h += sin(x * 0.19 + z * 0.13) * wall_factor * 0.7
	var ridge: float = abs(sin(x * 0.035 + z * 0.021 + float(id)))
	h += pow(ridge, 5.0) * (2.0 if id != 5 else 1.1)
	var edge: float = clampf((maxf(abs(x), abs(z)) - half * 0.7) / (half * 0.3), 0.0, 1.0)
	h += edge * edge * 2.8
	var river_axis: float = x if id % 2 == 0 else z
	var river_curve: float = sin((x if id % 2 == 0 else z) * 0.055 + float(id)) * 5.0
	var river_dist: float = abs((z if id % 2 == 0 else x) - river_curve)
	if river_dist < 4.5:
		h -= (4.5 - river_dist) * 0.55
	if id == 4 or id == 7:
		h -= abs(sin(x * 0.12) * cos(z * 0.09)) * 0.8
	if id == 8:
		h += sin(x * 0.09) * 0.6
	return h

func _build_dungeon_ridges(size: float, half: float, id: int) -> void:
	var ridge_xf: Array = []
	var crystal_xf: Array = []
	var count := int(size / 7.0)
	for i in count:
		var along := -size * 0.5 + float(i) * 7.0
		var curve := sin(along * 0.045 + float(id)) * 7.0
		for side in [-1.0, 1.0]:
			var cross: float = curve + side * 8.0
			var p := Vector3(along, 0, cross) if id % 2 == 0 else Vector3(cross, 0, along)
			var h: float = 2.0 + abs(sin(along * 0.17 + float(id))) * 3.5
			ridge_xf.append(_tf(p + Vector3(0, h * 0.5, 0), Vector3(1.5, h, 1.5), _rng.randf() * TAU))
			if id == 4 or id == 7 or id == 10:
				crystal_xf.append(_tf(p + Vector3(0, h + 0.5, 0), Vector3(0.5, 1.2, 0.5), _rng.randf() * TAU))
	_mm(_spm(1.0, 1.0, 7), Color(0.22, 0.2, 0.24), ridge_xf)
	if not crystal_xf.is_empty():
		var glow := Color(0.35, 0.6, 1.0) if id == 4 else Color(0.8, 0.25, 1.0)
		_mm(_cone(0.8, 1.8, 6), glow, crystal_xf, true)

func _build_river(size: float, half: float, id: int) -> void:
	if map.get("town", false):
		return
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5.0, size * 1.2)
	water.mesh = pm
	water.position.y = -1.35
	if id % 2 == 0:
		water.rotation.y = PI * 0.5
	var col := Color(0.12, 0.5, 0.8, 0.72)
	if id == 4 or id == 7:
		col = Color(0.35, 0.18, 0.8, 0.75)
	if id == 8:
		col = Color(1.0, 0.16, 0.03, 0.85)
	if id == 10:
		col = Color(0.75, 0.08, 0.95, 0.78)
	water.material_override = Gfx.mat(col, true, 0.55)
	map_root.add_child(water)
	var banks: Array = []
	var count := int(size / 8.0)
	for i in count:
		var along := -size * 0.5 + float(i) * 8.0
		var curve := sin(along * 0.055 + float(id)) * 5.0
		var p1 := Vector3(along, -0.35, curve + 3.5) if id % 2 == 0 else Vector3(curve + 3.5, -0.35, along)
		var p2 := Vector3(along, -0.35, curve - 3.5) if id % 2 == 0 else Vector3(curve - 3.5, -0.35, along)
		banks.append(_tf(p1, Vector3(0.7, 0.7, 1.8), _rng.randf() * TAU))
		banks.append(_tf(p2, Vector3(0.7, 0.7, 1.8), _rng.randf() * TAU))
	_mm(_spm(1.0, 0.7, 6), Color(0.22, 0.26, 0.3), banks)

# ------------------------------------------------------------------ util scatter
func _tf(p: Vector3, s: Vector3, yaw: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(s), p)

func _mm(mesh: Mesh, col: Color, xf: Array, emis: bool = false) -> void:
	if xf.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = Gfx.mat(col, emis, 0.9)
	map_root.add_child(mi)

func _free_pos(half: float, r_min: float = 12.0, margin: float = 3.0) -> Vector3:
	for i in 20:
		var p := Vector3(_rng.randf_range(-half + margin, half - margin), 0, _rng.randf_range(-half + margin, half - margin))
		if p.length() > r_min:
			return p
	return Vector3(half - margin, 0, half - margin)

func _ring_pos(half: float, off: float) -> Vector3:
	var t := _rng.randf() * 4.0
	var side := int(t)
	var u := (t - float(side)) * 2.0 - 1.0
	var e := half + off + _rng.randf_range(0.0, 5.0)
	match side:
		0: return Vector3(u * (half + 6.0), 0, -e)
		1: return Vector3(u * (half + 6.0), 0, e)
		2: return Vector3(-e, 0, u * (half + 6.0))
	return Vector3(e, 0, u * (half + 6.0))

func _cone(r: float, h: float, seg: int = 7) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = r
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

func _cylm(rt: float, rb: float, h: float, seg: int = 7) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

func _spm(r: float, sq: float = 1.0, seg: int = 9) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 * sq
	s.radial_segments = seg
	s.rings = maxi(3, seg / 2)
	return s

func _trees(n: int, half: float, kind: String, trunk: Color, crown: Color, smin: float = 0.9, smax: float = 1.7, border: bool = false) -> void:
	var tr: Array = []
	var c1: Array = []
	var c2: Array = []
	var c3: Array = []
	for i in n:
		var p := _ring_pos(half, 1.5) if border else _free_pos(half)
		var s := _rng.randf_range(smin, smax) * (1.5 if border else 1.0)
		var yaw := _rng.randf() * TAU
		match kind:
			"round":
				tr.append(_tf(p + Vector3(0, 1.1 * s, 0), Vector3(s, s, s)))
				c1.append(_tf(p + Vector3(0, 3.0 * s, 0), Vector3(s, s * 0.9, s), yaw))
				c2.append(_tf(p + Vector3(0.7 * s, 2.5 * s, 0.3 * s), Vector3(s * 0.7, s * 0.7, s * 0.7)))
			"pine":
				tr.append(_tf(p + Vector3(0, 0.8 * s, 0), Vector3(s * 0.8, s * 0.8, s * 0.8)))
				c1.append(_tf(p + Vector3(0, 2.0 * s, 0), Vector3(s, s, s), yaw))
				c2.append(_tf(p + Vector3(0, 3.1 * s, 0), Vector3(s * 0.75, s * 0.9, s * 0.75), yaw))
				c3.append(_tf(p + Vector3(0, 4.1 * s, 0), Vector3(s * 0.5, s * 0.8, s * 0.5), yaw))
			"dead":
				tr.append(_tf(p + Vector3(0, 1.6 * s, 0), Vector3(s * 1.1, s * 1.6, s * 1.1), yaw))
				c1.append(_tf(p + Vector3(0.5 * s, 3.2 * s, 0), Vector3(s * 0.4, s * 1.2, s * 0.4), yaw + 0.8))
				c2.append(_tf(p + Vector3(-0.5 * s, 2.6 * s, 0.2), Vector3(s * 0.3, s * 1.0, s * 0.3), yaw - 0.9))
			"jungle":
				tr.append(_tf(p + Vector3(0, 1.8 * s, 0), Vector3(s * 1.5, s * 1.8, s * 1.5)))
				c1.append(_tf(p + Vector3(0, 4.6 * s, 0), Vector3(s * 1.5, s * 0.7, s * 1.5), yaw))
				c2.append(_tf(p + Vector3(1.0 * s, 4.0 * s, 0.6 * s), Vector3(s, s * 0.6, s), yaw))
				c3.append(_tf(p + Vector3(-1.0 * s, 3.8 * s, -0.5 * s), Vector3(s * 0.9, s * 0.6, s * 0.9), yaw))
			"gold":
				tr.append(_tf(p + Vector3(0, 1.3 * s, 0), Vector3(s, s, s)))
				c1.append(_tf(p + Vector3(0, 3.2 * s, 0), Vector3(s, s * 0.9, s), yaw))
				c2.append(_tf(p + Vector3(0.9 * s, 2.7 * s, 0.4 * s), Vector3(s * 0.7, s * 0.7, s * 0.7)))
				c3.append(_tf(p + Vector3(-0.8 * s, 2.9 * s, -0.3 * s), Vector3(s * 0.7, s * 0.7, s * 0.7)))
	if kind == "round" or kind == "gold" or kind == "jungle":
		_mm(_cylm(0.2, 0.32, 2.2 if kind != "jungle" else 3.6, 6), trunk, tr)
		_mm(_spm(1.5, 0.85), crown, c1)
		_mm(_spm(1.5, 0.85), crown.lightened(0.12), c2)
		_mm(_spm(1.5, 0.85), crown.darkened(0.12), c3)
	elif kind == "pine":
		_mm(_cylm(0.18, 0.3, 1.6, 6), trunk, tr)
		_mm(_cone(1.5, 2.2, 8), crown, c1)
		_mm(_cone(1.5, 2.0, 8), crown.lightened(0.06), c2)
		_mm(_cone(1.5, 1.8, 8), crown.lightened(0.12), c3)
	else:
		_mm(_cylm(0.1, 0.3, 3.2, 5), trunk, tr)
		_mm(_cylm(0.04, 0.12, 2.4, 4), trunk, c1)
		_mm(_cylm(0.04, 0.12, 2.0, 4), trunk, c2)

func _rocks(n: int, half: float, col: Color, kind: String = "rock", border: bool = false, smin: float = 0.6, smax: float = 1.8, emis: bool = false) -> void:
	var xf: Array = []
	var xf2: Array = []
	for i in n:
		var p := _ring_pos(half, 1.0) if border else _free_pos(half, 11.0)
		var s := _rng.randf_range(smin, smax) * (1.6 if border else 1.0)
		var yaw := _rng.randf() * TAU
		match kind:
			"rock":
				xf.append(_tf(p + Vector3(0, 0.25 * s, 0), Vector3(s, s * 0.7, s * 1.1), yaw))
			"spire":
				var hh := s * _rng.randf_range(2.5, 4.5)
				xf.append(_tf(p + Vector3(0, hh * 0.5, 0), Vector3(s * 0.8, hh, s * 0.8), yaw))
			"crystal":
				var hc := s * _rng.randf_range(1.4, 2.6)
				xf.append(_tf(p + Vector3(0, hc * 0.5, 0), Vector3(s * 0.55, hc, s * 0.55), yaw))
				xf2.append(_tf(p + Vector3(0.5 * s, hc * 0.3, 0.2 * s), Vector3(s * 0.35, hc * 0.6, s * 0.35), yaw + 0.5))
			"tomb":
				xf.append(_tf(p + Vector3(0, 0.6 * s, 0), Vector3(0.7 * s, 1.2 * s, 0.25 * s), yaw))
				xf2.append(_tf(p + Vector3(0, 1.25 * s, 0), Vector3(0.8 * s, 0.25 * s, 0.3 * s), yaw))
			"pillar":
				xf.append(_tf(p + Vector3(0, 2.0 * s, 0), Vector3(s * 0.9, s * 4.0 / 2.0, s * 0.9), yaw))
				xf2.append(_tf(p + Vector3(0, 4.15 * s, 0), Vector3(s * 1.3, s * 0.3, s * 1.3), yaw))
	match kind:
		"rock":
			_mm(_spm(1.0, 1.0, 7), col, xf)
		"spire":
			_mm(_cone(1.0, 1.0, 6), col, xf)
		"crystal":
			_mm(_cone(0.7, 1.0, 5), col, xf, emis)
			_mm(_cone(0.7, 1.0, 5), col.lightened(0.2), xf2, emis)
		"tomb":
			var bm := BoxMesh.new()
			_mm(bm, col, xf)
			_mm(bm, col.lightened(0.1), xf2)
		"pillar":
			_mm(_cylm(0.6, 0.7, 2.0, 8), col, xf)
			var bm2 := BoxMesh.new()
			_mm(bm2, col.lightened(0.1), xf2)

func _flowers(n: int, half: float, cols: Array) -> void:
	for ci in cols.size():
		var xf: Array = []
		for i in n / cols.size():
			var p := _free_pos(half, 10.0)
			xf.append(_tf(p + Vector3(0, 0.18, 0), Vector3.ONE * _rng.randf_range(0.8, 1.3)))
		_mm(_spm(0.13, 1.0, 6), cols[ci], xf, true)
	var tuft: Array = []
	for i in n * 2:
		var p2 := _free_pos(half, 10.0)
		tuft.append(_tf(p2 + Vector3(0, 0.2, 0), Vector3(1, _rng.randf_range(0.8, 1.6), 1), _rng.randf() * TAU))
	_mm(_cone(0.22, 0.45, 4), Color(0.2, 0.5, 0.15), tuft)

func _pools(n: int, half: float, col: Color) -> void:
	for i in n:
		var p := _free_pos(half, 14.0)
		var d := MeshInstance3D.new()
		var cm := _cylm(1.0, 1.0, 0.05, 14)
		d.mesh = cm
		d.material_override = Gfx.mat(col, true)
		var s := _rng.randf_range(1.5, 3.5)
		d.position = p + Vector3(0, 0.03, 0)
		d.scale = Vector3(s, 1, s * _rng.randf_range(0.7, 1.2))
		map_root.add_child(d)

func _bones(n: int, half: float, col: Color) -> void:
	var xf: Array = []
	for i in n:
		var p := _free_pos(half, 10.0)
		xf.append(_tf(p + Vector3(0, 0.12, 0), Vector3(1, 1, _rng.randf_range(0.8, 1.6)), _rng.randf() * TAU))
	_mm(_cylm(0.08, 0.1, 1.2, 5), col, xf)

func _mushrooms(n: int, half: float) -> void:
	var st: Array = []
	var cp: Array = []
	for i in n:
		var p := _free_pos(half, 10.0)
		var s := _rng.randf_range(0.7, 2.0)
		st.append(_tf(p + Vector3(0, 0.3 * s, 0), Vector3(s, s, s)))
		cp.append(_tf(p + Vector3(0, 0.75 * s, 0), Vector3(s, s, s)))
	_mm(_cylm(0.1, 0.14, 0.6, 6), Color(0.9, 0.85, 0.75), st)
	_mm(_spm(0.45, 0.6, 8), Color(0.75, 0.2, 0.35), cp)

func _cacti(n: int, half: float) -> void:
	var tr: Array = []
	var arm: Array = []
	for i in n:
		var p := _free_pos(half, 10.0)
		var s := _rng.randf_range(0.8, 1.7)
		tr.append(_tf(p + Vector3(0, 1.0 * s, 0), Vector3(s, s, s)))
		arm.append(_tf(p + Vector3(0.45 * s, 1.3 * s, 0), Vector3(s, s, s)))
	_mm(_cylm(0.22, 0.25, 2.0, 7), Color(0.3, 0.55, 0.28), tr)
	_mm(_cylm(0.12, 0.12, 0.8, 6), Color(0.33, 0.58, 0.3), arm)

func _dunes(n: int, half: float, col: Color) -> void:
	var xf: Array = []
	for i in n:
		var p := _ring_pos(half, 2.0) if i % 2 == 0 else _free_pos(half, 16.0)
		var s := _rng.randf_range(3.0, 7.0)
		xf.append(_tf(p + Vector3(0, -s * 0.25, 0), Vector3(s, s * 0.45, s * 1.3), _rng.randf() * TAU))
	_mm(_spm(1.0, 1.0, 10), col, xf)

func _ruin_walls(n: int, half: float, col: Color) -> void:
	var xf: Array = []
	for i in n:
		var p := _free_pos(half, 15.0)
		var hh := _rng.randf_range(1.5, 4.0)
		xf.append(_tf(p + Vector3(0, hh * 0.5, 0), Vector3(_rng.randf_range(2.5, 6.0), hh, 0.8), _rng.randf() * TAU))
	var bm := BoxMesh.new()
	_mm(bm, col, xf)

func _sky_islands(n: int, half: float) -> void:
	var xf: Array = []
	var glow: Array = []
	for i in n:
		var p := _free_pos(half + 10.0, 12.0, 0.0)
		var y := _rng.randf_range(2.0, 6.0)
		var s := _rng.randf_range(0.6, 1.4)
		xf.append(_tf(p + Vector3(0, y, 0), Vector3(s, s * 1.5, s), _rng.randf() * TAU))
		glow.append(_tf(p + Vector3(0, y, 0), Vector3(s * 0.5, s * 0.8, s * 0.5)))
	_mm(_cone(0.5, 1.2, 4), Color(0.8, 0.3, 1.0), xf, true)
	_mm(_spm(0.35, 1.0, 6), Color(1.0, 0.9, 1.0), glow, true)

# ------------------------------------------------------------------ map liar
func _build_wild(id: int, half: float) -> void:
	match id:
		1:
			_trees(46, half, "round", Color(0.4, 0.28, 0.17), Color(0.2, 0.55, 0.2))
			_trees(60, half, "round", Color(0.4, 0.28, 0.17), Color(0.18, 0.5, 0.2), 1.0, 1.8, true)
			_rocks(18, half, Color(0.55, 0.55, 0.52))
			_flowers(120, half, [Color(1, 1, 1), Color(1, 0.85, 0.2), Color(1, 0.4, 0.6)])
			_dummies(half)
		2:
			_trees(90, half, "pine", Color(0.3, 0.2, 0.12), Color(0.1, 0.34, 0.18))
			_trees(70, half, "pine", Color(0.3, 0.2, 0.12), Color(0.08, 0.3, 0.16), 1.0, 1.8, true)
			_mushrooms(40, half)
			_rocks(14, half, Color(0.35, 0.38, 0.35))
		3:
			_rocks(26, half, Color(0.5, 0.52, 0.56), "spire", false, 0.8, 1.6)
			_rocks(50, half, Color(0.45, 0.47, 0.52), "spire", true, 1.0, 2.0)
			_trees(24, half, "dead", Color(0.3, 0.25, 0.22), Color(0.3, 0.25, 0.22))
			_rocks(20, half, Color(0.5, 0.52, 0.5))
		4:
			_rocks(40, half, Color(0.3, 0.28, 0.35), "spire", false, 0.6, 1.5)
			_rocks(60, half, Color(0.24, 0.22, 0.3), "spire", true, 1.2, 2.2)
			_rocks(26, half, Color(0.35, 0.6, 1.0), "crystal", false, 0.5, 1.2, true)
			_bones(24, half, Color(0.85, 0.82, 0.72))
		5:
			_dunes(36, half, Color(0.9, 0.78, 0.52))
			_cacti(30, half)
			_rocks(18, half, Color(0.72, 0.58, 0.4), "rock", false, 0.8, 2.0)
			_rocks(30, half, Color(0.75, 0.6, 0.4), "pillar", false, 0.8, 1.3)
			_bones(18, half, Color(0.95, 0.92, 0.82))
		6:
			_trees(70, half, "jungle", Color(0.28, 0.2, 0.14), Color(0.12, 0.42, 0.26))
			_trees(70, half, "jungle", Color(0.25, 0.18, 0.12), Color(0.1, 0.36, 0.22), 1.0, 1.6, true)
			_rocks(30, half, Color(0.4, 0.95, 0.65), "crystal", false, 0.4, 0.9, true)
			_mushrooms(24, half)
		7:
			_ruin_walls(24, half, Color(0.33, 0.28, 0.36))
			_rocks(50, half, Color(0.4, 0.36, 0.44), "tomb", false, 0.8, 1.4)
			_trees(30, half, "dead", Color(0.2, 0.16, 0.2), Color(0.2, 0.16, 0.2))
			_rocks(26, half, Color(0.38, 0.34, 0.42), "pillar", false, 0.7, 1.2)
			_rocks(50, half, Color(0.3, 0.26, 0.34), "pillar", true, 1.2, 2.0)
			_rocks(18, half, Color(0.75, 0.4, 1.0), "crystal", false, 0.4, 0.9, true)
		8:
			_rocks(36, half, Color(0.5, 0.25, 0.2), "spire", false, 0.9, 1.8)
			_rocks(60, half, Color(0.42, 0.2, 0.17), "spire", true, 1.4, 2.4)
			_pools(14, half, Color(1.0, 0.4, 0.08))
			_rocks(22, half, Color(0.3, 0.17, 0.15))
			_bones(14, half, Color(0.9, 0.85, 0.75))
		9:
			_trees(44, half, "pine", Color(0.35, 0.28, 0.22), Color(0.82, 0.9, 0.95))
			_trees(60, half, "pine", Color(0.35, 0.28, 0.22), Color(0.78, 0.88, 0.95), 1.0, 1.8, true)
			_rocks(28, half, Color(0.65, 0.88, 1.0), "crystal", false, 0.6, 1.4, true)
			_rocks(18, half, Color(0.85, 0.9, 0.95))
			_dunes(14, half, Color(0.95, 0.97, 1.0))
		10:
			_rocks(30, half, Color(0.8, 0.3, 1.0), "crystal", false, 0.7, 1.5, true)
			_rocks(50, half, Color(0.55, 0.15, 0.85), "crystal", true, 1.4, 2.4, true)
			_rocks(20, half, Color(0.2, 0.1, 0.3), "pillar", false, 0.8, 1.3)
			_sky_islands(26, half)
			_pools(10, half, Color(0.7, 0.2, 1.0))

func _dummies(half: float) -> void:
	for i in 6:
		var p := _free_pos(half, 15.0)
		var n := Node3D.new()
		n.position = p
		Gfx.cyl(n, 0.1, 0.12, 1.6, Vector3(0, 0.8, 0), Color(0.5, 0.35, 0.2), false, 6)
		Gfx.box(n, Vector3(1.0, 0.12, 0.12), Vector3(0, 1.3, 0), Color(0.5, 0.35, 0.2))
		Gfx.sph(n, 0.28, Vector3(0, 1.8, 0), Color(0.85, 0.7, 0.4))
		Gfx.cyl(n, 0.3, 0.3, 0.06, Vector3(0, 1.0, 0.14), Color(0.8, 0.15, 0.12), false, 12).rotation.x = PI / 2.0
		map_root.add_child(n)

# ------------------------------------------------------------------ camp (zona aman di map berburu)
func _build_camp() -> void:
	var tex := Gfx.tex_tiles(Color(0.42, 0.38, 0.33), Color(0.12, 0.1, 0.08), 4, 0.03, "camp")
	var d := MeshInstance3D.new()
	var cm := _cylm(9.0, 9.0, 0.1, 40)
	d.mesh = cm
	d.material_override = Gfx.tex_material(tex, Vector3(4, 4, 1))
	d.position = Vector3(peace_c.x, 0.05, peace_c.z)
	map_root.add_child(d)
	var tm := Gfx.ring(map_root, 8.7, 9.2, Vector3(peace_c.x, 0.13, peace_c.z), Color(1.0, 0.8, 0.3))
	tm.scale = Vector3(1, 0.3, 1)
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3
		var tp := Vector3(peace_c.x + cos(a) * 8.6, 0, peace_c.z + sin(a) * 8.6)
		Gfx.cyl(map_root, 0.08, 0.1, 1.8, tp + Vector3(0, 0.9, 0), Color(0.35, 0.22, 0.12), false, 6)
		Gfx.sph(map_root, 0.22, tp + Vector3(0, 1.9, 0), Color(1.0, 0.6, 0.15), true, Vector3(0.8, 1.4, 0.8))
	# api unggun
	Gfx.cyl(map_root, 0.5, 0.6, 0.18, Vector3(peace_c.x, 0.1, peace_c.z + 3.5), Color(0.3, 0.28, 0.27), false, 10)
	Gfx.cyl(map_root, 0.0, 0.32, 0.9, Vector3(peace_c.x, 0.65, peace_c.z + 3.5), Color(1.0, 0.5, 0.12), true, 6)
	Gfx.cyl(map_root, 0.0, 0.2, 0.6, Vector3(peace_c.x, 0.55, peace_c.z + 3.5), Color(1.0, 0.85, 0.3), true, 6)

# ------------------------------------------------------------------ kota
func _house(pos: Vector3, yaw: float, wall: Color, roof: Color) -> void:
	var h := Node3D.new()
	h.position = pos
	h.rotation.y = yaw
	var bt := Gfx.tex_brick(wall.darkened(0.1), wall.darkened(0.55), "brickh%s" % wall.to_html())
	var body := Gfx.box(h, Vector3(7, 4, 6), Vector3(0, 2, 0), wall)
	body.material_override = Gfx.tex_material(bt, Vector3(1.6, 1.0, 1))
	var rf := Gfx.prism(h, Vector3(8.4, 3.0, 7.2), Vector3(0, 5.5, 0), roof)
	rf.rotation.y = 0.0
	Gfx.box(h, Vector3(1.3, 2.3, 0.2), Vector3(0, 1.15, 3.05), Color(0.3, 0.18, 0.1))
	for sx in [-2.3, 2.3]:
		Gfx.box(h, Vector3(1.0, 1.0, 0.15), Vector3(sx, 2.4, 3.05), Color(1.0, 0.85, 0.4), true)
		Gfx.box(h, Vector3(1.2, 0.12, 0.25), Vector3(sx, 1.85, 3.1), Color(0.35, 0.22, 0.12))
	Gfx.box(h, Vector3(0.9, 2.0, 0.9), Vector3(2.4, 5.8, -1.2), Color(0.4, 0.38, 0.38))
	map_root.add_child(h)

func _build_town(half: float) -> void:
	# alun-alun batu + dinding bata + menara (lantai ubin & tembok seperti screenshot kota Biosfear)
	var bt := Gfx.tex_brick(Color(0.28, 0.33, 0.38), Color(0.08, 0.1, 0.12), "wallbrick")
	var wm := Gfx.tex_material(bt, Vector3(half / 3.0, 1.2, 1))
	var wh := 5.0
	for side in 4:
		var w := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(half * 2.0 + 4.0, wh, 1.6)
		w.mesh = bm
		w.material_override = wm
		var a := PI / 2.0 * float(side)
		w.position = Vector3(sin(a) * (half + 0.8), wh * 0.5, cos(a) * (half + 0.8))
		w.rotation.y = a
		map_root.add_child(w)
		# gigi benteng
		for k in 16:
			var cx := -half + 2.0 + float(k) * (half * 2.0 - 4.0) / 15.0
			var cr := Gfx.box(map_root, Vector3(1.4, 0.9, 1.9), Vector3.ZERO, Color(0.34, 0.39, 0.45))
			cr.position = Vector3(sin(a) * (half + 0.8), wh + 0.45, cos(a) * (half + 0.8)) + Vector3(cos(a) * cx, 0, -sin(a) * cx)
			cr.rotation.y = a
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tw := Vector3(sx * (half + 0.8), 0, sz * (half + 0.8))
			Gfx.cyl(map_root, 2.3, 2.6, 8.0, tw + Vector3(0, 4.0, 0), Color(0.33, 0.38, 0.44), false, 12)
			Gfx.cyl(map_root, 0.0, 3.0, 3.2, tw + Vector3(0, 9.4, 0), Color(0.2, 0.28, 0.6), false, 12)
			Gfx.sph(map_root, 0.3, tw + Vector3(0, 11.2, 0), Color(1.0, 0.85, 0.3), true)
	# gerbang selatan
	for sx in [-1.0, 1.0]:
		Gfx.box(map_root, Vector3(2.2, 7.0, 2.2), Vector3(7.0 * sx, 3.5, half + 0.8), Color(0.38, 0.43, 0.5))
		Gfx.box(map_root, Vector3(2.8, 0.5, 2.8), Vector3(7.0 * sx, 7.2, half + 0.8), Color(0.55, 0.5, 0.35))
		Gfx.sph(map_root, 0.4, Vector3(7.0 * sx, 7.8, half + 0.8), Color(1.0, 0.8, 0.3), true)
	Gfx.box(map_root, Vector3(12.0, 1.4, 2.0), Vector3(0, 6.4, half + 0.8), Color(0.36, 0.41, 0.48))
	# air mancur pusat
	Gfx.cyl(map_root, 4.4, 4.6, 0.5, Vector3(0, 0.25, 0), Color(0.5, 0.52, 0.56), false, 24)
	Gfx.cyl(map_root, 3.6, 3.6, 0.6, Vector3(0, 0.6, 0), Color(0.45, 0.47, 0.52), false, 24)
	var wt := Gfx.cyl(map_root, 3.3, 3.3, 0.05, Vector3(0, 0.88, 0), Color(0.3, 0.7, 1.0), true, 24)
	wt.material_override = Hero.glass(Color(0.3, 0.7, 1.0), 0.75, 0.9)
	Gfx.cyl(map_root, 0.35, 0.5, 2.4, Vector3(0, 1.8, 0), Color(0.55, 0.57, 0.62), false, 10)
	Gfx.sph(map_root, 0.55, Vector3(0, 3.1, 0), Color(0.5, 0.85, 1.0), true)
	# rumah
	var wall_cols := [Color(0.82, 0.74, 0.6), Color(0.7, 0.55, 0.45), Color(0.78, 0.78, 0.82), Color(0.65, 0.6, 0.5)]
	var roof_cols := [Color(0.65, 0.2, 0.15), Color(0.2, 0.3, 0.6), Color(0.3, 0.45, 0.3), Color(0.55, 0.3, 0.15)]
	for i in 8:
		var a2 := TAU * float(i) / 8.0 + 0.2
		var rr := 29.0
		_house(Vector3(cos(a2) * rr, 0, sin(a2) * rr), -a2 + PI * 0.5 + PI, wall_cols[i % 4], roof_cols[(i * 3) % 4])
	# pohon emas dalam pot batu (ala screenshot Biosfear)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_gold_tree(Vector3(sx * 17.0, 0, sz * 17.0))
	for i in 6:
		_gold_tree(Vector3(-36.0 + float(i) * 14.4, 0, -40.0))
	# lampu jalan & panji
	for i in 8:
		var a3 := TAU * float(i) / 8.0
		var lp := Vector3(cos(a3) * 14.5, 0, sin(a3) * 14.5)
		Gfx.cyl(map_root, 0.08, 0.12, 3.2, lp + Vector3(0, 1.6, 0), Color(0.15, 0.15, 0.17), false, 6, 0.4, 0.6)
		Gfx.sph(map_root, 0.3, lp + Vector3(0, 3.4, 0), Color(1.0, 0.85, 0.45), true)
		var bn := Gfx.box(map_root, Vector3(0.05, 1.2, 0.6), lp + Vector3(0.1, 2.5, 0.35), Color(0.7, 0.15, 0.12))
		bn.rotation.y = a3
	# NPC
	var list := [
		["Raja Tempa Dargan", "forge", Color(0.8, 0.3, 0.2)],
		["Senapan Sari", "shop_class", Color(0.3, 0.6, 0.9)],
		["Apoteker Rania", "shop_potion", Color(0.4, 0.8, 0.5)],
		["Pasar Campuran", "market", Color(0.8, 0.7, 0.4)],
		["Tukang Permata", "jewel", Color(0.7, 0.4, 0.9)],
		["Pedagang Karu", "karu", Color(0.9, 0.6, 0.2)],
		["Penjaga Gerbang", "gate", Color(0.4, 0.8, 1.0)],
		["Papan Misi", "quest", Color(0.9, 0.9, 0.5)],
	]
	for i in list.size():
		var a4 := TAU * float(i) / float(list.size())
		_npc(list[i][0], list[i][1], Vector3(cos(a4) * 9.0, 0, sin(a4) * 9.0), list[i][2])

func _gold_tree(p: Vector3) -> void:
	var n := Node3D.new()
	n.position = p
	var pt := Gfx.tex_tiles(Color(0.45, 0.47, 0.5), Color(0.14, 0.14, 0.16), 2, 0.03, "planter")
	var pot := Gfx.box(n, Vector3(2.6, 0.7, 2.6), Vector3(0, 0.35, 0), Color(0.5, 0.52, 0.55))
	pot.material_override = Gfx.tex_material(pt, Vector3(1, 1, 1))
	Gfx.box(n, Vector3(2.2, 0.1, 2.2), Vector3(0, 0.72, 0), Color(0.25, 0.17, 0.1))
	Gfx.cyl(n, 0.2, 0.32, 3.0, Vector3(0, 2.1, 0), Color(0.3, 0.3, 0.38), false, 7)
	for i in 7:
		var a := TAU * float(i) / 7.0
		var c := Color(0.95, 0.82, 0.18).lerp(Color(0.55, 0.75, 0.15), 0.45 if i % 3 == 0 else 0.0)
		Gfx.sph(n, 1.0, Vector3(cos(a) * 0.9, 3.5 + sin(float(i) * 2.0) * 0.3, sin(a) * 0.9), c, false, Vector3(1, 0.85, 1), 0.7)
	Gfx.sph(n, 1.2, Vector3(0, 4.2, 0), Color(1.0, 0.88, 0.2), false, Vector3(1, 0.8, 1), 0.7)
	map_root.add_child(n)

func _npc(title: String, kind: String, pos: Vector3, col: Color) -> void:
	var n := Node3D.new()
	n.position = pos
	n.add_to_group("npc")
	n.set_meta("title", title)
	n.set_meta("kind", kind)
	var built := Models.npc(kind, col)
	n.add_child(built.root)
	npc_anims.append(built.anim)
	var dir := Vector3(-pos.x, 0, -pos.z)
	if kind == "camp" or kind == "gate" and not map.town:
		dir = Vector3(0, 0, 1)
	if dir.length() > 0.1:
		built.root.rotation.y = atan2(dir.x, dir.z)
	var l := Label3D.new()
	l.text = title
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position.y = float(built.h) + 0.55
	l.font_size = 40
	l.pixel_size = 0.009
	l.outline_size = 12
	l.modulate = Color(1, 0.95, 0.55)
	l.no_depth_test = true
	n.add_child(l)
	var role: String = Data.NPCS.get(kind, {}).get("role", "")
	if role != "":
		var r := Label3D.new()
		r.text = "< %s >" % role
		r.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		r.position.y = float(built.h) + 0.15
		r.font_size = 30
		r.pixel_size = 0.008
		r.outline_size = 10
		r.modulate = Color(0.7, 0.9, 1.0)
		r.no_depth_test = true
		n.add_child(r)
	map_root.add_child(n)

func _build_spawns(half: float) -> void:
	# Setiap jenis monster mendapat spot tetap. Empat ring level menjaga
	# progresi map tetap terasa tanpa menyesuaikan level monster ke pemain.
	var mob_count: int = map.mobs.size()
	if mob_count <= 0:
		return
	var rings := 4 if map.get("dungeon", false) else 3
	var span: int = maxi(0, int(map.max) - int(map.min))
	for ring_idx in rings:
		var fixed_level := int(map.min) if span == 0 else int(round(float(map.min) + float(span) * float(ring_idx) / float(rings - 1)))
		for type_idx in mob_count:
			var slot := ring_idx * mob_count + type_idx
			var a := (TAU * float(slot) / float(rings * mob_count)) + _rng.randf_range(-0.08, 0.08)
			var r := 22.0 + float(ring_idx) * ((half - 30.0) / float(rings - 1)) + _rng.randf_range(-2.0, 2.0)
			var elite: bool = bool(map.get("dungeon", false)) or (ring_idx == rings - 1 and type_idx == mob_count - 1)
			spawns.append({
				"pos": Vector3(cos(a) * r, 0, sin(a) * r),
				"mon": null,
				"t": _rng.randf_range(0.0, 3.0),
				"boss": false,
				"kind": 1 if elite else 0,
				"monster": str(map.mobs[type_idx]),
				"level": fixed_level,
				"spot": "ring_%d_type_%d" % [ring_idx + 1, type_idx + 1]
			})
	spawns.append({"pos": Vector3(0, 0, -half + 10.0), "mon": null, "t": 1.0, "boss": true, "kind": 2, "monster": str(map.boss), "level": int(map.max), "spot": "boss_gate"})

func _spawn(sp: Dictionary) -> void:
	var active_limit: int = MAX_ACTIVE_DUNGEON if map.get("dungeon", false) else MAX_ACTIVE_WILD
	if monsters.size() >= active_limit:
		sp.t = 2.0
		return
	var m := Monster.new()
	var k: int = int(sp.get("kind", 2 if sp.boss else 0))
	var nm: String = str(sp.get("monster", map.boss if sp.boss else map.mobs[0]))
	m.world = self
	m.setup(self, sp, map, k, nm, 0)
	map_root.add_child(m)
	monsters.append(m)
	sp.mon = m

func on_mon_died(m: Monster) -> void:
	monsters.erase(m)
	m.sp.mon = null
	m.sp.t = 120.0 if m.kind == 2 else randf_range(10.0, 30.0)

func sync_all() -> void:
	for m in monsters:
		if is_instance_valid(m) and not m.dead:
			m.sync_level()

func warp(id: int) -> void:
	load_map(id)

func enter_dungeon(id: int) -> void:
	if id <= 0 or id >= Data.MAPS.size():
		return
	load_map(id, true)
	G.toast.emit("Dungeon dimasuki: %s — kalahkan monster dan boss!" % map.name, true)

func exit_dungeon() -> void:
	if not map.get("dungeon", false):
		return
	load_map(int(map.get("base_id", 0)))

func player_died() -> void:
	await get_tree().create_timer(1.5).timeout
	G.on_death()
	load_map(0)

func float_text(pos: Vector3, text: String, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 48
	l.pixel_size = 0.01
	l.outline_size = 12
	l.modulate = color
	l.no_depth_test = true
	add_child(l)
	l.position = pos
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y + 1.6, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(l.queue_free)

func fx_beam(a: Vector3, b: Vector3, color: Color, w: float = 0.07) -> void:
	var dist := a.distance_to(b)
	if dist < 0.05:
		return
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = w
	c.bottom_radius = w
	c.height = dist
	c.radial_segments = 6
	m.mesh = c
	m.material_override = _mat(color, true)
	add_child(m)
	var up := (b - a).normalized()
	var x := up.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = up.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(up).normalized()
	m.global_transform = Transform3D(Basis(x, up, z), (a + b) * 0.5)
	var tw := create_tween()
	tw.tween_interval(0.12)
	tw.tween_callback(m.queue_free)

func fx_shot(a: Vector3, b: Vector3, color: Color, w: float = 0.07) -> void:
	fx_beam(a, b, color, w * 1.3)
	fx_beam(a, b, Color(1, 1, 1), w * 0.45)
	var fl := Gfx.sph(self, 0.28, a, color.lightened(0.4), true)
	var tw := create_tween()
	tw.tween_property(fl, "scale", Vector3(0.1, 0.1, 0.1), 0.12)
	tw.tween_callback(fl.queue_free)
	fx_burst(b, color, 8)

func fx_burst(pos: Vector3, color: Color, n: int = 10) -> void:
	var ps := CPUParticles3D.new()
	ps.emitting = true
	ps.one_shot = true
	ps.amount = n
	ps.lifetime = 0.45
	ps.explosiveness = 1.0
	ps.direction = Vector3.UP
	ps.spread = 180.0
	ps.initial_velocity_min = 2.0
	ps.initial_velocity_max = 5.0
	ps.gravity = Vector3(0, -9.0, 0)
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	sm.radial_segments = 6
	sm.rings = 3
	ps.mesh = sm
	ps.material_override = Gfx.mat(color, true)
	add_child(ps)
	ps.position = pos
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_callback(ps.queue_free)

func fx_levelup() -> void:
	if player == null:
		return
	var pil := MeshInstance3D.new()
	var cm := _cylm(1.2, 1.2, 12.0, 20)
	pil.mesh = cm
	pil.material_override = Hero.glass(Color(1.0, 0.9, 0.4), 0.35, 1.5)
	player.add_child(pil)
	pil.position = Vector3(0, 6.0, 0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(pil, "scale", Vector3(0.1, 1.0, 0.1), 1.1)
	tw.chain().tween_callback(pil.queue_free)
	fx_ring(player.position, 5.0, Color(1.0, 0.85, 0.3))
	fx_burst(player.position + Vector3(0, 1.0, 0), Color(1.0, 0.9, 0.4), 28)

func spawn_crystals(pos: Vector3, n: int, col: Color) -> void:
	for i in n:
		var m := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.22
		c.height = 0.5
		c.radial_segments = 4
		c.rings = 1
		m.mesh = c
		m.material_override = _mat(col, true)
		add_child(m)
		var start := pos + Vector3(randf_range(-0.8, 0.8), 0.3, randf_range(-0.8, 0.8))
		m.position = start
		var tw := m.create_tween()
		tw.tween_property(m, "position:y", start.y + 0.8, 0.25)
		tw.tween_property(m, "position:y", 0.3, 0.2)
		tw.tween_interval(0.5)
		tw.tween_method(_pull.bind(m, start), 0.0, 1.0, 0.35)
		tw.tween_callback(m.queue_free)

func _pull(t: float, m: Node3D, from: Vector3) -> void:
	if is_instance_valid(m) and player != null:
		m.position = Vector3(from.x, 0.3, from.z).lerp(player.position + Vector3(0, 1.0, 0), t)

func fx_ring(pos: Vector3, radius: float, color: Color) -> void:
	var m := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.9
	t.outer_radius = 1.0
	t.ring_segments = 6
	t.rings = 24
	m.mesh = t
	m.material_override = _mat(color, true)
	add_child(m)
	m.position = pos + Vector3(0, 0.2, 0)
	m.scale = Vector3(0.2, 1, 0.2)
	var tw := create_tween()
	tw.tween_property(m, "scale", Vector3(radius, 1, radius), 0.3)
	tw.tween_callback(m.queue_free)

func _process(delta: float) -> void:
	var weather_wave: float = sin(G.weather_phase * TAU / 120.0)
	var weather_light: float = 0.82 + weather_wave * 0.10
	if G.world_event == "Hujan Meteor":
		weather_light += 0.08
		sun.light_color = Color(0.78, 0.7, 0.95)
	elif G.world_event == "Portal Chaos":
		weather_light -= 0.12
		sun.light_color = Color(0.62, 0.42, 0.9)
	sun.light_energy = weather_light
	env.fog_density = (0.026 if int(map.id) in [4, 7, 10] else 0.011) + (0.006 if G.world_event != "" else 0.0)
	var focus := player.position + Vector3(0, 1.4, 0)
	var orbit := Vector3(cos(cam_yaw) * cos(cam_pitch), sin(cam_pitch), sin(cam_yaw) * cos(cam_pitch)) * cam_distance
	var target := focus + orbit
	cam.position = cam.position.lerp(target, clampf(8.0 * delta, 0.0, 1.0))
	cam.look_at(focus)
	_fx_t += delta
	for a in npc_anims:
		Models.animate(a, _fx_t, false)
	if map.town:
		return
	for sp in spawns:
		if sp.mon == null:
			sp.t -= delta
		if sp.t <= 0.0:
			_spawn(sp)

func camera_orbit(dx: float, dy: float) -> void:
	cam_yaw = fmod(cam_yaw + dx, TAU)
	cam_pitch = clampf(cam_pitch + dy, 0.18, 1.35)

func camera_zoom(delta: float) -> void:
	cam_distance = clampf(cam_distance + delta, 6.0, 28.0)
