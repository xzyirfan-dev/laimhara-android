class_name Player
extends Node3D

var world
var dead := false
var atk_cd := 0.0
var cds: Dictionary = {}
var hit_t := 99.0
var pot_cd := 0.0
var speed := 7.5
var half := 55.0
var hero: Hero
var tag: Label3D
var is_moving := false
var _look := ""

func _ready() -> void:
	hero = Hero.new()
	add_child(hero)
	_rebuild()
	tag = Label3D.new()
	tag.text = G.player_name
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.75, 0)
	tag.font_size = 44
	tag.pixel_size = 0.0085
	tag.outline_size = 14
	tag.modulate = Color(0.75, 0.95, 1.0)
	tag.no_depth_test = true
	add_child(tag)

func _look_key() -> String:
	return G.look_key()

func _rebuild() -> void:
	_look = _look_key()
	hero.hair_col = Data.HAIR_COLORS[G.hair_idx].c
	hero.build_eq(G.equipped)
	G.look_changed.emit()

func attack_range() -> float:
	return 9.0 + G.snipe_range()

func alive_monsters() -> Array:
	var out: Array = []
	for m in world.monsters:
		if is_instance_valid(m) and not m.dead:
			out.append(m)
	return out

func nearest(maxd: float) -> Monster:
	var best: Monster = null
	var bd := maxd
	for m in alive_monsters():
		var d := position.distance_to(m.position)
		if d < bd:
			bd = d
			best = m
	return best

func _face(p: Vector3) -> void:
	var dir := p - position
	dir.y = 0
	if dir.length() > 0.01:
		rotation.y = atan2(dir.x, dir.z)

func try_attack() -> bool:
	if atk_cd > 0.0 or dead:
		return false
	var m := nearest(attack_range())
	if m == null:
		return false
	atk_cd = 0.8
	var h := G.calc_hit(1.0)
	_face(m.position)
	m.hit(h.dmg, h.crit)
	hero.fire()
	world.fx_shot(hero.muzzle.global_position, m.position + Vector3(0, 1.0, 0), Color(0.4, 0.85, 1.0), 0.07)
	G.skill_use("marks")
	return true

func _spend(d: Dictionary, cost: int) -> void:
	hero.fire()
	G.mp -= cost
	cds[d.id] = d.cd
	G.skill_use(d.id)

func cast(i: int) -> void:
	if dead:
		return
	var acts := Data.actives()
	if i >= acts.size():
		return
	var d: Dictionary = acts[i]
	if G.lv < d.unlock:
		G.toast.emit("%s terbuka di Lv %d" % [d.short, d.unlock], false)
		return
	if float(cds.get(d.id, 0.0)) > 0.0:
		return
	var cost := int((6.0 + 0.8 * float(G.lv)) * d.f)
	if G.mp < cost:
		G.toast.emit("MP tidak cukup", false)
		return
	var sl: int = G.skill_lv(d.id)
	var sb := 1.0 + 0.04 * float(sl - 1)
	var r := attack_range() * 1.2
	var origin: Vector3 = hero.muzzle.global_position
	match d.id:
		"power":
			var m := nearest(r)
			if m == null:
				return
			_spend(d, cost)
			var h := G.calc_hit(2.2 * sb)
			_face(m.position)
			m.hit(h.dmg, h.crit)
			world.fx_shot(origin, m.position + Vector3(0, 1, 0), Color(1, 0.9, 0.3), 0.15)
		"shield":
			_spend(d, cost)
			G.shield_t = 12.0
			G.shield_frac = 0.05 + float(sl - 1) * 0.45 / 24.0
			world.fx_ring(position, 2.5, Color(0.3, 0.7, 1.0))
		"semi":
			var m := nearest(r)
			if m == null:
				return
			_spend(d, cost)
			for n in 3:
				if is_instance_valid(m) and not m.dead:
					var h := G.calc_hit(1.2 * sb)
					m.hit(h.dmg, h.crit)
					world.fx_shot(origin, m.position + Vector3(0, 1, 0), Color(1, 0.6, 0.2))
				await get_tree().create_timer(0.12).timeout
		"frozen":
			var m := nearest(r)
			if m == null:
				return
			_spend(d, cost)
			var h := G.calc_hit(4.0 * sb)
			m.hit(h.dmg, h.crit, 4.0)
			world.fx_shot(origin, m.position + Vector3(0, 1, 0), Color(0.6, 0.9, 1.0), 0.18)
		"air":
			var list := []
			for m in alive_monsters():
				if position.distance_to(m.position) < 8.0:
					list.append(m)
			if list.is_empty():
				return
			_spend(d, cost)
			world.fx_ring(position, 8.0, Color(1, 0.5, 0.2))
			for m in list:
				var h := G.calc_hit(5.0 * sb)
				m.hit(h.dmg, h.crit)
		"fire":
			var pool := []
			for m in alive_monsters():
				if position.distance_to(m.position) < 14.0:
					pool.append(m)
			if pool.is_empty():
				return
			_spend(d, cost)
			for n in 10:
				var m: Monster = pool.pick_random()
				if is_instance_valid(m) and not m.dead:
					var h := G.calc_hit(2.0 * sb)
					m.hit(h.dmg, h.crit)
					world.fx_shot(origin, m.position + Vector3(0, 1, 0), Color(1, 0.3, 0.3))
				await get_tree().create_timer(0.08).timeout

