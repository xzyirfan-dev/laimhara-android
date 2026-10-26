class_name Scaling
extends RefCounted
## Semua rumus balance (PRD Bagian 3) ada di sini.

const MAX_LEVEL := 400
const RATES_W := [95, 85, 75, 50, 55, 45, 35, 50, 25, 15, 12, 10, 8, 6, 5]
const RATES_A := [95, 85, 75, 50, 65, 55, 45, 50, 35, 30, 20, 15, 12, 9, 6]
const PITY := [0, 10, 15, 20, 25, 50]

static func exp_kill(l: int) -> float:
	return 12000.0 * pow(float(l), 1.7)

static func kills_per_level(l: int) -> float:
	return 10.0 + float(l) / 20.0

static func exp_need(l: int) -> int:
	return int(kills_per_level(l) * exp_kill(l))

static func tier_for(l: int) -> int:
	if l < 10:
		return maxi(1, l)
	return mini(400, floori(l / 10.0) * 10)

static func tier_down(t: int) -> int:
	if t > 10:
		return t - 10
	return maxi(1, t - 1)

static func tier_up(t: int) -> int:
	if t < 10:
		return t + 1
	return mini(400, t + 10)

static func weapon_atk(t: int) -> float:
	return 4.0 * pow(float(t), 1.1)

static func armor_def(t: int) -> float:
	return 3.0 * pow(float(t), 1.05)

static func expected_atk(l: int) -> float:
	return 4.0 * pow(float(l), 1.1) + 2.5 * float(l)

static func player_base_hp(l: int) -> float:
	return 150.0 + 50.0 * float(l)

static func mons_level(pl: int, mn: int, mx: int) -> int:
	return clampi(pl, mn, mx)

static func mons_hp(l: int, k: int) -> float:
	return 5.5 * expected_atk(l) * [1.0, 3.0, 15.0][k]

static func mons_atk(l: int, k: int) -> float:
	return 0.09 * player_base_hp(l) * [1.0, 1.5, 2.0][k]

static func laima_kill(l: int) -> float:
	return 50.0 * pow(float(l), 1.4)

static func price(t: int) -> int:
	return int(120.0 * pow(float(t), 1.5))

static func candidate_tiers(l: int) -> Array:
	var b := tier_for(l)
	var out: Array = []
	if b < 10:
		out = [maxi(1, b - 2), b, 10]
	else:
		out = [maxi(10, b - 10), b, mini(400, b + 10)]
	var u: Array = []
	for t in out:
		if not u.has(t):
			u.append(t)
	return u

static func fmt(n: int) -> String:
	var a := absi(n)
	if a >= 1000000000:
		return "%.2fB" % (float(n) / 1e9)
	if a >= 1000000:
		return "%.2fM" % (float(n) / 1e6)
	if a >= 10000:
		return "%.1fK" % (float(n) / 1e3)
	return str(n)
