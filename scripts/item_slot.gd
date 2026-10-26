class_name ItemSlot
extends Control
## Satu kotak item (equip / stack / permata / slot kosong). Mengirim "tapped" bila diketuk (bukan di-drag).

signal tapped(slot: ItemSlot)

var item: Dictionary = {}       # item equip
var stack_id := ""              # consumable / permata (stack)
var count := 0
var ghost := ""                 # nama slot kosong (silhouette)
var gem_id := ""                # permata terpasang (socket)
var selected := false
var equipped_mark := false
var tag := ""                   # label kecil kiri bawah
var dim := false
var cell := 84.0
var _press_pos := Vector2.ZERO
var _down := false

func _init(c: float = 84.0) -> void:
	cell = c
	custom_minimum_size = Vector2(c, c)
	size = Vector2(c, c)
	mouse_filter = Control.MOUSE_FILTER_PASS

func set_item(it: Dictionary) -> ItemSlot:
	item = it
	queue_redraw()
	return self

func set_stack(id: String, n: int) -> ItemSlot:
	stack_id = id
	count = n
	queue_redraw()
	return self

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press_pos = e.position
			_down = true
		elif _down:
			_down = false
			if e.position.distance_to(_press_pos) < 14.0:
				tapped.emit(self)
				accept_event()

func _draw() -> void:
	var s := size
	var rar := -1
	if not item.is_empty():
		rar = int(item.get("rar", 0))
	elif stack_id != "" and stack_id.begins_with("g_"):
		rar = clampi(int(ItemDb.gem_parse(stack_id.substr(2)).grade) - 1, 0, 4)
	elif gem_id != "":
		rar = clampi(int(ItemDb.gem_parse(gem_id).grade) - 1, 0, 4)
	var frame := UiKit.ui("slot" if rar < 0 else "slot_r%d" % rar)
	draw_texture_rect(frame, Rect2(Vector2.ZERO, s), false, Color(1, 1, 1, 0.55 if dim else 1.0))
	var pad := s.x * 0.1
	var ir := Rect2(Vector2(pad, pad), s - Vector2(pad, pad) * 2.0)
	var tint := Color(1, 1, 1, 0.45 if dim else 1.0)
	if not item.is_empty():
		draw_texture_rect(UiKit.item_icon(item), ir, false, tint)
	elif stack_id != "":
		draw_texture_rect(UiKit.stack_icon(stack_id), ir, false, tint)
	elif gem_id != "":
		draw_texture_rect(UiKit.gem_icon(gem_id), ir, false, tint)
	elif ghost != "":
		draw_texture_rect(UiKit.icon("slot_" + ghost), ir, false, Color(1, 1, 1, 0.55))
	var f := UiKit.font_b()
	var fs := int(s.x * 0.22)
	if not item.is_empty():
		if int(item.plus) > 0:
			_txt("+%d" % int(item.plus), Vector2(s.x * 0.08, s.y * 0.3), fs, Color(1, 0.92, 0.45), f)
		if equipped_mark:
			draw_rect(Rect2(s.x * 0.06, s.y * 0.7, s.x * 0.3, s.y * 0.22), Color(0.1, 0.5, 0.25, 0.95), true)
			_txt("E", Vector2(s.x * 0.11, s.y * 0.88), int(s.x * 0.2), Color.WHITE, f)
		if int(item.get("setn", 0)) > 0:
			draw_circle(Vector2(s.x * 0.84, s.y * 0.17), s.x * 0.08, Color(1, 0.8, 0.3))
		# titik socket terisi
		var soc: Array = item.get("soc", [])
		for i in soc.size():
			var c := Color(0.25, 0.28, 0.35)
			if String(soc[i]) != "":
				c = ItemDb.GEMS[ItemDb.gem_parse(String(soc[i])).type].c
			var p := Vector2(s.x * 0.86, s.y * (0.34 + 0.15 * float(i)))
			draw_circle(p, s.x * 0.055, Color(0, 0, 0, 0.8))
			draw_circle(p, s.x * 0.04, c)
	if count > 1 or (stack_id != "" and count >= 1):
		_txt(Scaling.fmt(count) if count < 100000 else "99K+", Vector2(0, s.y - 6), fs, Color.WHITE, f, HORIZONTAL_ALIGNMENT_RIGHT, s.x - 6)
	if tag != "":
		_txt(tag, Vector2(s.x * 0.08, s.y - 6), int(s.x * 0.18), Color(0.7, 0.9, 1), f)
	if selected:
		draw_rect(Rect2(Vector2(1, 1), s - Vector2(2, 2)), Color(1, 0.95, 0.5), false, 3.0)

func _txt(t: String, pos: Vector2, fs: int, col: Color, f: Font, al: int = HORIZONTAL_ALIGNMENT_LEFT, w: float = -1.0) -> void:
	draw_string_outline(f, pos, t, al, w, fs, 6, Color(0, 0, 0, 0.95))
	draw_string(f, pos, t, al, w, fs, col)
