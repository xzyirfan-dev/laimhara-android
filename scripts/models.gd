class_name Models
extends RefCounted
## Model 3D prosedural: tiap spesies monster punya siluet sendiri (bukan bola polos), NPC berpakaian sesuai peran.
## Anim: array {n: Node3D, ax: 0=rot x, 2=rot z, 3=pos x, 4=pos y, amp, sp, ph, always}

const BONE := Color(0.88, 0.85, 0.74)

static func _eye(p: Node3D, pos: Vector3, r: float, c: Color) -> void:
	Gfx.sph(p, r, pos, c, true)

static func _eyes(p: Node3D, y: float, z: float, dx: float, r: float, c: Color) -> void:
	_eye(p, Vector3(-dx, y, z), r, c)
	_eye(p, Vector3(dx, y, z), r, c)

static func _a(A: Array, n: Node3D, ax: int, amp: float, ph: float = 0.0, sp: float = 1.0, always: bool = false) -> void:
	A.append({"n": n, "ax": ax, "amp": amp, "ph": ph, "sp": sp, "always": always})

static func animate(A: Array, t: float, moving: bool) -> void:
	for e in A:
		var n: Node3D = e.n
		if not is_instance_valid(n):
			continue
		var always: bool = e.always
		var amp: float = e.amp
		var sp: float = e.sp
		var f := (9.0 if moving else 2.2) * sp
		var k := 1.0 if (moving or always) else 0.13
		var v: float = sin(t * f + float(e.ph)) * amp * k
		match int(e.ax):
			0: n.rotation.x = v
			2: n.rotation.z = v
			3: n.position.x = v
			4: n.position.y = v

# ------------------------------------------------------------------ monster
static func monster(mname: String, col: Color, kind: int) -> Dictionary:
	var root := Node3D.new()
	var A: Array = []
	var h := 1.4
	var n := mname
	if n.contains("Slime"):
		h = _blob(root, A, Color(0.35, 0.85, 0.4), n == "Raja Slime", "slime")
	elif n.contains("Jamur") or n.contains("Spora"):
		h = _blob(root, A, Color(0.8, 0.25, 0.3), n.contains("Ratu"), "jamur")
	elif n.contains("Tikus"):
		h = _quad(root, A, {"col": Color(0.5, 0.42, 0.38), "len": 0.7, "w": 0.4, "ht": 0.4, "feats": ["ears", "tail", "fang"], "eye": Color(1, 0.3, 0.2)})
	elif n.contains("Belalang"):
		h = _bug(root, A, Color(0.5, 0.8, 0.2), "hopper")
	elif n.contains("Kalajengking"):
		h = _bug(root, A, Color(0.35, 0.27, 0.3) if n.contains("Batu") else Color(0.85, 0.65, 0.3), "scorp")
	elif n.contains("Goblin"):
		h = _biped(root, A, {"col": Color(0.4, 0.62, 0.25), "col2": Color(0.45, 0.32, 0.2), "h": 0.75, "bulk": 0.85, "hunch": 0.25, "feats": ["ears", "club", "fang"], "eye": Color(1, 0.9, 0.2)})
	elif n.contains("Serigala"):
		h = _quad(root, A, {"col": Color(0.45, 0.45, 0.5), "len": 1.0, "w": 0.45, "ht": 0.7, "feats": ["ears", "tail", "snout", "fang"], "eye": Color(1, 0.8, 0.2)})
	elif n.contains("Harimau"):
		h = _quad(root, A, {"col": Color(0.75, 0.8, 0.95), "len": 1.15, "w": 0.55, "ht": 0.75, "feats": ["ears", "tail", "stripes", "ghost", "fang"], "eye": Color(0.3, 1, 0.9)})
	elif n.contains("Banteng") or n == "Tanduk Putih":
		h = _quad(root, A, {"col": Color(0.65, 0.4, 0.25) if n != "Tanduk Putih" else Color(0.92, 0.9, 0.85), "len": 1.1, "w": 0.7, "ht": 0.8, "feats": ["horns", "snout"], "eye": Color(1, 0.3, 0.2)})
	elif n.contains("Elang"):
		h = _wing(root, A, "eagle", n.contains("Badai"))
	elif n.contains("Kelelawar"):
		h = _wing(root, A, "bat", false)
	elif n.contains("Wyvern"):
		h = _wing(root, A, "wyvern", false)
	elif n.contains("Wyrm"):
		h = _wing(root, A, "wyvern", true)
	elif n.contains("Gargoyle"):
		h = _biped(root, A, {"col": Color(0.5, 0.5, 0.58), "col2": Color(0.4, 0.4, 0.48), "h": 0.9, "bulk": 1.0, "feats": ["horns", "wings", "fang"], "eye": Color(1, 0.4, 0.2)})
	elif n.contains("Troll"):
		h = _biped(root, A, {"col": Color(0.4, 0.5, 0.45), "col2": Color(0.3, 0.38, 0.34), "h": 0.95, "bulk": 1.5, "hunch": 0.3, "feats": ["club", "tusks"], "eye": Color(1, 0.7, 0.1)})
	elif n.contains("Golem"):
		var mag := n.contains("Magma")
		h = _biped(root, A, {"col": Color(0.3, 0.2, 0.18) if mag else Color(0.5, 0.5, 0.52), "col2": Color(0.22, 0.15, 0.14) if mag else Color(0.4, 0.4, 0.42), "h": 0.85, "bulk": 1.7, "feats": ["cracks_hot" if mag else "cracks"], "eye": Color(1, 0.5, 0.1) if mag else Color(0.4, 0.9, 1)})
	elif n.contains("Warden"):
		h = _biped(root, A, {"col": BONE, "col2": Color(0.3, 0.3, 0.38), "h": 1.0, "bulk": 1.45, "feats": ["skull", "sword", "shield", "horns"], "eye": Color(0.4, 1, 1)})
	elif n.contains("Skeleton"):
		h = _biped(root, A, {"col": BONE, "col2": Color(0.78, 0.75, 0.64), "h": 1.0, "bulk": 0.9, "thin": true, "feats": ["skull", "sword"], "eye": Color(0.5, 1, 1)})
	elif n.contains("Mumi"):
		h = _biped(root, A, {"col": Color(0.86, 0.8, 0.62), "col2": Color(0.78, 0.7, 0.52), "h": 0.95, "bulk": 1.0, "hunch": 0.2, "feats": ["wrap", "armsout"], "eye": Color(0.3, 1, 0.5)})
	elif n.contains("Zombie"):
		h = _biped(root, A, {"col": Color(0.5, 0.6, 0.5), "col2": Color(0.3, 0.3, 0.38), "h": 0.95, "bulk": 1.0, "hunch": 0.3, "feats": ["armsout"], "eye": Color(0.9, 0.2, 0.2)})
	elif n.contains("Lich"):
		h = _biped(root, A, {"col": BONE, "col2": Color(0.3, 0.12, 0.45), "h": 1.0, "bulk": 1.2, "thin": true, "feats": ["skull", "cloak", "crown", "orb"], "eye": Color(0.8, 0.3, 1)})
	elif n.contains("Wraith"):
		h = _biped(root, A, {"col": Color(0.35, 0.3, 0.5), "col2": Color(0.25, 0.2, 0.4), "h": 1.0, "bulk": 1.0, "feats": ["cloak", "float"], "eye": Color(0.5, 1, 0.9)})
	elif n.contains("Iblis"):
		h = _biped(root, A, {"col": Color(0.65, 0.15, 0.1), "col2": Color(0.4, 0.08, 0.06), "h": 1.0, "bulk": 1.2, "feats": ["horns", "flame", "fang", "wings"], "eye": Color(1, 0.9, 0.2)})
	elif n.contains("Yeti"):
		h = _biped(root, A, {"col": Color(0.92, 0.95, 1.0), "col2": Color(0.8, 0.86, 0.95), "h": 0.9, "bulk": 1.55, "hunch": 0.25, "feats": ["fur", "fang"], "eye": Color(0.3, 0.7, 1)})
	elif n.contains("Titan"):
		h = _biped(root, A, {"col": Color(0.7, 0.85, 0.95), "col2": Color(0.45, 0.65, 0.85), "h": 1.1, "bulk": 1.7, "feats": ["ice", "club"], "eye": Color(0.4, 0.9, 1)})
	elif n == "Ragnok":
		h = _wing(root, A, "wyvern", true)
		_ice_tint(root)
	elif n.contains("Naga"):
		h = _serpent(root, A, Color(0.4, 0.75, 0.95), true)
	elif n.contains("Ular") or n == "Magralis":
		h = _serpent(root, A, Color(0.25, 0.65, 0.4), n == "Magralis")
	elif n.contains("Ent"):
		h = _ent(root, A)
	elif n.contains("Void"):
		h = _biped(root, A, {"col": Color(0.1, 0.05, 0.15), "col2": Color(0.07, 0.03, 0.1), "h": 1.05, "bulk": 1.1, "feats": ["orb", "float", "spikes"], "eye": Color(1, 0.2, 0.9)})
	elif n.contains("Chaos Emperor"):
		h = _orb_eye(root, A, true)
	elif n.contains("Chaos") or n.contains("Horor"):
		h = _orb_eye(root, A, false)
	else:
		h = _blob(root, A, col, false, "slime")
	root.set_meta("h", h)
	return {"root": root, "anim": A, "h": h}

