class_name Monster
extends Node3D

var world
var sp: Dictionary = {}
var kind := 0
var lv := 1
var lv_off := 0
var mname := ""
var hp := 1.0
var max_hp := 1.0
var atk := 1.0
var home := Vector3.ZERO
var dead := false
var speed := 3.4
var atk_t := 0.0
var slow_t := 0.0
var wander := Vector3.ZERO
var wander_t := 0.0
var aggro := false
var color := Color.WHITE
var map_min := 1
var map_max := 20
var map_sets: Array = []
var fixed_level := 1
var stat_factor := 1.0
var exp_factor := 1.0
var label: Label3D
var body: Node3D
var model: Node3D
var anim: Array = []
var mh := 1.4
var bar: MeshInstance3D
var bar_mat: ShaderMaterial
var ring: Node3D
var moving := false
var sc := 1.0
var _t := 0.0
var _flash := 0.0
var _lunge := 0.0

func setup(w, spd: Dictionary, mi: Dictionary, k: int, nm: String, off: int) -> void:
	world = w
	sp = spd
	kind = k
	mname = nm
	lv_off = off
	color = mi.mc
	map_min = mi.min
	map_max = mi.max
	map_sets = mi.sets
	# Level monster berasal dari spot map, bukan level karakter.
	# Fallback ini menjaga kompatibilitas dengan spawn lama.
	fixed_level = clampi(int(spd.get("level", map_min + off)), map_min, map_max)
	position = spd.pos
	home = position
	sc = [1.0, 1.5, 2.6][k]
	sync_level(true)

const BAR_SHADER := """
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;
uniform float ratio = 1.0;
uniform vec4 fill : source_color = vec4(0.9, 0.1, 0.1, 1.0);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	vec3 c = vec3(0.78, 0.6, 0.28);
	bool inner = UV.x > 0.02 && UV.x < 0.98 && UV.y > 0.18 && UV.y < 0.82;
	if (inner) {
		if (UV.x < ratio) {
			c = fill.rgb * (1.0 + 0.35 * (0.5 - abs(UV.y - 0.35)));
		} else {
			c = vec3(0.1, 0.03, 0.03);
		}
	}
	ALBEDO = c;
}
"""
static var _bar_sh: Shader

func _ready() -> void:
	var built := Models.monster(mname, color, kind)
	model = built.root
	anim = built.anim
	mh = float(built.h)
	body = Node3D.new()
	body.scale = Vector3(sc, sc, sc)
	add_child(body)
	body.add_child(model)
	# cincin kaki: elite oranye, boss merah (seperti cincin aura di screenshot Laghaim)
	if kind > 0:
		ring = Gfx.pivot(self, Vector3(0, 0.05, 0))
		var rc := Color(1.0, 0.6, 0.15) if kind == 1 else Color(1.0, 0.2, 0.2)
		Gfx.ring(ring, 0.9 * sc, 1.05 * sc, Vector3.ZERO, rc)
		if kind == 2:
			Gfx.ring(ring, 1.2 * sc, 1.3 * sc, Vector3.ZERO, Color(1.0, 0.7, 0.2))
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, (mh + 0.55) * sc + 0.3, 0)
	label.font_size = 38
	label.pixel_size = 0.009
	label.outline_size = 12
	label.no_depth_test = true
	add_child(label)
	if _bar_sh == null:
		_bar_sh = Shader.new()
		_bar_sh.code = BAR_SHADER
	bar_mat = ShaderMaterial.new()
	bar_mat.shader = _bar_sh
	var qm := QuadMesh.new()
	qm.size = Vector2(1.5, 0.2)
	bar = MeshInstance3D.new()
	bar.mesh = qm
	bar.material_override = bar_mat
	bar.position = Vector3(0, (mh + 0.55) * sc + 0.02, 0)
	add_child(bar)
	_update_label()

func sync_level(first: bool = false) -> void:
	# Monster di world tetap pada level spot-nya. Tidak ada rubber-band
	# scaling terhadap level karakter saat pemain naik level.
	lv = fixed_level
	stat_factor = 1.0
	exp_factor = 1.0
	var ratio := 1.0 if first else hp / max_hp
	max_hp = Scaling.mons_hp(lv, kind) * stat_factor
	hp = max_hp * ratio
	atk = Scaling.mons_atk(lv, kind) * stat_factor
	_update_label()

