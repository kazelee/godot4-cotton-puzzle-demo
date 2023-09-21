extends TextureRect

@onready var load: Button = $VBoxContainer/Load

func _ready() -> void:
	load.disabled = not Game.has_save_file()


func _on_new_pressed() -> void:
	Game.new_game()


func _on_load_pressed() -> void:
	Game.load_game()


func _on_quit_pressed() -> void:
	get_tree().quit()