static func _ice_tint(root: Node3D) -> void:
	for c in root.get_children():
		if c is MeshInstance3D:
			var mi: MeshInstance3D = c
			var m: StandardMaterial3D = mi.material_override
			if m != null:
				mi.material_override = Gfx.mat(m.albedo_color.lerp(Color(0.7, 0.9, 1.0), 0.7), m.emission_enabled, 0.3, 0.2)

# ------------------------------------------------------------------ blob (slime / jamur)
static func _blob(root: Node3D, A: Array, c: Color, boss: bool, style: String) -> float:
	var b := Gfx.pivot(root, Vector3.ZERO)
	_a(A, b, 4, 0.0, 0.0, 1.0, true)
	if style == "slime":
		var body := Gfx.sph(b, 0.62, Vector3(0, 0.5, 0), c, false, Vector3(1.1, 0.85, 1.1), 0.25)
		body.material_override = Hero.glass(c, 0.72, 0.35)
		Gfx.sph(b, 0.22, Vector3(0.0, 0.5, 0.0), c.darkened(0.35), false, Vector3(1, 0.8, 1))
		Gfx.sph(b, 0.1, Vector3(-0.22, 0.78, 0.3), Color(1, 1, 1, 1), true, Vector3(1, 0.6, 0.6))
		_eyes(b, 0.55, 0.52, 0.2, 0.07, Color(0.05, 0.1, 0.05))
		Gfx.box(b, Vector3(0.22, 0.04, 0.04), Vector3(0, 0.38, 0.58), Color(0.05, 0.1, 0.05))
		if boss:
			Gfx.cyl(b, 0.2, 0.28, 0.25, Vector3(0, 1.1, 0), Color(1, 0.85, 0.2), true, 6)
			for i in 5:
				var a := TAU * float(i) / 5.0
				Gfx.cyl(b, 0.0, 0.07, 0.2, Vector3(cos(a) * 0.24, 1.3, sin(a) * 0.24), Color(1, 0.85, 0.2), true, 4)
		return 1.3 if boss else 1.1
	var stem := Gfx.cyl(b, 0.22, 0.28, 0.5, Vector3(0, 0.25, 0), Color(0.95, 0.9, 0.8), false, 10)
	stem.name = "stem"
	_eyes(b, 0.3, 0.24, 0.1, 0.05, Color(0.1, 0.0, 0.0))
	Gfx.box(b, Vector3(0.18, 0.04, 0.03), Vector3(0, 0.16, 0.27), Color(0.2, 0.05, 0.05))
	Gfx.sph(b, 0.65, Vector3(0, 0.65, 0), c, false, Vector3(1.0, 0.62, 1.0), 0.5)
	for i in 6:
		var a2 := TAU * float(i) / 6.0 + 0.4
		Gfx.sph(b, 0.1, Vector3(cos(a2) * 0.42, 0.88 + sin(float(i) * 2.1) * 0.06, sin(a2) * 0.42), Color(1, 0.95, 0.85), false, Vector3(1, 0.5, 1))
	Gfx.sph(b, 0.12, Vector3(0, 1.02, 0), Color(1, 0.95, 0.85), false, Vector3(1, 0.5, 1))
	if boss:
		Gfx.cyl(b, 0.12, 0.2, 0.2, Vector3(0, 1.2, 0), Color(0.7, 0.2, 0.9), true, 6)
	return 1.4

