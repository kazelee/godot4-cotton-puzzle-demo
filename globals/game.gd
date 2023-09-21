extends Node

const SAVE_PATH := "user://data.sav"

class Flags:
	signal changed

	var _flags := []

	func has(flag: String) -> bool:
		return flag in _flags

	func add(flag: String) -> void:
		if flag in _flags:
			return
		_flags.append(flag)
		emit_signal("changed")

	# 存档的逻辑：将游戏进度保存成json文件
	func to_dict():
		return {
			"flags": _flags
		}

	# 读档的逻辑
	func from_dict(dict: Dictionary):
		_flags = dict.flags
		emit_signal("changed")

	func reset():
		_flags.clear()
		emit_signal("changed")


class Inventory:
	signal changed

	# 与其他函数无关，外界可以访问
	var active_item: Item

	var _items := []
	var _current_item_index := -1

	func get_item_count() -> int:
		return _items.size()

	func get_current_item() -> Item:
		if _current_item_index == -1:
			return null
		return _items[_current_item_index]

	func add_item(item: Item) -> void:
		if item in _items:
			return
		_items.append(item)
		_current_item_index = _items.size() -1
		emit_signal("changed")

	func remove_item(item: Item) -> void:
		var index := _items.find(item)
		if index == -1:
			return
		_items.remove_at(index)
		if _current_item_index >= _items.size():
			# 确保背包没有东西的时候不会越界访问
			_current_item_index = 0 if _items else -1
		emit_signal("changed")

	func select_next() -> void:
		if _current_item_index == -1:
			return
		_current_item_index = (_current_item_index + 1) % _items.size()
		emit_signal("changed")

	func select_prev():
		if _current_item_index == -1:
			return
		# 保证求余的结果为正数
		_current_item_index = (_current_item_index - 1 + _items.size()) % _items.size()
		emit_signal("changed")

	func to_dict():
		var names := []
		for item in _items:
			var path := item.resource_path as String
			names.append(path.get_file().get_basename())
		return {
			items=names,
			current_item_index=_current_item_index,
		}

	func from_dict(dict: Dictionary):
		_current_item_index = dict.current_item_index
		_items.clear()
		for name in dict.items:
			_items.append(load("res://items/%s.tres" % name))
		emit_signal("changed")

	func reset():
		_current_item_index = -1
		_items.clear()
		emit_signal("changed")


var flags := Flags.new()
var inventory := Inventory.new()


func save_game():
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	var data := {
		"inventory": inventory.to_dict(),
		"flags": flags.to_dict(),
#		"current_scene": get_tree().current_scene.filename.get_file().get_basename(),
		"current_scene": get_tree().current_scene.scene_file_path.get_file().get_basename()
	}
	var json := JSON.stringify(data)
	file.store_string(json)


func load_game():
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json = file.get_as_text()
	var data = JSON.parse_string(json) as Dictionary
	inventory.from_dict(data.inventory)
	flags.from_dict(data.flags)
	SceneChanger.change_scene("res://scenes/%s.tscn" % data.current_scene)


func new_game():
	inventory.reset()
	flags.reset()
	SceneChanger.change_scene("res://scenes/H1.tscn")


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func back_to_title():
	save_game()
	SceneChanger.change_scene("res://ui/title_screen.tscn")
