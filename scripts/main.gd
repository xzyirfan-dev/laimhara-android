extends Node
## Alur: Layar Judul -> (Game Baru: buat karakter + intro | Lanjutkan) -> Dunia + HUD.
## "Kembali ke Menu Utama" menyimpan otomatis lalu membuka layar judul lagi.

var title: Title
var world: GameWorld
var hud: Hud

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	G.to_title.connect(_to_title)
	_show_title()

func _show_title() -> void:
	G.in_game = false
	get_tree().paused = false
	title = Title.new()
	title.start_game.connect(_start)
	add_child(title)

func _start(mode: String) -> void:
	if title != null:
		title.queue_free()
		title = null
	if mode == "load":
		if not G.load_game():
			G.new_game()
	G.in_game = true
	world = GameWorld.new()
	add_child(world)
	hud = Hud.new()
	hud.world = world
	add_child(hud)
	if mode == "new":
		G.save_game()

func _to_title() -> void:
	G.save_game()
	G.in_game = false
	if hud != null:
		hud.queue_free()
		hud = null
	if world != null:
		world.queue_free()
		world = null
	_show_title()
