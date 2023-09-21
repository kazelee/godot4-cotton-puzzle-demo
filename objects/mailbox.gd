extends FlagSwitch


func _on_interactable_interact() -> void:
	var item := Game.inventory.active_item
	if not item or item != preload("res://items/key.tres"):
		return
	Game.flags.add(flag)
	Game.inventory.remove_item(item)
