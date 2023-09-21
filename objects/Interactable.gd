@tool
class_name Interactable
extends Area2D

signal interact

@export var allow_item := false
@export var texture: Texture: set = set_texture

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if not event.is_action_pressed("interact"):
		return
#	print("[%s] %s" % [Engine.get_physics_frames(), Game.inventory.active_item])
	if not allow_item and Game.inventory.active_item:
		return
	_interact()

func _interact() -> void:
	emit_signal("interact")
#	print("[%s] intectact!" % Engine.get_physics_frames())


func set_texture(v: Texture) -> void:
	texture = v

	for node in get_children():
		if node.owner == null:
			node.queue_free()

	if texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = texture
	add_child(sprite)

	var rect := RectangleShape2D.new()
	rect.extents = v.get_size() / 2

	var collider := CollisionShape2D.new()
	collider.shape = rect
	add_child(collider)