# ------------------------------------------------------------------ biped
static func _biped(root: Node3D, A: Array, o: Dictionary) -> float:
	var col: Color = o.get("col", Color.GRAY)
	var c2: Color = o.get("col2", col.darkened(0.3))
	var eye: Color = o.get("eye", Color(1, 0.9, 0.2))
	var h: float = o.get("h", 1.0)
	var bulk: float = o.get("bulk", 1.0)
	var thin: bool = o.get("thin", false)
	var hunch: float = o.get("hunch", 0.0)
	var feats: Array = o.get("feats", [])
	var lw := 0.2 * bulk * (0.55 if thin else 1.0)
	var hip_y := 0.78 * h + (0.35 if feats.has("float") else 0.0)
	if feats.has("float"):
		_a(A, Gfx.pivot(root, Vector3.ZERO), 4, 0.0, 0.0, 1.0, true)
	if not feats.has("float"):
		for s in [-1.0, 1.0]:
			var hip := Gfx.pivot(root, Vector3(0.16 * bulk * s, hip_y, 0))
			Gfx.box(hip, Vector3(lw, hip_y, lw * 1.1), Vector3(0, -hip_y * 0.5, 0), c2)
			Gfx.box(hip, Vector3(lw * 1.25, 0.1, lw * 1.9), Vector3(0, -hip_y + 0.05, lw * 0.35), c2.darkened(0.3))
			_a(A, hip, 0, 0.75, 0.0 if s < 0 else PI)
	var tp := Gfx.pivot(root, Vector3(0, hip_y, 0))
	tp.rotation.x = hunch
	_a(A, tp, 4, 0.03, 0.0, 0.8, true)
	var tw := 0.5 * bulk * (0.7 if thin else 1.0)
	var th := 0.72 * h
	if feats.has("cloak"):
		var cl := Gfx.cyl(root, 0.32 * bulk, 0.6 * bulk, hip_y + 0.6, Vector3(0, (hip_y + 0.6) * 0.5 - 0.05 + (0.0 if not feats.has("float") else 0.0), 0), c2, false, 12)
		cl.material_override = Hero.glass(c2, 0.82, 0.3) if feats.has("float") else Gfx.mat(c2)
		_a(A, cl, 2, 0.03, 0.0, 0.7, true)
	Gfx.box(tp, Vector3(tw, th, 0.32 * bulk), Vector3(0, th * 0.5, 0), col)
	if thin:
		for i in 4:
			Gfx.box(tp, Vector3(tw * 1.05, 0.05, 0.2), Vector3(0, 0.15 + 0.14 * i, 0.08), c2)
	if feats.has("wrap"):
		for i in 5:
			var wb := Gfx.box(tp, Vector3(tw * 1.1, 0.07, 0.36 * bulk), Vector3(0, 0.1 + 0.14 * i, 0), c2)
			wb.rotation.z = 0.25 * (1 if i % 2 == 0 else -1)
	if feats.has("cracks") or feats.has("cracks_hot"):
		var cc := Color(1, 0.45, 0.1) if feats.has("cracks_hot") else Color(0.4, 0.9, 1)
		Gfx.box(tp, Vector3(0.05, 0.4, 0.04), Vector3(0.1, th * 0.5, 0.18 * bulk), cc, true)
		Gfx.box(tp, Vector3(0.2, 0.04, 0.04), Vector3(0.0, th * 0.4, 0.18 * bulk), cc, true)
		Gfx.sph(tp, 0.1, Vector3(-0.1, th * 0.7, 0.17 * bulk), cc, true)
	if feats.has("fur"):
		for i in 9:
			Gfx.sph(tp, 0.22, Vector3(sin(float(i) * 2.4) * 0.28 * bulk, 0.1 + float(i) * 0.08, 0.14 * bulk + cos(float(i) * 1.9) * 0.08), col, false, Vector3(1, 0.8, 0.7), 1.0)
	if feats.has("ice"):
		for s in [-1.0, 1.0]:
			Gfx.cyl(tp, 0.0, 0.12, 0.5, Vector3(0.48 * bulk * s, th + 0.05, 0), Color(0.75, 0.95, 1.0), true, 5).rotation.z = -0.35 * s
	if feats.has("spikes"):
		for i in 5:
			Gfx.cyl(tp, 0.0, 0.06, 0.3, Vector3((i - 2) * 0.1, th + 0.1, -0.1), Color(0.8, 0.2, 0.9), true, 4)
	# kepala
	var head := Gfx.pivot(tp, Vector3(0, th + 0.2, 0.05))
	if feats.has("skull"):
		Gfx.sph(head, 0.2, Vector3.ZERO, BONE, false, Vector3(1, 1.05, 1.0), 0.8)
		Gfx.box(head, Vector3(0.22, 0.1, 0.18), Vector3(0, -0.17, 0.05), BONE)
		_eyes(head, 0.02, 0.17, 0.08, 0.055, eye)
	else:
		Gfx.sph(head, 0.24 * (1.0 if not feats.has("tusks") else 0.9), Vector3.ZERO, col.lightened(0.05), false, Vector3(1.05, 1.0, 1.0), 0.8)
		_eyes(head, 0.04, 0.2, 0.1, 0.05, eye)
		Gfx.box(head, Vector3(0.2, 0.04, 0.04), Vector3(0, -0.1, 0.22), Color(0.15, 0.05, 0.05))
	if feats.has("ears"):
		for s in [-1.0, 1.0]:
			var ear := Gfx.cyl(head, 0.0, 0.09, 0.4, Vector3(0.3 * s, 0.05, 0), col, false, 4)
			ear.rotation.z = 1.35 * -s
	if feats.has("horns"):
		for s in [-1.0, 1.0]:
			var hn := Gfx.cyl(head, 0.0, 0.07, 0.4, Vector3(0.17 * s, 0.26, 0), BONE if not feats.has("flame") else Color(0.2, 0.05, 0.05), false, 6)
			hn.rotation.z = -0.5 * s
	if feats.has("tusks") or feats.has("fang"):
		for s in [-1.0, 1.0]:
			var tk := Gfx.cyl(head, 0.0, 0.035, 0.17, Vector3(0.09 * s, -0.14, 0.2), Color(1, 1, 0.9), false, 5)
			tk.rotation.x = PI
	if feats.has("crown"):
		Gfx.cyl(head, 0.2, 0.24, 0.16, Vector3(0, 0.26, 0), Color(0.85, 0.7, 0.2), true, 6)
		for i in 5:
			var ca := TAU * float(i) / 5.0
			Gfx.cyl(head, 0.0, 0.045, 0.14, Vector3(cos(ca) * 0.18, 0.4, sin(ca) * 0.18), Color(0.85, 0.7, 0.2), true, 4)
	if feats.has("flame"):
		for i in 4:
			var fl := Gfx.sph(head, 0.09, Vector3((i - 1.5) * 0.11, 0.32 + (i % 2) * 0.08, 0), Color(1, 0.55, 0.1), true, Vector3(0.7, 1.6, 0.7))
			_a(A, fl, 4, 0.05, float(i), 1.6, true)
	# lengan
	var arm_len := 0.5 * h
	for s in [-1.0, 1.0]:
		var sh := Gfx.pivot(tp, Vector3((tw * 0.5 + 0.08) * s, th - 0.1, 0))
		var aw := lw * 0.85
		Gfx.box(sh, Vector3(aw, arm_len, aw), Vector3(0, -arm_len * 0.5, 0), col if not thin else c2)
		Gfx.sph(sh, aw * 0.75, Vector3(0, -arm_len - 0.02, 0), col.darkened(0.15))
		if feats.has("armsout"):
			sh.rotation.x = -1.4
			_a(A, sh, 0, 0.1, float(s), 0.6, true)
		else:
			_a(A, sh, 0, 0.6, PI if s < 0 else 0.0)
		if s > 0:
			if feats.has("club"):
				var cb := Gfx.cyl(sh, 0.16, 0.06, 0.8, Vector3(0, -arm_len - 0.25, 0.1), Color(0.45, 0.3, 0.18), false, 7)
				cb.rotation.x = -0.4
			if feats.has("sword"):
				var bl := Gfx.box(sh, Vector3(0.07, 0.8, 0.02), Vector3(0, -arm_len - 0.4, 0.12), Color(0.75, 0.8, 0.88), false, 0.3, 0.8)
				bl.rotation.x = -0.5
		elif feats.has("shield"):
			Gfx.box(sh, Vector3(0.1, 0.6, 0.45), Vector3(-0.12, -arm_len, 0.05), c2, false, 0.4, 0.5)
			Gfx.box(sh, Vector3(0.12, 0.2, 0.2), Vector3(-0.18, -arm_len, 0.05), Color(0.9, 0.75, 0.2), true)
	if feats.has("wings"):
		for s in [-1.0, 1.0]:
			var wp := Gfx.pivot(tp, Vector3(0.15 * s, th * 0.8, -0.2))
			var w := Gfx.box(wp, Vector3(0.9, 0.05, 0.5), Vector3(0.45 * s, 0.0, -0.1), c2.darkened(0.1))
			w.rotation.z = 0.35 * s
			_a(A, wp, 2, 0.35, PI if s < 0 else 0.0, 1.4, true)
	if feats.has("orb"):
		var ob := Gfx.sph(root, 0.22, Vector3(0.6 * bulk, hip_y + th + 0.1, 0.3), eye, true)
		_a(A, ob, 4, 0.12, 0.0, 1.5, true)
	return hip_y + th + 0.5