func take_damage(raw: float) -> void:
	if dead:
		return
	if randf() < G.evade_chance():
		world.float_text(position + Vector3(0, 2.6, 0), "EVADE", Color(0.6, 0.9, 1.0))
		return
	var d := G.dmg_taken(raw)
	if G.shield_t > 0.0:
		d *= 1.0 - G.shield_frac
	G.hp -= d
	hit_t = 0.0
	world.float_text(position + Vector3(0, 2.6, 0), "-%d" % int(d), Color(1, 0.35, 0.35))
	if G.hp <= 0.0:
		dead = true
		world.player_died()

func _camera_relative_direction(input_vec: Vector2) -> Vector3:
	"""Map joystick screen input to the camera's horizontal ground plane.

	The joystick uses screen coordinates (right = +X, down = +Y), while the
	player lives in world X/Z coordinates. Using the camera basis keeps the
	controls correct after any free-orbit rotation or pitch change.
	"""
	var v := input_vec.limit_length(1.0)
	if world == null or world.cam == null or v.length_squared() < 0.0001:
		return Vector3(v.x, 0.0, v.y)
	var cam_basis: Basis = world.cam.global_transform.basis
	var screen_right := Vector3(cam_basis.x.x, 0.0, cam_basis.x.z).normalized()
	var screen_forward := Vector3(-cam_basis.z.x, 0.0, -cam_basis.z.z).normalized()
	var dir := screen_right * v.x + screen_forward * (-v.y)
	return dir.normalized() if dir.length_squared() > 0.0001 else Vector3.ZERO

func _process(delta: float) -> void:
	if dead:
		return
	if _look != _look_key():
		_rebuild()
	atk_cd -= delta
	hit_t += delta
	pot_cd -= delta
	for k in cds.keys():
		cds[k] = float(cds[k]) - delta
	var jv := G.joy
	var kv := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if kv.length() > 0.1:
		jv = kv
	speed = 7.5 * G.move_mult()
	var moving := jv.length() > 0.15
	is_moving = moving
	if moving:
		var dir := _camera_relative_direction(jv)
		position += dir * speed * delta
		_face(position + dir)
	elif bool(G.settings.auto_hunt) and not world.map.town:
		var m := nearest(70.0)
		if m != null:
			if position.distance_to(m.position) > attack_range() * 0.7:
				var dir := (m.position - position)
				dir.y = 0
				dir = dir.normalized()
				position += dir * speed * delta
				is_moving = true
				_face(m.position)
			else:
				_face(m.position)
	hero.animate(delta, is_moving, G.shield_t > 0.0)
	position.x = clampf(position.x, -half, half)
	position.z = clampf(position.z, -half, half)
	if bool(G.settings.auto_attack) or bool(G.settings.auto_hunt):
		try_attack()
		if bool(G.settings.auto_hunt):
			for i in 6:
				var acts := Data.actives()
				if i < acts.size() and i != 1 and G.lv >= acts[i].unlock:
					cast(i)
	var mhp := float(G.max_hp())
	var mmp := float(G.max_mp())
	if hit_t > 4.0:
		G.hp = minf(mhp, G.hp + mhp * 0.01 * delta * (6.0 if world.map.town else 1.0))
	G.mp = minf(mmp, G.mp + mmp * 0.02 * delta)
	if bool(G.settings.auto_potion) and pot_cd <= 0.0:
		if G.hp < mhp * 0.4 and G.use_potion("hp"):
			pot_cd = 1.5
		elif G.mp < mmp * 0.15 and G.use_potion("mp"):
			pot_cd = 1.5
