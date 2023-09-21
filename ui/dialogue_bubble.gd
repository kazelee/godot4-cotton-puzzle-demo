extends Control

var _dialogs := [] # 存储对话内容
var _current_line := -1 # 存储当前行数，默认-1

@onready var content: Label = $Content

func _ready() -> void:
	hide()


func show_dialog(dialogs: Array) -> void:
	# 点击触发对话的人物也可以推进对话（不必非要点击气泡）
	if _current_line == -1 or _dialogs != dialogs:
		_dialogs = dialogs
		_show_line(0)
		show()
	else:
		_advance()


func _show_line(line: int) -> void:
	_current_line = line
	content.text = _dialogs[line]
	# 将场景进入的效果用在对话气泡上面
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).from(Vector2.ONE * 1.05)


# 推进对话
func _advance() -> void:
	if _current_line + 1 < _dialogs.size():
		_show_line(_current_line + 1)
	else:
		_current_line = -1
		hide()


func _on_content_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_advance()