# ------------------------------------------------------------------ quadruped
static func _quad(root: Node3D, A: Array, o: Dictionary) -> float:
	var col: Color = o.get("col", Color.GRAY)
	var eye: Color = o.get("eye", Color(1, 0.8, 0.2))
	var feats: Array = o.get("feats", [])
	var ln: float = o.get("len", 1.0)
	var w: float = o.get("w", 0.5)
	var ht: float = o.get("ht", 0.7)
	var ghost := feats.has("ghost")
	var body := Gfx.pivot(root, Vector3(0, ht, 0))
	_a(A, body, 4, 0.025, 0.0, 1.0, true)
	var bm := Gfx.box(body, Vector3(w, w * 0.9, ln), Vector3.ZERO, col, false, 0.9)
	if ghost:
		bm.material_override = Hero.glass(col, 0.62, 0.6)
	Gfx.sph(body, w * 0.6, Vector3(0, 0.05, ln * 0.35), col, false, Vector3(1, 0.95, 1.0))
	if feats.has("stripes"):
		for i in 4:
			Gfx.box(body, Vector3(w * 1.02, w * 0.6, 0.07), Vector3(0, 0.15, -ln * 0.35 + i * ln * 0.22), Color(0.15, 0.2, 0.45))
	var head := Gfx.pivot(body, Vector3(0, w * 0.25, ln * 0.55))
	Gfx.sph(head, w * 0.5, Vector3(0, 0, w * 0.2), col.lightened(0.05), false, Vector3(1, 0.9, 1.0))
	if feats.has("snout") or feats.has("fang"):
		Gfx.box(head, Vector3(w * 0.4, w * 0.3, w * 0.55), Vector3(0, -w * 0.1, w * 0.6), col.darkened(0.1))
		Gfx.sph(head, 0.045, Vector3(0, w * 0.02, w * 0.9), Color(0.05, 0.03, 0.03))
	_eyes(head, w * 0.2, w * 0.5, w * 0.25, 0.05, eye)
	if feats.has("fang"):
		for s in [-1.0, 1.0]:
			Gfx.cyl(head, 0.0, 0.03, 0.14, Vector3(0.08 * s, -w * 0.28, w * 0.7), Color(1, 1, 0.9), false, 5).rotation.x = PI
	if feats.has("ears"):
		for s in [-1.0, 1.0]:
			Gfx.cyl(head, 0.0, w * 0.18, w * 0.5, Vector3(w * 0.3 * s, w * 0.55, 0), col.darkened(0.1), false, 4)
	if feats.has("horns"):
		for s in [-1.0, 1.0]:
			var hn := Gfx.cyl(head, 0.0, 0.1, 0.65, Vector3(w * 0.5 * s, w * 0.4, 0.1), Color(0.95, 0.92, 0.82), false, 6)
			hn.rotation.z = -1.05 * s
	if feats.has("tail"):
		var tl := Gfx.pivot(body, Vector3(0, 0.05, -ln * 0.5))
		var tb := Gfx.cyl(tl, 0.02, 0.07, ln * 0.8, Vector3(0, 0.0, -ln * 0.35), col.darkened(0.15), false, 6)
		tb.rotation.x = PI / 2.0 + 0.3
		_a(A, tl, 3, 0.12, 0.0, 1.5, true)
	for fx in [-1.0, 1.0]:
		for fz in [-1.0, 1.0]:
			var lg := Gfx.pivot(root, Vector3(w * 0.4 * fx, ht - w * 0.3, ln * 0.35 * fz))
			Gfx.box(lg, Vector3(w * 0.28, ht, w * 0.28), Vector3(0, -ht * 0.5 + w * 0.3, 0), col.darkened(0.12))
			Gfx.box(lg, Vector3(w * 0.34, 0.07, w * 0.42), Vector3(0, -ht + w * 0.3 + 0.03, 0.05), col.darkened(0.35))
			_a(A, lg, 0, 0.7, 0.0 if (fx * fz) > 0 else PI)
	return ht + w * 1.1

