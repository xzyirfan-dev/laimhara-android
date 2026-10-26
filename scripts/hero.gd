class_name Hero
extends Node3D
## Model karakter Human (penembak). Setiap slot perlengkapan (helm, zirah, sarung tangan, sepatu, jubah, sabuk,
## kalung, cincin, senjata) mengubah tampilan sendiri. Efek (glow senjata, aura zirah, partikel) naik menurut +N / rarity / set.

var rig: Node3D
var l_leg: Node3D
var r_leg: Node3D
var l_arm: Node3D
var r_arm: Node3D
var gun_grp: Node3D
var muzzle: Node3D
var cape: Node3D
var wings: Node3D
var aura: Node3D
var rune: Node3D
var shield_fx: MeshInstance3D
var portrait_mode := false
var _phase := 0.0
var _t := 0.0
var _recoil := 0.0
var _gun_z := 0.64
var _orbit: Node3D
var _halo: MeshInstance3D
var _shell: MeshInstance3D
var _wfx := 0
var _afx := 0
var hair_col: Color = Color(0.8, 0.86, 0.98)

const SKIN := Color(0.96, 0.78, 0.64)

static func glass(c: Color, a: float, energy: float = 1.4) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, a)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func fire() -> void:
	_recoil = 0.14

## kompatibilitas (layar judul): semua slot setier
func build(armor_t: int, weapon_t: int) -> void:
	var eq: Dictionary = {}
	for s in ItemDb.SLOTS:
		eq[s] = {"slot": s, "tier": armor_t, "plus": 0, "rar": 0, "setn": 0, "uid": 0}
	eq["weapon"] = {"slot": "weapon", "tier": weapon_t, "plus": 0, "rar": 0, "setn": 0, "uid": 0}
	build_eq(eq)

static func _tier(eq: Dictionary, slot: String) -> int:
	var it: Dictionary = eq.get(slot, {})
	if it.is_empty():
		return 0
	return int(it.tier)

func _sparks(parent: Node3D, pos: Vector3, col: Color, amount: int, life: float, spd: float, size: float, radius: float = 0.1, up: float = 0.5, world_space: bool = true) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.position = pos
	p.local_coords = not world_space
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3(0, 1, 0)
	p.spread = 70.0
	p.initial_velocity_min = spd * 0.4
	p.initial_velocity_max = spd
	p.gravity = Vector3(0, up, 0)
	p.scale_amount_min = size * 0.5
	p.scale_amount_max = size
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 6
	sm.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = col
	sm.material = mat
	p.mesh = sm
	var g := Gradient.new()
	g.set_color(0, Color(col.r, col.g, col.b, 0.95))
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	p.color_ramp = g
	p.emitting = true
	parent.add_child(p)
	return p

