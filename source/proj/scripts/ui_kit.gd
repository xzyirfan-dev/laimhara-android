class_name UiKit
extends RefCounted
## Utilitas UI: tekstur ikon/bingkai, StyleBox 9-patch, tema, label/tombol, penamaan ikon item.

static var _tex: Dictionary = {}
static var _sb: Dictionary = {}
static var _font: Font
static var _font_b: Font

const GOLD := Color(0.95, 0.82, 0.45)
const GOLD_D := Color(0.62, 0.48, 0.22)
const INK := Color(0.04, 0.03, 0.05)
const TXT := Color(0.92, 0.94, 0.98)
const TXT_DIM := Color(0.62, 0.68, 0.8)
const GOOD := Color(0.45, 0.95, 0.55)
const BAD := Color(1.0, 0.42, 0.38)
const CYAN := Color(0.55, 0.88, 1.0)

static func font() -> Font:
	if _font == null:
		_font = load("res://fonts/Poppins-Medium.ttf")
	return _font

static func font_b() -> Font:
	if _font_b == null:
		_font_b = load("res://fonts/Poppins-Bold.ttf")
	return _font_b

static func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path)
	return _tex[path]

static func icon(name: String) -> Texture2D:
	var path := "res://art/icons/%s.png" % name
	if not ResourceLoader.exists(path):
		path = "res://art/icons/g_info.png"
	return tex(path)

static func ui(name: String) -> Texture2D:
	return tex("res://art/ui/%s.png" % name)

static func item_icon_name(it: Dictionary) -> String:
	return "eq_%s_%d" % [it.slot, ItemDb.pal_idx(int(it.tier))]

static func item_icon(it: Dictionary) -> Texture2D:
	return icon(item_icon_name(it))

static func stack_icon_name(id: String) -> String:
	if id.begins_with("g_"):
		var p := ItemDb.gem_parse(id.substr(2))
		return "gem_%s_%d" % [p.type, p.grade]
	return id

static func stack_icon(id: String) -> Texture2D:
	return icon(stack_icon_name(id))

static func gem_icon(gid: String) -> Texture2D:
	var p := ItemDb.gem_parse(gid)
	return icon("gem_%s_%d" % [p.type, p.grade])

## StyleBoxTexture 9-patch dari art/ui
static func box(name: String, margin: int = 16, content: int = 10) -> StyleBoxTexture:
	var key := "%s|%d|%d" % [name, margin, content]
	if _sb.has(key):
		return _sb[key]
	var s := StyleBoxTexture.new()
	s.texture = ui(name)
	s.texture_margin_left = margin
	s.texture_margin_right = margin
	s.texture_margin_top = margin
	s.texture_margin_bottom = margin
	s.content_margin_left = content
	s.content_margin_right = content
	s.content_margin_top = content
	s.content_margin_bottom = content
	_sb[key] = s
	return s

static func flat(c: Color, r: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(r)
	return s

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 22
	t.set_color("font_color", "Label", TXT)
	t.set_font_size("font_size", "Label", 22)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var nm: String = {"normal": "btn_normal", "hover": "btn_hover", "pressed": "btn_pressed", "disabled": "btn_disabled", "focus": "btn_hover"}[st]
		var b := box(nm, 20, 12)
		t.set_stylebox(st, "Button", b)
	t.set_color("font_color", "Button", TXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.52, 0.58))
	t.set_font_size("font_size", "Button", 22)
	t.set_constant("outline_size", "Button", 0)
	t.set_stylebox("panel", "PanelContainer", box("panel", 30, 14))
	var grab := flat(Color(0.8, 0.65, 0.3, 0.75), 4)
	grab.content_margin_left = 6
	grab.content_margin_right = 6
	var track := flat(Color(0, 0, 0, 0.35), 4)
	t.set_stylebox("scroll", "VScrollBar", track)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	t.set_stylebox("scroll", "HScrollBar", track)
	t.set_stylebox("grabber", "HScrollBar", grab)
	t.set_stylebox("grabber_highlight", "HScrollBar", grab)
	t.set_stylebox("grabber_pressed", "HScrollBar", grab)
	return t

# ---------- pembuat kontrol ----------
static func lbl(text: String, size: int = 22, col: Color = TXT, align: int = HORIZONTAL_ALIGNMENT_LEFT, bold: bool = false, outline: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if bold:
		l.add_theme_font_override("font", font_b())
	if outline > 0:
		l.add_theme_color_override("font_outline_color", INK)
		l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func rich(bb: String, size: int = 20) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_override("bold_font", font_b())
	r.add_theme_color_override("default_color", TXT)
	r.text = bb
	return r

static func tr_rect(t: Texture2D, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.custom_minimum_size = size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## tombol bergaya; kind: normal | gold | red | green
static func btn(text: String, kind: String = "normal", min_size: Vector2 = Vector2(0, 64), font_size: int = 22) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.focus_mode = Control.FOCUS_NONE
	if kind != "normal":
		var n := "btn_" + kind
		b.add_theme_stylebox_override("normal", box(n, 20, 12))
		b.add_theme_stylebox_override("hover", box(n, 20, 12))
		b.add_theme_stylebox_override("pressed", box(n + "_p" if kind == "gold" else n, 20, 12))
		b.add_theme_color_override("font_color", Color(0.18, 0.1, 0.02) if kind == "gold" else Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color(0.18, 0.1, 0.02) if kind == "gold" else Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color(0.18, 0.1, 0.02) if kind == "gold" else Color.WHITE)
	return b

static func spacer(h: int = 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func hdiv() -> TextureRect:
	var r := TextureRect.new()
	r.texture = ui("divider")
	r.custom_minimum_size = Vector2(0, 8)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func hex(c: Color) -> String:
	return c.to_html(false)

static func signed(v: int) -> String:
	return ("+%d" % v) if v >= 0 else ("%d" % v)