# ------------------------------------------------------------------ bug
static func _bug(root: Node3D, A: Array, c: Color, style: String) -> float:
	var b := Gfx.pivot(root, Vector3(0, 0.38, 0))
	_a(A, b, 4, 0.02, 0.0, 1.0, true)
	if style == "hopper":
		Gfx.sph(b, 0.3, Vector3(0, 0.1, 0), c, false, Vector3(0.9, 0.8, 1.6))
		Gfx.sph(b, 0.22, Vector3(0, 0.28, 0.5), c.lightened(0.1))
		_eyes(b, 0.36, 0.62, 0.14, 0.09, Color(0.9, 0.15, 0.1))
		for s in [-1.0, 1.0]:
			var an := Gfx.cyl(b, 0.01, 0.015, 0.6, Vector3(0.1 * s, 0.6, 0.7), Color(0.2, 0.3, 0.1), false, 4)
			an.rotation.x = -0.6
			var lg := Gfx.pivot(b, Vector3(0.22 * s, 0.1, -0.25))
			Gfx.box(lg, Vector3(0.1, 0.55, 0.12), Vector3(0, 0.1, -0.15), c.darkened(0.2)).rotation.x = 0.5
			Gfx.box(lg, Vector3(0.08, 0.5, 0.1), Vector3(0, -0.15, -0.05), c.darkened(0.1))
			_a(A, lg, 0, 0.5, 0.0 if s < 0 else PI)
			var fl := Gfx.pivot(b, Vector3(0.18 * s, 0.25, 0.0))
			Gfx.box(fl, Vector3(0.04, 0.02, 0.8), Vector3(0.1 * s, 0, -0.45), Color(0.7, 0.9, 0.6, 0.8))
			_a(A, fl, 2, 0.4, 0.0, 2.0, true)
		return 1.0
	Gfx.sph(b, 0.4, Vector3(0, 0.0, 0), c, false, Vector3(1.1, 0.55, 1.3))
	Gfx.sph(b, 0.2, Vector3(0, 0.02, 0.5), c.lightened(0.05))
	_eyes(b, 0.15, 0.62, 0.1, 0.05, Color(1, 0.2, 0.1))
	for s in [-1.0, 1.0]:
		var cl := Gfx.pivot(b, Vector3(0.38 * s, 0.0, 0.62))
		Gfx.box(cl, Vector3(0.1, 0.1, 0.4), Vector3(0, 0, 0.18), c.darkened(0.15))
		Gfx.box(cl, Vector3(0.28, 0.08, 0.3), Vector3(0.0, 0.0, 0.45), c)
		_a(A, cl, 3, 0.07, 0.0 if s < 0 else PI, 1.4, true)
		for i in 3:
			var lg := Gfx.pivot(b, Vector3(0.3 * s, -0.1, -0.2 + 0.22 * i))
			Gfx.box(lg, Vector3(0.4, 0.05, 0.06), Vector3(0.22 * s, -0.08, 0), c.darkened(0.3))
			_a(A, lg, 2, 0.4, float(i) + (0.0 if s < 0 else PI))
	var tl := Gfx.pivot(b, Vector3(0, 0.05, -0.45))
	for i in 4:
		Gfx.sph(tl, 0.14 - 0.02 * i, Vector3(0, 0.1 + 0.18 * i, -0.15 - 0.1 * i + (0.0 if i < 3 else 0.2)), c.darkened(0.1))
	Gfx.cyl(tl, 0.0, 0.07, 0.25, Vector3(0, 0.78, 0.0), Color(0.95, 0.75, 0.2), true, 5).rotation.x = 2.2
	_a(A, tl, 0, 0.08, 0.0, 1.3, true)
	return 1.0

