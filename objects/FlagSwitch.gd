class_name FlagSwitch
extends Node2D

@export var flag: String

var default_node: Node2D # flag 不存在时显示
var switch_node: Node2D # flag 存在时显示


func _ready() -> void:
	var count := get_child_count()
	if count > 0:
		default_node = get_child(0)
	if count > 1:
		switch_node = get_child(1)

	Game.flags.connect("changed", Callable(self, "_update_nodes"))
	_update_nodes()


func _update_nodes():
	var exists := Game.flags.has(flag)
	if default_node:
		default_node.visible = not exists
	if switch_node:
		switch_node.visible = exists


