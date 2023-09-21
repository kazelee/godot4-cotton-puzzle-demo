@tool
extends Interactable
class_name H2AStone

var target_slot: int: set = set_target_slot
var current_slot: int: set = set_current_slot

func set_target_slot(v: int):
	target_slot = v
	_update_texture()


func set_current_slot(v: int):
	current_slot = v
	_update_texture()


func _update_texture():
	var index := target_slot
	# 目标状态的texture是1-6，默认状态的texture是7-12
	# 当棋子未移动到目标状态时，加载的图片序号是 目标状态 + 7-1
	if target_slot != current_slot:
		index += H2AConfig.Slot.size() - 1
	# %02d 表示：两位 十进制数 不足补0
	set_texture(load("res://assets/H2A/SS_%02d.png" % index))

