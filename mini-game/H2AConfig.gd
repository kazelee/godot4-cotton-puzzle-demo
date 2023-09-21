@tool
extends Resource
class_name H2AConfig

enum Slot { NULL, TIME, SUN, FISH, HILL, CROSS, CHOICE }

#@export var placements := PackedInt32Array()
#@export var connections := {}
var placements := PackedInt32Array()
var connections := {}

func _init():
	# 实际只需要 6 个位置，这样是为了后面访问方便
	placements.resize(Slot.size())
	placements.fill(Slot.NULL)

	for slot in Slot.values():
		connections[slot] = []


# 为检查器设置选单样式
func _get_property_list():
#	var properties = []
	var properties := [
		{
			"name": "placements",
			"type": TYPE_PACKED_INT32_ARRAY,
			"usage": PROPERTY_USAGE_STORAGE,
#			"usage": PROPERTY_USAGE_NO_EDITOR,
		},
		{
			"name": "connections",
			"type": TYPE_DICTIONARY,
			"usage": PROPERTY_USAGE_STORAGE,
#			"usage": PROPERTY_USAGE_NO_EDITOR,
		},
	]

	# 可以把 enum 视作一个字典，枚举的名称是key，对应的int值是value
	# 这里keys()返回的是键的列表，最后options是一个String列表
	var options := ",".join(PackedStringArray(Slot.keys()))
	for slot in range(1, Slot.size()):
		properties.append({
			"name": "placements/" + Slot.keys()[slot],
			"type": TYPE_INT,
			# 这里不保存到文件，而是在编辑器中
			"usage": PROPERTY_USAGE_EDITOR,
#			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": options,
		})

	# - N T S F H C C
	# N - x x x x x x
	# T - - x x x x x
	# S - - - x x x x
	# F - - - - x x x
	# H - - - - - x x
	# C - - - - - - x
	# C - - - - - - -

	for slot in Slot.size() - 1:
		var available := PackedStringArray()
		for dst in Slot.size():
			# n^2 -> n^2/2：0:6 -> 6:1 (7:0)
			# 限定了检查器的选单选项
			if dst <= slot:
				available.append("")
			else:
				# 通过int下标索引keys，得到的还是名称String
				available.append(Slot.keys()[dst])

		properties.append({
			"name": "connections/" + Slot.keys()[slot],
			"type": TYPE_INT,
			# 这里不保存到文件，而是在编辑器中
			"usage": PROPERTY_USAGE_EDITOR,
#			"usage": PROPERTY_USAGE_DEFAULT,
			# ENUM 单选框；FLAGS 复选框（对应二进制值，空字符串占位0）
			"hint": PROPERTY_HINT_FLAGS,
			"hint_string": ",".join(available),
		})

#	return []
	return properties


# 脚本中的变量，从检查器的选单中获得数据
func _get(property: StringName):
	if property.begins_with("placements/"):
		property = property.trim_prefix("placements/")
		# 通过字符串key来返回int型value，再用于索引
		var index := Slot[property] as int
		return placements[index]

	#  - N T S F H C C   [get value]    [set value]
	#  N - x x x x x x  - 1 1 1 1 1 1  0 1 1 1 1 1 1
	#  T - - x x x x x  - - 1 1 0 0 0  1 0 1 1 0 0 0
	#  S - - - x x x x  - - - 0 0 0 0  1 1 0 0 0 0 0
	#  F - - - - x x x  - - - - 1 0 0  1 1 0 0 1 0 0
	#  H - - - - - x x  - - - - - 0 1  1 0 0 1 0 0 1
	#  C - - - - - - x  - - - - - - 1  1 0 0 0 0 0 1
	#  C - - - - - - -  - - - - - - -  1 0 0 0 1 1 0

	if property.begins_with("connections/"):
		property = property.trim_prefix("connections/")
		var index := Slot[property] as int
		var value := 0
		# 只需考虑自己以后的选项，此语句对应上面的第二层for循环
		for dst in range(index + 1, Slot.size()):
			# 选单index对应项中有这个选项
			if dst in connections[index]:
				# 将该选项对应的位置1
				value |= (1 << dst)
		return value

	return null


# 资源根据脚本中的变量数据，写进文件中
func _set(property: StringName, value: Variant):
	if property.begins_with("placements/"):
		property = property.trim_prefix("placements/")
		var index := Slot[property] as int
		placements[index] = value
		emit_changed()
		return true

	if property.begins_with("connections/"):
		property = property.trim_prefix("connections/")
		var index := Slot[property] as int
		for dst in range(index + 1, Slot.size()):
			# 通过对应位与，确定两点是否连接
			_set_connected(index, dst, value & (1 << dst))
		emit_changed()
		return true

	return false


# 相当于数据结构中把单向图变成双向图（将三角矩阵对称复制，其中对角线默认为0）
func _set_connected(src: int, dst: int, connected: bool):
	# xxx_arr：xxx相连的点的数组
	var src_arr := connections[src] as Array
	var dst_arr := connections[dst] as Array
	# xxx_idx：在与xxx相连的数组中找到的「另一个」点的下标
	# 所以xxx_idx指向的不是xxx，只是在xxx_arr中查询而已
	# 原教程的命名有歧义，其实用 A_idx_of_B_arr 的格式更好理解，只是过于长了
	# 如：src_idx -> dst_idx_of_src_arr
	var src_idx := src_arr.find(dst)
	var dst_idx := dst_arr.find(src)
	if connected:
		# 如果连接，且没有找到彼此，则重新添加
		if src_idx == -1:
			src_arr.append(dst)
		if dst_idx == -1:
			dst_arr.append(src)
	else:
		# 如果未连接，且两点有连接，则断开连接
		if src_idx != -1:
			src_arr.remove_at(src_idx)
		if dst_idx != -1:
			dst_arr.remove_at(dst_idx)
