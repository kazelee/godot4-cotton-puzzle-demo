@tool
class_name Teleporter
extends Interactable

@export_file("*.tscn") var target_path: String

func _interact() -> void:
	super()
	SceneChanger.change_scene(target_path)