func build_eq(eq: Dictionary) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_orbit = null
	_halo = null
	_shell = null
	var t_arm := _tier(eq, "armor")
	var t_helm := _tier(eq, "helm")
	var t_glv := _tier(eq, "gloves")
	var t_bts := _tier(eq, "boots")
	var t_clk := _tier(eq, "cloak")
	var t_blt := _tier(eq, "belt")
	var t_nck := _tier(eq, "neck")
	var t_rng := _tier(eq, "ring")
	var t_wpn := _tier(eq, "weapon")
	var plain := t_arm == 0
	var pa := Gfx.palette(maxi(1, t_arm))
	var M: Color = pa.main
	var D: Color = pa.dark
	var T: Color = pa.trim
	var GL: Color = pa.glow
	if plain:  # kain polos
		M = Color(0.32, 0.34, 0.42)
		D = Color(0.2, 0.21, 0.28)
		T = Color(0.5, 0.45, 0.35)
		GL = Color(0.4, 0.7, 0.9)
	var wit: Dictionary = eq.get("weapon", {})
	_wfx = ItemDb.weapon_fx(wit)
	_afx = ItemDb.armor_fx(eq)
	var setc := 0
	var cnt: Dictionary = {}
	for s in ItemDb.SLOTS:
		var it: Dictionary = eq.get(s, {})
		if not it.is_empty() and int(it.get("setn", 0)) > 0:
			cnt[int(it.setn)] = int(cnt.get(int(it.setn), 0)) + 1
			setc = maxi(setc, int(cnt[int(it.setn)]))
	rig = Gfx.pivot(self, Vector3.ZERO)
	# ---------- kaki + sepatu ----------
	var pb := Gfx.palette(maxi(1, t_bts))
	var BM: Color = pb.main
	var BD: Color = pb.dark
	var BT: Color = pb.trim
	var BG: Color = pb.glow
	if t_bts == 0:
		BM = Color(0.24, 0.18, 0.15)
		BD = Color(0.16, 0.12, 0.1)
		BT = Color(0.3, 0.24, 0.2)
	for s in [-1.0, 1.0]:
		var hip := Gfx.pivot(rig, Vector3(0.15 * s, 0.98, 0.0))
		Gfx.box(hip, Vector3(0.23, 0.48, 0.25), Vector3(0, -0.24, 0), D, false, 0.6, 0.3)
		Gfx.sph(hip, 0.12, Vector3(0, -0.48, 0.1), T, false, Vector3(1, 0.9, 0.8), 0.4, 0.5)
		Gfx.box(hip, Vector3(0.2, 0.4, 0.22), Vector3(0, -0.68, 0), BM if t_bts > 0 else M, false, 0.55, 0.3)
		if t_bts > 0:
			Gfx.box(hip, Vector3(0.24, 0.12, 0.26), Vector3(0, -0.6, 0), BT, false, 0.4, 0.5)
		Gfx.box(hip, Vector3(0.26, 0.17, 0.4), Vector3(0, -0.89, 0.07), BD.darkened(0.15), false, 0.5, 0.4)
		Gfx.box(hip, Vector3(0.27, 0.05, 0.42), Vector3(0, -0.96, 0.07), BT, false, 0.4, 0.5)
		if t_bts >= 50:
			var sp := Gfx.cyl(hip, 0.0, 0.05, 0.2, Vector3(0, -0.88, 0.3), BT, false, 6, 0.4, 0.5)
			sp.rotation.x = PI / 2.0
		if t_bts >= 200:
			var wg := Gfx.box(hip, Vector3(0.02, 0.2, 0.16), Vector3(0.15 * s, -0.7, -0.08), BG, true)
			wg.rotation.z = 0.5 * s
		if t_bts >= 320:
			Gfx.box(hip, Vector3(0.22, 0.015, 0.36), Vector3(0, -0.985, 0.07), BG, true)
		if s < 0:
			l_leg = hip
		else:
			r_leg = hip
	# ---------- badan ----------
	Gfx.box(rig, Vector3(0.44, 0.22, 0.3), Vector3(0, 1.0, 0), D, false, 0.6, 0.3)
	Gfx.box(rig, Vector3(0.58, 0.52, 0.34), Vector3(0, 1.42, 0), M, false, 0.5, 0.35)
	Gfx.box(rig, Vector3(0.36, 0.28, 0.06), Vector3(0, 0.88, 0.17), M, false, 0.5, 0.35)
	Gfx.cyl(rig, 0.13, 0.17, 0.12, Vector3(0, 1.72, 0), D)
	if not plain:
		Gfx.box(rig, Vector3(0.48, 0.07, 0.34), Vector3(0, 1.13, 0), T, false, 0.35, 0.6)
		Gfx.box(rig, Vector3(0.1, 0.1, 0.05), Vector3(0, 1.13, 0.18), GL, true)
		Gfx.box(rig, Vector3(0.62, 0.3, 0.1), Vector3(0, 1.48, 0.18), M.lightened(0.12), false, 0.4, 0.5)
		Gfx.box(rig, Vector3(0.64, 0.05, 0.12), Vector3(0, 1.64, 0.17), T, false, 0.35, 0.6)
		Gfx.sph(rig, 0.065 + 0.012 * float(_afx), Vector3(0, 1.46, 0.24), GL, true)
		Gfx.box(rig, Vector3(0.38, 0.04, 0.07), Vector3(0, 0.75, 0.17), T, false, 0.35, 0.6)
	else:
		Gfx.box(rig, Vector3(0.1, 0.5, 0.02), Vector3(0, 1.42, 0.18), T.darkened(0.2))
	# ransel Electric Power
	Gfx.box(rig, Vector3(0.36, 0.42, 0.17), Vector3(0, 1.4, -0.26), D.darkened(0.15), false, 0.5, 0.4)
	for sx in [-0.09, 0.09]:
		Gfx.cyl(rig, 0.05, 0.05, 0.3, Vector3(sx, 1.4, -0.36), GL, true, 8)
	Gfx.cyl(rig, 0.012, 0.012, 0.3, Vector3(0.14, 1.78, -0.27), T)
	# ---------- sabuk ----------
	if t_blt > 0:
		var pk := Gfx.palette(t_blt)
		Gfx.box(rig, Vector3(0.5, 0.09, 0.36), Vector3(0, 1.1, 0), pk.dark, false, 0.4, 0.5)
		Gfx.box(rig, Vector3(0.2, 0.12, 0.05), Vector3(0, 1.1, 0.2), pk.trim, false, 0.3, 0.7)
		Gfx.box(rig, Vector3(0.09, 0.07, 0.03), Vector3(0, 1.1, 0.23), pk.glow, true)
		if t_blt >= 50:
			for sx in [-0.3, 0.3]:
				Gfx.box(rig, Vector3(0.1, 0.16, 0.12), Vector3(sx, 1.0, 0.1), pk.main, false, 0.5, 0.4)
	# ---------- kalung ----------
	if t_nck > 0:
		var pn := Gfx.palette(t_nck)
		Gfx.box(rig, Vector3(0.3, 0.025, 0.02), Vector3(0, 1.66, 0.19), pn.trim, false, 0.3, 0.7)
		Gfx.box(rig, Vector3(0.03, 0.2, 0.02), Vector3(0.1, 1.58, 0.205), pn.trim, false, 0.3, 0.7).rotation.z = 0.5
		Gfx.box(rig, Vector3(0.03, 0.2, 0.02), Vector3(-0.1, 1.58, 0.205), pn.trim, false, 0.3, 0.7).rotation.z = -0.5
		Gfx.sph(rig, 0.06, Vector3(0, 1.5, 0.27), pn.glow, true)
	# ---------- jubah ----------
	cape = Gfx.pivot(rig, Vector3(0, 1.66, -0.2))
	if t_clk > 0:
		var pc := Gfx.palette(t_clk)
		var CC: Color = pc.cape
		Gfx.box(cape, Vector3(0.62, 1.0, 0.035), Vector3(0, -0.5, -0.05), CC)
		Gfx.box(cape, Vector3(0.64, 0.07, 0.045), Vector3(0, -1.0, -0.05), pc.trim)
		Gfx.box(cape, Vector3(0.64, 0.06, 0.05), Vector3(0, -0.04, -0.04), pc.trim)
		if t_clk >= 100:
			Gfx.box(cape, Vector3(0.1, 0.9, 0.04), Vector3(0, -0.5, -0.07), pc.trim.darkened(0.25))
		if t_clk >= 320:
			for i in 5:
				var sp2 := Gfx.cyl(cape, 0.0, 0.05, 0.22, Vector3(-0.24 + 0.12 * i, -1.08, -0.05), pc.glow, true, 5)
				sp2.rotation.x = PI
	# ---------- sayap (jubah tier 400) ----------
	wings = Gfx.pivot(rig, Vector3(0, 1.62, -0.34))
	if t_clk >= 400:
		var pw2 := Gfx.palette(t_clk)
		for s in [-1.0, 1.0]:
			var w := Gfx.pivot(wings, Vector3(0.1 * s, 0, 0))
			w.rotation.z = -0.5 * s
			for i in 4:
				var f := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.1, 0.9 - 0.14 * i, 0.015)
				f.mesh = bm
				f.material_override = glass(pw2.glow, 0.55)
				f.position = Vector3(0.18 * s * float(i + 1) * 0.8, 0.25 - 0.08 * i, 0)
				f.rotation.z = -0.35 * s * float(i + 1) * 0.5
				w.add_child(f)
	# ---------- kepala ----------
	var head := Gfx.pivot(rig, Vector3(0, 1.93, 0))
	Gfx.sph(head, 0.25, Vector3.ZERO, SKIN, false, Vector3(1, 1.05, 1), 0.7)
	Gfx.sph(head, 0.272, Vector3(0, 0.05, -0.03), hair_col, false, Vector3(1, 0.82, 1.02), 0.8)
	Gfx.box(head, Vector3(0.34, 0.12, 0.1), Vector3(0, 0.15, 0.2), hair_col)
	Gfx.box(head, Vector3(0.3, 0.32, 0.12), Vector3(0, -0.06, -0.26), hair_col)
	for sx in [-0.1, 0.1]:
		Gfx.box(head, Vector3(0.06, 0.07, 0.03), Vector3(sx, -0.02, 0.235), Color(0.1, 0.12, 0.2))
	Gfx.sph(head, 0.045, Vector3(0.0, -0.1, 0.24), Color(0.85, 0.5, 0.45), false, Vector3(1.4, 0.5, 0.6))
	if t_helm > 0:
		var ph := Gfx.palette(t_helm)
		var HM: Color = ph.main
		var HD: Color = ph.dark
		var HT: Color = ph.trim
		var HG: Color = ph.glow
		Gfx.box(head, Vector3(0.46, 0.07, 0.1), Vector3(0, 0.04, 0.19), HG, true)
		if t_helm >= 10:
			Gfx.sph(head, 0.3, Vector3(0, 0.1, -0.02), HM, false, Vector3(1, 0.62, 1.04), 0.45, 0.4)
			Gfx.box(head, Vector3(0.1, 0.22, 0.12), Vector3(0.28, -0.04, 0), HD)
			Gfx.box(head, Vector3(0.1, 0.22, 0.12), Vector3(-0.28, -0.04, 0), HD)
			Gfx.box(head, Vector3(0.58, 0.04, 0.5), Vector3(0, 0.07, 0), HT, false, 0.35, 0.6)
		else:
			Gfx.box(head, Vector3(0.52, 0.07, 0.5), Vector3(0, 0.13, 0), ph.cape)
		if t_helm >= 100:
			Gfx.box(head, Vector3(0.05, 0.18, 0.46), Vector3(0, 0.3, -0.02), HT)
		if t_helm >= 50:
			for s in [-1.0, 1.0]:
				var hn := Gfx.cyl(head, 0.0, 0.05, 0.26, Vector3(0.26 * s, 0.22, 0), HT, false, 6, 0.4, 0.5)
				hn.rotation.z = -0.6 * s
		if t_helm >= 200:
			for s in [-1.0, 1.0]:
				var h := Gfx.cyl(head, 0.0, 0.07, 0.42, Vector3(0.29 * s, 0.3, 0), HT, false, 8, 0.4, 0.5)
				h.rotation.z = -0.7 * s
		if t_helm >= 320:
			for i in 5:
				var sp := Gfx.cyl(head, 0.0, 0.05, 0.28, Vector3((i - 2) * 0.1, 0.34, -0.1), HG, true, 6)
				sp.rotation.x = -0.4
		if t_helm >= 400:
			for s in [-1.0, 1.0]:
				var wg := MeshInstance3D.new()
				var bm2 := BoxMesh.new()
				bm2.size = Vector3(0.34, 0.03, 0.14)
				wg.mesh = bm2
				wg.material_override = glass(HG, 0.7)
				wg.position = Vector3(0.4 * s, 0.1, -0.04)
				wg.rotation.z = 0.45 * s
				head.add_child(wg)
	# ---------- bahu ----------
	for s in [-1.0, 1.0]:
		if plain:
			Gfx.sph(rig, 0.18, Vector3(0.4 * s, 1.63, 0), M, false, Vector3(1.0, 0.7, 1.0), 0.8)
			continue
		Gfx.sph(rig, 0.23, Vector3(0.4 * s, 1.63, 0), M, false, Vector3(1.05, 0.7, 1.05), 0.4, 0.5)
		Gfx.sph(rig, 0.18, Vector3(0.43 * s, 1.68, 0), T, false, Vector3(1, 0.5, 1), 0.35, 0.6)
		if t_arm >= 50:
			var sp2 := Gfx.cyl(rig, 0.0, 0.07, 0.3, Vector3(0.46 * s, 1.84, 0), T, false, 6, 0.4, 0.5)
			sp2.rotation.z = -0.35 * s
		if t_arm >= 200:
			var sp3 := Gfx.cyl(rig, 0.0, 0.06, 0.4, Vector3(0.58 * s, 1.74, 0), T, false, 6, 0.4, 0.5)
			sp3.rotation.z = -1.1 * s
	# ---------- lengan + sarung tangan ----------
	var pg := Gfx.palette(maxi(1, t_glv))
	for s in [-1.0, 1.0]:
		var sh := Gfx.pivot(rig, Vector3(0.4 * s, 1.58, 0))
		Gfx.box(sh, Vector3(0.17, 0.34, 0.17), Vector3(0, -0.2, 0), M, false, 0.55, 0.3)
		Gfx.sph(sh, 0.1, Vector3(0, -0.4, 0), T, false, Vector3.ONE, 0.4, 0.5)
		Gfx.box(sh, Vector3(0.15, 0.3, 0.15), Vector3(0, -0.56, 0), D, false, 0.5, 0.35)
		if t_glv > 0:
			Gfx.box(sh, Vector3(0.2, 0.2, 0.2), Vector3(0, -0.66, 0), pg.main, false, 0.4, 0.5)
			Gfx.box(sh, Vector3(0.22, 0.05, 0.22), Vector3(0, -0.57, 0), pg.trim, false, 0.35, 0.6)
			Gfx.box(sh, Vector3(0.14, 0.06, 0.12), Vector3(0, -0.74, 0.08), pg.dark, false, 0.4, 0.5)
			if t_glv >= 50:
				for kx in [-0.06, 0.0, 0.06]:
					var ks := Gfx.cyl(sh, 0.0, 0.025, 0.1, Vector3(kx, -0.8, 0.1), pg.trim, false, 5, 0.4, 0.5)
					ks.rotation.x = PI / 2.0 - 0.2
			if t_glv >= 200:
				Gfx.sph(sh, 0.045, Vector3(0, -0.66, 0.11), pg.glow, true)
			Gfx.sph(sh, 0.085, Vector3(0, -0.77, 0), pg.dark, false, Vector3.ONE, 0.6)
		else:
			Gfx.box(sh, Vector3(0.18, 0.1, 0.18), Vector3(0, -0.62, 0), T, false, 0.35, 0.6)
			Gfx.sph(sh, 0.085, Vector3(0, -0.76, 0), SKIN, false, Vector3.ONE, 0.7)
		if s < 0:
			l_arm = sh
			if t_rng > 0:  # cincin
				var pr := Gfx.palette(t_rng)
				Gfx.sph(sh, 0.05, Vector3(0.07, -0.74, 0.07), pr.glow, true)
				Gfx.box(sh, Vector3(0.1, 0.02, 0.1), Vector3(0.0, -0.7, 0), pr.trim, false, 0.3, 0.7)
		else:
			r_arm = sh
	r_arm.rotation.x = -1.15
	l_arm.rotation.x = -0.35
	# ---------- senapan ----------
	var pw := Gfx.palette(maxi(1, t_wpn))
	var ln := 1.0 + float(t_wpn) / 900.0
	gun_grp = Gfx.pivot(rig, Vector3(0.4, 1.29, _gun_z))
	var WM: Color = pw.main
	var WD: Color = pw.dark
	var WT: Color = pw.trim
	var WG: Color = pw.glow
	var ge := 1.0 + 0.5 * float(_wfx)
	Gfx.box(gun_grp, Vector3(0.12, 0.17, 0.62), Vector3(0, 0, 0.05), WD, false, 0.4, 0.5)
	Gfx.box(gun_grp, Vector3(0.1, 0.07, 0.5), Vector3(0, 0.12, 0.1), WM, false, 0.4, 0.5)
	Gfx.box(gun_grp, Vector3(0.09, 0.2, 0.26), Vector3(0, -0.02, -0.4), WD)
	Gfx.box(gun_grp, Vector3(0.07, 0.2, 0.09), Vector3(0, -0.16, -0.02), WD.darkened(0.2))
	var br := Gfx.cyl(gun_grp, 0.035, 0.035, 0.7 * ln, Vector3(0, 0.02, 0.35 + 0.35 * ln), Color(0.75, 0.78, 0.85), false, 8, 0.25, 0.8)
	br.rotation.x = PI / 2.0
	Gfx.box(gun_grp, Vector3(0.14, 0.14, 0.05), Vector3(0, 0.02, 0.42), WT, false, 0.4, 0.5)
	var tipm := Gfx.box(gun_grp, Vector3(0.14 + 0.02 * _wfx, 0.14 + 0.02 * _wfx, 0.05), Vector3(0, 0.02, 0.35 + 0.7 * ln), WG, true)
	(tipm.material_override as StandardMaterial3D).emission_energy_multiplier = 1.6 * ge
	var sc := Gfx.cyl(gun_grp, 0.045, 0.045, 0.3, Vector3(0, 0.22, 0.12), WD.darkened(0.3), false, 8, 0.3, 0.6)
	sc.rotation.x = PI / 2.0
	Gfx.sph(gun_grp, 0.04, Vector3(0, 0.22, 0.28), WG, true)
	for sx in [-0.062, 0.062]:
		var st := Gfx.box(gun_grp, Vector3(0.012, 0.03, 0.34), Vector3(sx, 0.02, 0.1), WG, true)
		(st.material_override as StandardMaterial3D).emission_energy_multiplier = 1.6 * ge
	if t_wpn >= 200:
		for i in 3:
			Gfx.box(gun_grp, Vector3(0.02, 0.14, 0.08), Vector3(0, 0.1, 0.55 + 0.15 * i), WT)
	if t_wpn >= 400:
		for i in 3:
			var cr := Gfx.cyl(gun_grp, 0.0, 0.04, 0.22, Vector3(0.07 * (1 if i % 2 == 0 else -1), 0.02, 0.5 + 0.18 * i), WG, true, 4)
			cr.rotation.z = 0.8 * (1 if i % 2 == 0 else -1)
	muzzle = Gfx.pivot(gun_grp, Vector3(0, 0.02, 0.4 + 0.7 * ln))
	# efek senjata menurut +N / rarity
	var wcol: Color = WG
	if int(wit.get("rar", 0)) >= 4:
		wcol = Color(1.0, 0.75, 0.25)
	if _wfx >= 1:
		_halo = MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = 0.16 + 0.03 * float(_wfx)
		hs.height = hs.radius * 2.0
		hs.radial_segments = 12
		hs.rings = 6
		_halo.mesh = hs
		_halo.material_override = glass(wcol, 0.35, 1.8)
		_halo.position = Vector3(0, 0.02, 0.35 + 0.7 * ln)
		gun_grp.add_child(_halo)
	if _wfx >= 2:
		var shell := MeshInstance3D.new()
		var bs := BoxMesh.new()
		bs.size = Vector3(0.2, 0.3, 1.5 * ln)
		shell.mesh = bs
		shell.material_override = glass(wcol, 0.12 + 0.03 * float(_wfx), 1.4)
		shell.position = Vector3(0, 0.05, 0.4 + 0.3 * ln)
		gun_grp.add_child(shell)
		_sparks(gun_grp, Vector3(0, 0.05, 0.3 + 0.7 * ln), wcol, 8 + 4 * _wfx, 0.7, 0.5, 0.045)
	if _wfx >= 3:
		_sparks(gun_grp, Vector3(0, 0.1, 0.6), wcol, 24, 1.0, 0.9, 0.06, 0.3, 1.0)
		for i in 3:
			var rg := Gfx.ring(gun_grp, 0.1, 0.13, Vector3(0, 0.02, 0.5 + 0.22 * i), wcol)
			rg.rotation.x = PI / 2.0
	if _wfx >= 4:
		_sparks(gun_grp, Vector3(0, 0.15, 0.7), Color(1.0, 0.55, 0.2), 40, 1.2, 1.6, 0.09, 0.25, 2.2)
		_sparks(gun_grp, Vector3(0, 0.02, 0.35 + 0.7 * ln), Color(1, 1, 0.8), 20, 0.5, 1.2, 0.05, 0.05, 0.0)
	# ---------- aura kaki ----------
	aura = Gfx.pivot(self, Vector3(0, 0.04, 0))
	var acol: Color = GL
	if setc >= 2:
		acol = Color(1.0, 0.82, 0.3)
	if not portrait_mode:
		Gfx.ring(aura, 0.62, 0.78, Vector3.ZERO, acol)
		var disc := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.7
		cm.bottom_radius = 0.7
		cm.height = 0.01
		cm.radial_segments = 28
		disc.mesh = cm
		disc.material_override = glass(acol, 0.22 + 0.04 * float(_afx), 1.0)
		aura.add_child(disc)
		rune = Gfx.pivot(aura, Vector3.ZERO)
		for i in 6 + 2 * _afx:
			var a := TAU * float(i) / float(6 + 2 * _afx)
			var rb := Gfx.box(rune, Vector3(0.07, 0.015, 0.16), Vector3(cos(a) * 0.46, 0.01, sin(a) * 0.46), acol, true)
			rb.rotation.y = -a
		if _afx >= 2:
			Gfx.ring(aura, 0.9, 0.96, Vector3(0, 0.01, 0), acol)
		# gelembung Electric Shield
		shield_fx = MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.25
		sm.height = 2.5
		sm.radial_segments = 20
		sm.rings = 10
		shield_fx.mesh = sm
		shield_fx.material_override = glass(Color(0.4, 0.8, 1.0), 0.18, 1.2)
		shield_fx.position = Vector3(0, 1.1, 0)
		shield_fx.visible = false
		add_child(shield_fx)
	else:
		shield_fx = null
		rune = null
	# efek zirah menurut rata-rata +N seluruh perlengkapan
	if _afx >= 1:
		_sparks(self, Vector3(0, 0.1, 0), acol, 6 + 6 * _afx, 1.4, 0.6, 0.05 + 0.01 * _afx, 0.5, 0.9)
	if _afx >= 3:
		_shell = MeshInstance3D.new()
		var cs := CapsuleMesh.new()
		cs.radius = 0.62
		cs.height = 2.3
		cs.radial_segments = 16
		cs.rings = 6
		_shell.mesh = cs
		_shell.material_override = glass(acol, 0.12 + 0.03 * float(_afx - 3), 1.2)
		_shell.position = Vector3(0, 1.15, 0)
		add_child(_shell)
	if _afx >= 4 or setc >= 4:
		_orbit = Gfx.pivot(self, Vector3(0, 1.2, 0))
		for i in 4:
			var a2 := TAU * float(i) / 4.0
			var ob := Gfx.sph(_orbit, 0.07, Vector3(cos(a2) * 0.75, sin(a2 * 2.0) * 0.4, sin(a2) * 0.75), acol, true)
			ob.material_override = glass(acol, 0.9, 2.2)
		_sparks(self, Vector3(0, 0.1, 0), Color(1.0, 0.6, 0.25) if setc < 4 else Color(1.0, 0.85, 0.3), 36, 1.6, 1.6, 0.08, 0.45, 1.8)