# ------------------------------------------------------------------ bersayap
static func _wing(root: Node3D, A: Array, style: String, boss: bool) -> float:
	var hv := 1.35 if style != "bat" else 1.0
	var b := Gfx.pivot(root, Vector3(0, hv, 0))
	_a(A, b, 4, 0.12, 0.0, 1.0, true)
	var col := Color(0.35, 0.3, 0.4)
	var wc := Color(0.45, 0.4, 0.55)
	var eye := Color(1, 0.3, 0.2)
	var span := 1.1
	if style == "eagle":
		col = Color(0.55, 0.42, 0.28) if not boss else Color(0.4, 0.5, 0.85)
		wc = Color(0.4, 0.3, 0.2) if not boss else Color(0.3, 0.4, 0.9)
		eye = Color(1, 0.85, 0.2)
		span = 1.2 if not boss else 1.6
		Gfx.sph(b, 0.3, Vector3.ZERO, col, false, Vector3(1, 0.9, 1.5))
		Gfx.sph(b, 0.2, Vector3(0, 0.15, 0.45), Color(0.95, 0.95, 0.95))
		Gfx.cyl(b, 0.0, 0.08, 0.25, Vector3(0, 0.1, 0.7), Color(1, 0.75, 0.2), false, 5).rotation.x = PI / 2.0
		_eyes(b, 0.22, 0.58, 0.1, 0.045, eye)
		for i in 3:
			Gfx.box(b, Vector3(0.06, 0.02, 0.5), Vector3((i - 1) * 0.1, 0.0, -0.75), wc)
		for s in [-1.0, 1.0]:
			Gfx.cyl(b, 0.01, 0.03, 0.25, Vector3(0.12 * s, -0.4, 0.1), Color(0.9, 0.7, 0.2), false, 4)
		if boss:
			for i in 5:
				Gfx.cyl(b, 0.0, 0.04, 0.4, Vector3((i - 2) * 0.12, 0.38, -0.2), Color(1, 0.95, 0.3), true, 4).rotation.x = -0.4
	elif style == "bat":
		col = Color(0.3, 0.25, 0.3)
		wc = Color(0.28, 0.2, 0.3)
		span = 0.9
		Gfx.sph(b, 0.22, Vector3.ZERO, col, false, Vector3(1, 1, 1.2))
		Gfx.sph(b, 0.17, Vector3(0, 0.1, 0.3), col.lightened(0.05))
		for s in [-1.0, 1.0]:
			Gfx.cyl(b, 0.0, 0.05, 0.22, Vector3(0.1 * s, 0.3, 0.3), col, false, 4)
			Gfx.cyl(b, 0.0, 0.015, 0.1, Vector3(0.05 * s, -0.08, 0.42), Color(1, 1, 0.9), false, 4).rotation.x = PI
		_eyes(b, 0.14, 0.42, 0.07, 0.04, eye)
	else:
		col = Color(0.65, 0.2, 0.12) if not boss else Color(0.45, 0.1, 0.1)
		wc = Color(0.5, 0.12, 0.1)
		eye = Color(1, 0.9, 0.2)
		span = 1.4 if not boss else 2.0
		Gfx.sph(b, 0.35, Vector3.ZERO, col, false, Vector3(1, 0.9, 1.5))
		var neck := Gfx.cyl(b, 0.12, 0.2, 0.6, Vector3(0, 0.25, 0.55), col, false, 8)
		neck.rotation.x = 0.7
		Gfx.sph(b, 0.22, Vector3(0, 0.55, 0.85), col.lightened(0.05), false, Vector3(0.9, 0.85, 1.4))
		_eyes(b, 0.62, 0.95, 0.1, 0.05, eye)
		for s in [-1.0, 1.0]:
			Gfx.cyl(b, 0.0, 0.05, 0.4, Vector3(0.1 * s, 0.75, 0.7), Color(0.95, 0.9, 0.8), false, 5).rotation.x = -0.9
		var tl := Gfx.pivot(b, Vector3(0, 0, -0.5))
		var tb := Gfx.cyl(tl, 0.02, 0.15, 1.3, Vector3(0, 0, -0.6), col.darkened(0.1), false, 6)
		tb.rotation.x = PI / 2.0
		Gfx.cyl(tl, 0.0, 0.12, 0.3, Vector3(0, 0, -1.35), Color(0.95, 0.85, 0.3), false, 4).rotation.x = -PI / 2.0
		_a(A, tl, 3, 0.2, 0.0, 1.2, true)
	for s in [-1.0, 1.0]:
		var wp := Gfx.pivot(b, Vector3(0.2 * s, 0.1, 0))
		var arm := Gfx.box(wp, Vector3(span, 0.05, 0.12), Vector3(span * 0.5 * s, 0, 0), col.darkened(0.1))
		var mem := Gfx.box(wp, Vector3(span * 0.95, 0.025, 0.55), Vector3(span * 0.5 * s, 0, -0.25), wc)
		mem.material_override = Gfx.mat(wc)
		arm.rotation.z = 0.0
		_a(A, wp, 2, 0.75, PI if s < 0 else 0.0, 1.9 if style == "bat" else 1.2, true)
	return hv + 0.7

# ------------------------------------------------------------------ ular / naga
static func _serpent(root: Node3D, A: Array, c: Color, big: bool) -> float:
	var n := 9
	for i in n:
		var r := 0.3 - 0.022 * float(i)
		if big:
			r += 0.05
		var seg := Gfx.pivot(root, Vector3(0, 0.0, 0))
		var y := r + maxf(0.0, float(3 - i)) * 0.2
		var z := 0.5 - float(i) * 0.33
		Gfx.sph(seg, r, Vector3(0, y, z), c.lerp(Color(0.9, 0.9, 0.5), 0.35 if i % 2 == 0 else 0.0), false, Vector3(1, 0.9, 1.1))
		_a(A, seg, 3, 0.18, float(i) * 0.7, 0.8, true)
	var head := Gfx.pivot(root, Vector3(0, 0.95, 0.65))
	Gfx.sph(head, 0.3, Vector3.ZERO, c.lightened(0.05), false, Vector3(1.0, 0.8, 1.3))
	_eyes(head, 0.1, 0.25, 0.14, 0.06, Color(1, 0.9, 0.1))
	for s in [-1.0, 1.0]:
		Gfx.cyl(head, 0.0, 0.025, 0.2, Vector3(0.07 * s, -0.17, 0.3), Color(1, 1, 0.9), false, 4).rotation.x = PI
		if big:
			var hood := Gfx.box(head, Vector3(0.5, 0.45, 0.05), Vector3(0.28 * s, 0.0, -0.1), c.darkened(0.2))
			hood.rotation.y = 0.5 * s
	if big:
		for i in 4:
			Gfx.cyl(head, 0.0, 0.05, 0.3, Vector3((i - 1.5) * 0.12, 0.3, -0.1), Color(0.85, 0.95, 1.0), true, 4)
	return 1.4

# ------------------------------------------------------------------ ent
static func _ent(root: Node3D, A: Array) -> float:
	var b := Gfx.pivot(root, Vector3.ZERO)
	_a(A, b, 2, 0.02, 0.0, 0.7, true)
	Gfx.cyl(b, 0.35, 0.55, 1.6, Vector3(0, 0.8, 0), Color(0.35, 0.24, 0.14), false, 8)
	for s in [-1.0, 1.0]:
		var r := Gfx.cyl(b, 0.1, 0.18, 0.7, Vector3(0.45 * s, 0.2, 0.1), Color(0.3, 0.2, 0.12), false, 6)
		r.rotation.z = 0.7 * s
		var arm := Gfx.pivot(b, Vector3(0.38 * s, 1.3, 0))
		Gfx.cyl(arm, 0.1, 0.16, 0.9, Vector3(0.1 * s, -0.35, 0.1), Color(0.33, 0.22, 0.13), false, 6).rotation.z = 0.3 * s
		_a(A, arm, 0, 0.5, 0.0 if s < 0 else PI)
	_eyes(b, 1.35, 0.33, 0.14, 0.06, Color(1, 0.8, 0.2))
	Gfx.box(b, Vector3(0.3, 0.06, 0.05), Vector3(0, 1.1, 0.4), Color(0.1, 0.05, 0.02))
	for i in 5:
		var a := TAU * float(i) / 5.0
		Gfx.sph(b, 0.55, Vector3(cos(a) * 0.45, 1.9 + sin(float(i) * 3.0) * 0.12, sin(a) * 0.45), Color(0.15, 0.5, 0.25), false, Vector3(1, 0.8, 1))
	Gfx.sph(b, 0.6, Vector3(0, 2.15, 0), Color(0.18, 0.55, 0.28), false, Vector3(1, 0.8, 1))
	return 2.6

