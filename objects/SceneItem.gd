@tool
class_name SceneItem
extends Interactable

@export var item: Item: set = set_item


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if Game.flags.has(_get_flag()):
		queue_free()


func set_item(v: Item):
	item = v
	set_texture(item.scene_texture if item else null)
	# 强制继承节点也刷新
	notify_property_list_changed()


func _interact():
	super()
	
	Game.flags.add(_get_flag())
	Game.inventory.add_item(item)
	
	# 新建一个图层来“掉包”（让玩家以为还是原来那个）
	var sprite := Sprite2D.new()
	sprite.texture = item.scene_texture
	get_parent().add_child(sprite)
#	get_tree().current_scene.add_child(sprite)
	sprite.global_position = global_position
	
	# 在新的spite上创建tween，此时不可点击交互
	var tween := sprite.create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(Callable(sprite, "queue_free"))
	
	queue_free()

# 获取事件信息
func _get_flag():
	return "picked" + item.resource_path.get_file()