func animate(delta: float, moving: bool, shield: bool) -> void:
	if rig == null:
		return
	_t += delta
	var k := minf(1.0, 12.0 * delta)
	if moving:
		_phase += delta * 10.5
		var sw := sin(_phase)
		l_leg.rotation.x = sw * 0.8
		r_leg.rotation.x = -sw * 0.8
		l_arm.rotation.x = -sw * 0.7
		rig.position.y = absf(sw) * 0.07
		cape.rotation.x = lerpf(cape.rotation.x, 0.42 + sin(_phase * 0.5) * 0.06, k)
	else:
		l_leg.rotation.x = lerpf(l_leg.rotation.x, 0.0, k)
		r_leg.rotation.x = lerpf(r_leg.rotation.x, 0.0, k)
		l_arm.rotation.x = lerpf(l_arm.rotation.x, -0.35 + sin(_t * 1.8) * 0.04, k)
		rig.position.y = sin(_t * 2.0) * 0.015
		cape.rotation.x = lerpf(cape.rotation.x, 0.06 + sin(_t * 1.6) * 0.03, k)
	if _recoil > 0.0:
		_recoil -= delta
		var kk := clampf(_recoil / 0.14, 0.0, 1.0)
		gun_grp.position.z = _gun_z - 0.1 * kk
		r_arm.rotation.x = -1.15 + 0.22 * kk
	else:
		gun_grp.position.z = _gun_z
		r_arm.rotation.x = -1.15
	if rune != null:
		rune.rotation.y += delta * 1.6
	if wings != null and wings.get_child_count() > 0:
		wings.rotation.z = sin(_t * 2.2) * 0.04
	if _orbit != null:
		_orbit.rotation.y += delta * 1.8
	if _halo != null:
		_halo.scale = Vector3.ONE * (1.0 + sin(_t * 7.0) * 0.12)
	if _shell != null:
		_shell.scale = Vector3.ONE * (1.0 + sin(_t * 3.0) * 0.025)
	if shield_fx != null:
		shield_fx.visible = shield
		if shield:
			shield_fx.scale = Vector3.ONE * (1.0 + sin(_t * 8.0) * 0.015)
