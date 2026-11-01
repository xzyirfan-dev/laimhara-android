class_name AssetCatalog
extends RefCounted

const ITEMS_PATH := "res://assets/catalog/items.json"
static var _items: Array = []
static var _loaded := false

static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open(ITEMS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_items = parsed

static func pick_item(slot: String, tier: int) -> Dictionary:
	_ensure()
	var db_slot: String = String({"helm": "helmet", "armor": "body", "gloves": "gloves", "boots": "shoes", "cloak": "cloak", "belt": "belt", "neck": "neck", "ring": "ring", "weapon": "weapon"}.get(slot, slot))
	var best: Dictionary = {}
	var best_score := INF
	for raw in _items:
		var row: Dictionary = raw
		if String(row.get("slot", "")) != db_slot:
			continue
		var am := String(row.get("am", ""))
		var aw := String(row.get("aw", ""))
		if not FileAccess.file_exists(am) and not FileAccess.file_exists(aw):
			continue
		var level := int(row.get("level", 0))
		var score := absf(float(level - tier))
		if score < best_score:
			best_score = score
			best = row
	return best

static func find_item(asset_id: int) -> Dictionary:
	_ensure()
	for raw in _items:
		var row: Dictionary = raw
		if int(row.get("id", 0)) == asset_id:
			return row
	return {}

static func model_path(item: Dictionary, female: bool = false) -> String:
	if item.is_empty():
		return ""
	var key := "aw" if female else "am"
	var p := String(item.get(key, ""))
	if p.is_empty() or not FileAccess.file_exists(p):
		var other := String(item.get("am" if female else "aw", ""))
		if FileAccess.file_exists(other):
			return other
		return ""
	return p

static func pet_path(index: int = 3) -> String:
	var p := "res://assets/models/Warehouse_Pet_%03d.glb" % index
	return p if FileAccess.file_exists(p) else ""

static func monster_path(source_id: int) -> String:
	var p := "res://assets/models/monsters/monster_%d.glb" % source_id
	return p if FileAccess.file_exists(p) else ""
