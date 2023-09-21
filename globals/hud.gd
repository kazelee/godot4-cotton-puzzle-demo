extends CanvasLayer

func _ready() -> void:
	SceneChanger.connect("game_entered", Callable(self, "show"))
	SceneChanger.connect("game_exited", Callable(self, "hide"))

	# 当前场景为Scene时才显示menu和道具栏
	visible = get_tree().current_scene is Scene


func _on_menu_pressed() -> void:
	Game.back_to_title()