func _update_label() -> void:
	if label == null:
		return
	var pre := "" if kind == 0 else ("[ELITE] " if kind == 1 else "[BOSS] ")
	label.text = "Lv%d %s%s" % [lv, pre, mname]
	label.modulate = Color(1, 1, 1) if kind == 0 else (Color(1, 0.72, 0.3) if kind == 1 else Color(1, 0.4, 0.4))
	if bar_mat != null:
		bar_mat.set_shader_parameter("ratio", clampf(hp / max_hp, 0.0, 1.0))
		bar_mat.set_shader_parameter("fill", Color(0.9, 0.12, 0.1) if kind == 0 else (Color(1.0, 0.55, 0.1) if kind == 1 else Color(0.85, 0.1, 0.5)))

func hit(dmg: float, crit: bool = false, slow: float = 0.0) -> void:
	if dead:
		return
	hp -= dmg
	aggro = true
	_flash = 0.14
	if slow > 0.0:
		slow_t = slow
	world.float_text(position + Vector3(0, 1.8 * sc + 0.6, 0), str(int(dmg)) + ("!" if crit else ""), Color(1, 0.9, 0.3) if crit else Color(1, 1, 1))
	_update_label()
	if hp <= 0.0:
		die()

func die() -> void:
	dead = true
	G.on_kill(self)
	world.on_mon_died(self)
	world.spawn_crystals(position, 1 + kind * 2, Color(0.75, 0.55, 1.0) if kind < 2 else Color(1, 0.8, 0.3))
	world.float_text(position + Vector3(0, 2.4 * sc, 0), "+%s EXP" % Scaling.fmt(int(Scaling.exp_kill(lv) * float(G.settings.exp_mult) / 1000.0 * [1.0, 3.0, 20.0][kind] * exp_factor)), Color(0.5, 1, 0.5))
	label.visible = false
	bar.visible = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(body, "scale", Vector3(0.01, 0.01, 0.01), 0.45)
	tw.tween_property(body, "rotation:z", 1.2, 0.45)
	tw.chain()
	tw.tween_callback(queue_free)

func _move_to(t: Vector3, s: float, delta: float) -> void:
	var dir := t - position
	dir.y = 0
	if dir.length() < 0.01:
		return
	dir = dir.normalized()
	moving = true
	position += dir * s * delta
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8.0 * delta)

func _process(delta: float) -> void:
	if dead or world.player == null:
		return
	_t += delta
	moving = false
	_flash = maxf(0.0, _flash - delta)
	_lunge = maxf(0.0, _lunge - delta * 3.0)
	var sq := 1.0 + _flash * 1.2
	body.scale = Vector3(sc * sq, sc / sq, sc * sq)
	body.position = Vector3(0, 0, _lunge * 0.9)
	if ring != null:
		ring.rotation.y += delta * 1.4
	var pp: Vector3 = world.player.position
	var d := position.distance_to(pp)
	slow_t -= delta
	atk_t -= delta
	var spd := speed * (0.5 if slow_t > 0.0 else 1.0)
	var calm: bool = world.in_peace(pp) or world.player.dead
	if aggro and (calm or d > 32.0 or position.distance_to(home) > 40.0):
		aggro = false
	if not aggro and not calm and d < (10.0 if kind == 0 else 13.0):
		aggro = true
	if aggro:
		if d > 2.4 * sc:
			_move_to(pp, spd, delta)
		elif atk_t <= 0.0:
			atk_t = 1.5 if kind < 2 else 1.2
			_lunge = 1.0
			world.player.take_damage(atk)
	else:
		wander_t -= delta
		if wander_t <= 0.0:
			wander_t = randf_range(2.0, 5.0)
			wander = home + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
		if position.distance_to(wander) > 0.5:
			_move_to(wander, spd * 0.5, delta)
	Models.animate(anim, _t, moving)
