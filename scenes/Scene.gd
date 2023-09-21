extends Sprite2D
class_name Scene

@export_file("*.mp3") var music_override := ""


func _ready() -> void:
	var tween := create_tween()
	# 场景进入效果，在每一个场景开始时出现
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).from(Vector2.ONE * 1.05)

