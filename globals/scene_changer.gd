extends CanvasLayer

signal game_entered
signal game_exited

@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	_on_scene_changed(null, get_tree().current_scene)


func change_scene(path: String) -> void:
	# 场景“黑入”“黑出”的转场效果
	var tween := create_tween()
	tween.tween_callback(Callable(color_rect, "show"))
	tween.tween_property(color_rect, "color:a", 1.0, 0.2)
	# 自带的 change_scene 函数是 deferred 的，即第二帧才能看到效果
#	tween.tween_callback(Callable(get_tree(), "change_scene_to_file").bind(path))
	tween.tween_callback(Callable(self, "_change_scene").bind(path))
	tween.tween_property(color_rect, "color:a", 0.0, 0.3)
	tween.tween_callback(Callable(color_rect, "hide"))


func _change_scene(path: String):
	var old_scene := get_tree().current_scene
	var new_scene := load(path).instantiate() as Node

	var root := get_tree().root
	root.remove_child(old_scene)
	root.add_child(new_scene)
	get_tree().current_scene = new_scene

	_on_scene_changed(old_scene, new_scene)

	# 手动释放，因为父节点替换了不会自动删除
	old_scene.queue_free()


func _on_scene_changed(old_scene: Node, new_scene: Node):
	var was_in_game := old_scene is Scene
	var is_in_game := new_scene is Scene
	if was_in_game != is_in_game:
		if is_in_game:
			emit_signal("game_entered")
		else:
			emit_signal("game_exited")

	# 默认场景音乐
	var music := "res://assets/Music/PaperWings.mp3"
	# 默认override为空，H2A的override有特殊值
	if is_in_game and new_scene.music_override:
		music = new_scene.music_override
	SoundManager.play_music(music)
