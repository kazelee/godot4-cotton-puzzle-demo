@tool
extends Node2D

const SLOT_TEXTURE = preload("res://assets/H2A/CIRCLE.png")
const LINE_TEXTURE = preload("res://assets/H2A/CIRCLELINE.png")

@export var radius := 100.0: set = set_radius
@export var config: H2AConfig: set = set_config

var _stone_map := {}


func _draw():
	for slot in H2AConfig.Slot.size():
		# draw_texture的坐标在左上角，_get_slot_position的坐标在中心
		draw_texture(SLOT_TEXTURE, _get_slot_position(slot) - SLOT_TEXTURE.get_size() / 2)


func set_radius(v: float):
	radius = v
	queue_redraw()


func set_config(v: H2AConfig):
	# 在config = v 前后设置重连的逻辑，保证直接修改 config 也可以直接影响画面
	if config and config.is_connected("changed", Callable(self, "_update_board")):
		config.disconnect("changed", Callable(self, "_update_board"))
	config = v
	if config and not config.is_connected("changed", Callable(self, "_update_board")):
		config.connect("changed", Callable(self, "_update_board"))
	_update_board()


func reset():
	for stone in _stone_map.values():
		_move_stone(stone, config.placements[stone.target_slot])


func _update_board():
	# 逻辑参见：Interactable set_texture()
	for node in get_children():
		if node.owner == null:
			node.queue_free()

	if not config:
		return

	for src in H2AConfig.Slot.size():
		# 只当从前往后的时候绘制连线（避免重复绘制）
		for dst in range(src + 1, H2AConfig.Slot.size()):
			if not dst in config.connections[src]:
				continue
			var line := Line2D.new()
			add_child(line)
			line.add_point(_get_slot_position(src))
			line.add_point(_get_slot_position(dst))
			line.width = LINE_TEXTURE.get_size().y
			line.texture = LINE_TEXTURE
			# 模式：平铺，即长度不够时重复纹理
#			line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			line.texture_mode = Line2D.LINE_TEXTURE_TILE
			# 类似 modulate 属性，Godot 4 默认已经是白色了
			line.default_color = Color.WHITE
			# 连线显示在圆圈的下方
			line.show_behind_parent = true

	for slot in range(1, H2AConfig.Slot.size()):
		var stone := H2AStone.new()
		add_child(stone)
		# 目标状态是默认的1-6
		stone.target_slot = slot
		# 当前状态在placements中设置
		stone.current_slot = config.placements[slot]
		stone.position = _get_slot_position(stone.current_slot)
		# 将棋子位置另外存入字典中
		_stone_map[slot] = stone
		stone.connect("interact", Callable(self, "_request_move").bind(stone))


# 核心思路：交互 -> 找到空位 -> 判断是否相接 -> 如果相接则移动
func _request_move(stone: H2AStone):
#	var available := H2AConfig.Slot.vulues()
	# available存储的是enum对应的值0-6
	var available := []
	for k in H2AConfig.Slot.keys():
		available.append(H2AConfig.Slot[k])
	# 删除available中所有的棋子当前所在序号（剩下的一个就是空位所在的序号）
	for s in _stone_map.values():
		available.erase(s.current_slot)
	# 断言保证available的所有棋子序号删除（默认有NULL，所以剩下1个空位）
	assert(available.size() == 1)
	var available_slot := available.front() as int
	if available_slot in config.connections[stone.current_slot]:
		_move_stone(stone, available_slot)


func _move_stone(stone: H2AStone, slot: int):
	stone.current_slot = slot
	# 为移动效果添加动画
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(stone, "position", _get_slot_position(slot), 0.2)
	# 等待时刻后判断是否完成
	tween.tween_interval(1.0)
	tween.tween_callback(Callable(self, "_check"))


func _check():
	for stone in _stone_map.values():
		if stone.current_slot != stone.target_slot:
			return
	Game.flags.add("h2a_unlocked")
	SceneChanger.change_scene("res://scenes/H2.tscn")


func _get_slot_position(slot: int) -> Vector2:
	# 从向下方向开始，绕中心点旋转（顺时针），平均分配环上的图案
	return Vector2.DOWN.rotated(TAU / H2AConfig.Slot.size() * slot) * radius