# ------------------------------------------------------------------ chaos
static func _orb_eye(root: Node3D, A: Array, boss: bool) -> float:
	var b := Gfx.pivot(root, Vector3(0, 1.2, 0))
	_a(A, b, 4, 0.18, 0.0, 0.9, true)
	var core := Gfx.sph(b, 0.5, Vector3.ZERO, Color(0.15, 0.04, 0.25), false, Vector3.ONE, 0.3, 0.3)
	core.material_override = Hero.glass(Color(0.5, 0.1, 0.8), 0.8, 0.5)
	Gfx.sph(b, 0.22, Vector3(0, 0, 0.36), Color(1, 0.95, 0.9), true)
	Gfx.sph(b, 0.1, Vector3(0, 0, 0.5), Color(0.9, 0.1, 0.5), true)
	var sp := Gfx.pivot(b, Vector3.ZERO)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var c := Gfx.cyl(sp, 0.0, 0.07, 0.5, Vector3(cos(a) * 0.6, sin(a * 2.0) * 0.2, sin(a) * 0.6), Color(0.85, 0.2, 0.95), true, 4)
		c.basis = Basis(Vector3.UP, -a) * Basis(Vector3.BACK, -PI / 2.0)
	_a(A, sp, 2, 0.4, 0.0, 0.6, true)
	if boss:
		Gfx.cyl(b, 0.28, 0.35, 0.3, Vector3(0, 0.8, 0), Color(0.95, 0.75, 0.25), true, 6)
		for i in 6:
			var a2 := TAU * float(i) / 6.0
			Gfx.cyl(b, 0.0, 0.06, 0.28, Vector3(cos(a2) * 0.3, 1.1, sin(a2) * 0.3), Color(0.95, 0.75, 0.25), true, 4)
	return 2.2 if boss else 1.9

