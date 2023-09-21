extends "res://scenes/Scene.gd"

@onready var board: Node2D = $Board
@onready var gear: Sprite2D = $Reset/Gear


func _on_reset_interact() -> void:
	# 齿轮转动的效果
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# as relative 相对旋转角度，因为初始可能是 0 或 360
	tween.tween_property(gear, "rotation", 360.0, 0.2).as_relative()
	tween.tween_callback(Callable(board, "reset"))
