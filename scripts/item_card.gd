class_name ItemCard
extends RefCounted
## Kartu info item (isi popup) untuk equip, permata, dan consumable.

const DESC := {
	"hp": "Memulihkan 40% HP.",
	"mp": "Memulihkan 40% MP.",
	"tp": "Town Portal: kembali ke kota Velamina dari map berburu.",
	"warp": "Warp Scroll: teleport ke map yang pernah dikunjungi.",
	"capsule": "EXP x2 selama 30 menit.",
	"safety": "Safety Stone: item tidak turun level saat tempa gagal (peluang -10%).",
	"w50": "Warranty 50%: menambah +50% peluang sukses tempa.",
	"w100": "Warranty 100%: tempa PASTI berhasil.",
	"gem": "Batu mentah. Bahan Confusion (acak stat) atau dijual ke Pasar.",
	"aeth4": "Jewel G4: peluang Option 10%. Hanya untuk item tier 350+.",
	"aeth3": "Jewel G3: peluang Option 20%. Hanya untuk item tier 350+.",
	"aeth2": "Jewel G2: peluang Option 40%. Hanya untuk item tier 350+.",
	"aeth1": "Jewel G1: peluang Option 80%. Hanya untuk item tier 350+.",
}

static func _c(c: Color) -> String:
	return c.to_html(false)

static func item_title(it: Dictionary) -> String:
	var rc: Color = ItemDb.rarity_color(it)
	var s := "[b][color=#%s]%s[/color][/b]" % [_c(rc), ItemDb.base_name(it.slot, int(it.tier))]
	if int(it.plus) > 0:
		s += " [color=#ffe27a]+%d[/color]" % int(it.plus)
	return s

static func item_body(it: Dictionary, compare: Dictionary = {}) -> String:
	var rc: Color = ItemDb.rarity_color(it)
	var out: Array = []
	var lvc := UiKit.GOOD if G.lv >= int(it.tier) else UiKit.BAD
	out.append("[color=#%s]%s[/color] · Tier %d · [color=#%s]Syarat Lv %d[/color]" % [_c(rc), ItemDb.RARITY_NAME[int(it.get("rar", 0))], int(it.tier), _c(lvc), int(it.tier)])
	var pw := int(G.item_power(it))
	var stat := "ATK" if it.slot == "weapon" else "DEF"
	var line := "[font_size=30][b]%s %s[/b][/font_size]" % [stat, Scaling.fmt(pw)]
	if not compare.is_empty() and int(compare.uid) != int(it.uid):
		var d := pw - int(G.item_power(compare))
		if d > 0:
			line += "   [color=#%s]▲ +%s[/color]" % [_c(UiKit.GOOD), Scaling.fmt(d)]
		elif d < 0:
			line += "   [color=#%s]▼ -%s[/color]" % [_c(UiKit.BAD), Scaling.fmt(-d)]
		else:
			line += "   [color=#888888]=[/color]"
	elif compare.is_empty() and not G.is_equipped(it):
		line += "   [color=#%s]▲ slot kosong[/color]" % _c(UiKit.GOOD)
	out.append(line)
	var inh := ItemDb.inherent(it)
	for k in inh.keys():
		out.append("[color=#%s]%s +%.1f%%[/color]" % [_c(UiKit.CYAN), ItemDb.BONUS_NAME[k], float(inh[k])])
	for o in it.get("opts", []):
		out.append("[color=#ffd36a]✦ %s[/color]" % G.opt_text(o))
	var soc: Array = it.get("soc", [])
	if soc.size() > 0:
		out.append("[color=#8fa0c0]Socket (%d)[/color]" % soc.size())
		for gid in soc:
			var g := String(gid)
			if g == "":
				out.append("[color=#667088]◇ kosong[/color]")
			else:
				var p := ItemDb.gem_parse(g)
				out.append("[color=#%s]◆ %s: %s[/color]" % [_c(ItemDb.GEMS[p.type].c), ItemDb.gem_name(g), ItemDb.gem_text(g)])
	if int(it.get("setn", 0)) > 0:
		var n := G.set_count()
		out.append("[color=#ffd36a][SET] Bonus set aktif: %d/9 → ATK/DEF x%.2f[/color]" % [n, G.set_mult()])
	out.append("[color=#8fa0c0]Harga jual: %s Laima[/color]" % Scaling.fmt(G.sell_value(it)))
	return "\n".join(out)

## kartu lengkap: header (ikon + nama) + isi
static func build_item(it: Dictionary, compare: Dictionary = {}, icon_size: float = 92.0) -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var sl := ItemSlot.new(icon_size)
	sl.item = it
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(sl)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	hv.add_child(UiKit.rich(item_title(it), 28))
	var eqs: String = "Terpasang" if G.is_equipped(it) else ItemDb.SLOT_LABEL[it.slot]
	hv.add_child(UiKit.lbl(eqs, 18, UiKit.TXT_DIM))
	head.add_child(hv)
	vb.add_child(head)
	vb.add_child(UiKit.hdiv())
	var body := UiKit.rich(item_body(it, compare), 20)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(body)
	return vb

static func stack_body(id: String, n: int) -> String:
	if id.begins_with("g_"):
		var g := id.substr(2)
		var p := ItemDb.gem_parse(g)
		var col: Color = ItemDb.GEMS[p.type].c
		return "[color=#%s][font_size=26][b]%s[/b][/font_size][/color]\n[color=#%s]%s[/color]\nDipasang pada socket perlengkapan.\nGabungkan 3 permata sama menjadi tingkat berikutnya." % [_c(col), ItemDb.gem_name(g), _c(UiKit.GOOD), ItemDb.gem_text(g)]
	return "[font_size=26][b]%s[/b][/font_size]\n%s" % [Data.STACK_NAMES.get(id, id), DESC.get(id, "")]

static func build_stack(id: String, n: int) -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var sl := ItemSlot.new(92.0)
	sl.stack_id = id
	sl.count = n
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(sl)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	var nm := ItemDb.stack_name(id)
	hv.add_child(UiKit.lbl(nm, 26, UiKit.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
	hv.add_child(UiKit.lbl("Jumlah: %d" % n, 18, UiKit.TXT_DIM))
	head.add_child(hv)
	vb.add_child(head)
	vb.add_child(UiKit.hdiv())
	var desc: String
	if id.begins_with("g_"):
		var g := id.substr(2)
		desc = "[color=#%s]%s[/color]\nDipasang pada socket perlengkapan.\nGabungkan 3 permata sama menjadi tingkat berikutnya." % [_c(UiKit.GOOD), ItemDb.gem_text(g)]
	else:
		desc = String(DESC.get(id, ""))
	var body := UiKit.rich(desc, 20)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(body)
	return vb