# ------------------------------------------------------------------ NPC
static func npc(kind: String, col: Color) -> Dictionary:
	var root := Node3D.new()
	var A: Array = []
	var top := col
	var bot := col.darkened(0.45)
	var hair := Color(0.25, 0.17, 0.1)
	var skin := Color(0.95, 0.78, 0.64)
	var h := 2.0
	match kind:
		"forge":
			top = Color(0.35, 0.28, 0.25)
			bot = Color(0.2, 0.17, 0.15)
			hair = Color(0.6, 0.25, 0.1)
		"shop_class":
			hair = Color(0.8, 0.86, 0.98)
		"shop_potion":
			hair = Color(0.95, 0.85, 0.5)
		"market":
			hair = Color(0.35, 0.25, 0.15)
		"jewel":
			hair = Color(0.85, 0.85, 0.95)
		"karu":
			hair = Color(0.15, 0.1, 0.08)
		"gate":
			hair = Color(0.2, 0.2, 0.25)
		"camp":
			hair = Color(0.4, 0.3, 0.2)
	if kind == "quest":
		Gfx.cyl(root, 0.08, 0.1, 2.2, Vector3(-0.8, 1.1, 0), Color(0.4, 0.27, 0.15), false, 6)
		Gfx.cyl(root, 0.08, 0.1, 2.2, Vector3(0.8, 1.1, 0), Color(0.4, 0.27, 0.15), false, 6)
		Gfx.box(root, Vector3(1.8, 1.1, 0.1), Vector3(0, 1.5, 0), Color(0.5, 0.35, 0.2))
		for i in 4:
			Gfx.box(root, Vector3(0.35, 0.45, 0.02), Vector3(-0.6 + i * 0.4, 1.5 + (i % 2) * 0.1, 0.07), Color(0.95, 0.9, 0.7))
		Gfx.box(root, Vector3(0.2, 0.2, 0.02), Vector3(0.0, 2.0, 0.08), Color(1, 0.85, 0.2), true)
		root.set_meta("h", 2.6)
		return {"root": root, "anim": A, "h": 2.6}
	if kind == "gate":
		for s in [-1.0, 1.0]:
			Gfx.box(root, Vector3(0.45, 2.4, 0.45), Vector3(0.9 * s, 1.2, 0), Color(0.45, 0.45, 0.5))
			Gfx.box(root, Vector3(0.6, 0.2, 0.6), Vector3(0.9 * s, 2.45, 0), Color(0.6, 0.55, 0.4))
		Gfx.box(root, Vector3(2.3, 0.35, 0.5), Vector3(0, 2.4, 0), Color(0.5, 0.5, 0.55))
		var orb := Gfx.sph(root, 0.4, Vector3(0, 1.3, 0), Color(0.3, 0.85, 1.0), true)
		_a(A, orb, 4, 0.12, 0.0, 1.2, true)
		var rg := Gfx.ring(root, 0.55, 0.65, Vector3(0, 1.3, 0), Color(0.5, 0.95, 1.0))
		rg.rotation.x = PI / 2.0
		rg.scale = Vector3(1, 1, 1)
		_a(A, rg, 2, 0.5, 0.0, 1.0, true)
		root.set_meta("h", 2.9)
		return {"root": root, "anim": A, "h": 2.9}
	# ----- humanoid NPC
	Gfx.box(root, Vector3(0.52, 0.2, 0.3), Vector3(0, 0.95, 0), bot)
	for s in [-1.0, 1.0]:
		Gfx.box(root, Vector3(0.2, 0.75, 0.22), Vector3(0.14 * s, 0.45, 0), bot)
		Gfx.box(root, Vector3(0.24, 0.12, 0.38), Vector3(0.14 * s, 0.06, 0.06), Color(0.2, 0.13, 0.1))
	var body := Gfx.pivot(root, Vector3.ZERO)
	_a(A, body, 4, 0.012, 0.0, 0.9, true)
	Gfx.box(body, Vector3(0.6, 0.6, 0.34), Vector3(0, 1.35, 0), top)
	Gfx.box(body, Vector3(0.64, 0.07, 0.38), Vector3(0, 1.08, 0), Color(0.35, 0.22, 0.1))
	for s in [-1.0, 1.0]:
		var ar := Gfx.pivot(body, Vector3(0.4 * s, 1.58, 0))
		Gfx.box(ar, Vector3(0.16, 0.6, 0.16), Vector3(0, -0.3, 0), top)
		Gfx.sph(ar, 0.08, Vector3(0, -0.64, 0), skin)
		ar.rotation.x = -0.15
		if s > 0 and (kind == "forge" or kind == "gate"):
			ar.rotation.x = -0.6
	var head := Gfx.pivot(body, Vector3(0, 1.88, 0))
	Gfx.sph(head, 0.25, Vector3.ZERO, skin, false, Vector3(1, 1.05, 1), 0.7)
	Gfx.sph(head, 0.27, Vector3(0, 0.05, -0.03), hair, false, Vector3(1, 0.82, 1.02), 0.8)
	_eyes(head, -0.01, 0.22, 0.09, 0.04, Color(0.1, 0.1, 0.15))
	match kind:
		"forge":
			Gfx.box(body, Vector3(0.5, 0.7, 0.05), Vector3(0, 1.1, 0.19), Color(0.2, 0.15, 0.12))
			Gfx.sph(head, 0.2, Vector3(0, -0.2, 0.1), Color(0.55, 0.22, 0.1), false, Vector3(1, 0.9, 0.8))
			Gfx.box(root, Vector3(0.9, 0.5, 0.6), Vector3(1.1, 0.25, 0.3), Color(0.25, 0.25, 0.3), false, 0.4, 0.6)
			Gfx.box(root, Vector3(1.0, 0.12, 0.7), Vector3(1.1, 0.55, 0.3), Color(0.35, 0.35, 0.4), false, 0.3, 0.7)
			var hm := Gfx.box(body, Vector3(0.12, 0.12, 0.5), Vector3(0.55, 1.05, 0.35), Color(0.4, 0.4, 0.45), false, 0.3, 0.7)
			hm.rotation.x = 0.3
			Gfx.sph(root, 0.12, Vector3(1.1, 0.7, 0.3), Color(1, 0.45, 0.1), true)
		"shop_class":
			Gfx.box(body, Vector3(0.1, 0.1, 1.1), Vector3(0.0, 1.3, -0.3), Color(0.35, 0.4, 0.5), false, 0.3, 0.6).rotation.x = 0.7
			Gfx.sph(head, 0.3, Vector3(0, 0.1, -0.02), Color(0.3, 0.4, 0.6), false, Vector3(1, 0.62, 1.04), 0.45, 0.4)
			Gfx.box(head, Vector3(0.46, 0.07, 0.1), Vector3(0, 0.03, 0.19), Color(0.4, 0.9, 1.0), true)
		"shop_potion":
			Gfx.cyl(root, 0.34, 0.6, 0.7, Vector3(0, 0.45, 0), top, false, 10)
			Gfx.cyl(head, 0.0, 0.34, 0.4, Vector3(0, 0.3, 0), Color(0.25, 0.55, 0.35), false, 8)
			var bt := Gfx.pivot(root, Vector3(0.7, 0.3, 0.2))
			Gfx.cyl(bt, 0.18, 0.2, 0.5, Vector3(0, 0.25, 0), Color(0.95, 0.2, 0.25, 1), true, 8)
			Gfx.cyl(bt, 0.07, 0.1, 0.18, Vector3(0, 0.58, 0), Color(0.7, 0.5, 0.3), false, 6)
		"market":
			Gfx.cyl(head, 0.38, 0.38, 0.05, Vector3(0, 0.22, 0), Color(0.6, 0.4, 0.2), false, 12)
			Gfx.cyl(head, 0.2, 0.25, 0.25, Vector3(0, 0.36, 0), Color(0.6, 0.4, 0.2), false, 12)
			Gfx.sph(root, 0.42, Vector3(-0.75, 0.38, 0.1), Color(0.75, 0.62, 0.4), false, Vector3(1, 1.1, 1))
			Gfx.box(root, Vector3(0.9, 0.08, 0.7), Vector3(0.9, 0.95, 0.4), Color(0.5, 0.35, 0.2))
			Gfx.sph(root, 0.12, Vector3(0.75, 1.1, 0.4), Color(0.9, 0.2, 0.2))
			Gfx.sph(root, 0.12, Vector3(1.0, 1.1, 0.4), Color(0.95, 0.8, 0.2))
		"jewel":
			Gfx.cyl(root, 0.34, 0.62, 0.75, Vector3(0, 0.45, 0), Color(0.45, 0.25, 0.65), false, 10)
			Gfx.cyl(head, 0.0, 0.3, 0.5, Vector3(0, 0.38, 0), Color(0.4, 0.2, 0.6), false, 8)
			var cr := Gfx.cyl(root, 0.0, 0.25, 0.7, Vector3(0.85, 1.1, 0.2), Color(0.85, 0.5, 1.0), true, 5)
			_a(A, cr, 4, 0.1, 0.0, 1.4, true)
			Gfx.cyl(root, 0.25, 0.0, 0.5, Vector3(0.85, 0.5, 0.2), Color(0.85, 0.5, 1.0), true, 5)
		"karu":
			Gfx.sph(head, 0.3, Vector3(0, 0.12, 0), Color(0.9, 0.55, 0.15), false, Vector3(1.1, 0.8, 1.1))
			Gfx.sph(head, 0.06, Vector3(0, 0.2, 0.3), Color(1, 0.2, 0.3), true)
			Gfx.sph(root, 0.2, Vector3(0.7, 0.25, 0.2), Color(1, 0.8, 0.25), true, Vector3(1, 0.5, 1))
		"gate":
			Gfx.box(body, Vector3(0.7, 0.4, 0.4), Vector3(0, 1.55, 0), Color(0.45, 0.45, 0.55), false, 0.3, 0.6)
			Gfx.sph(head, 0.3, Vector3(0, 0.1, -0.02), Color(0.5, 0.5, 0.6), false, Vector3(1, 0.7, 1.04), 0.4, 0.5)
			Gfx.cyl(root, 0.03, 0.03, 2.4, Vector3(0.65, 1.2, 0.3), Color(0.55, 0.4, 0.2), false, 6)
			Gfx.cyl(root, 0.0, 0.08, 0.35, Vector3(0.65, 2.55, 0.3), Color(0.8, 0.85, 0.9), false, 4)
		"camp":
			Gfx.box(body, Vector3(0.5, 0.6, 0.3), Vector3(0, 1.4, -0.3), Color(0.5, 0.35, 0.2))
			Gfx.sph(head, 0.28, Vector3(0, 0.16, 0), Color(0.4, 0.5, 0.3), false, Vector3(1.1, 0.55, 1.1))
			var tn := Gfx.prism(root, Vector3(1.5, 1.2, 1.2), Vector3(1.2, 0.6, 0.2), Color(0.8, 0.7, 0.45))
			tn.rotation.y = 0.2
	# tanda seru role-play
	var mk := Gfx.sph(root, 0.1, Vector3(0, 2.75, 0), Color(1, 0.9, 0.2), true, Vector3(0.7, 1.4, 0.7))
	_a(A, mk, 4, 0.08, 0.0, 1.8, true)
	root.set_meta("h", 2.5)
	return {"root": root, "anim": A, "h": h + 0.5}
