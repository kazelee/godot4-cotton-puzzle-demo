extends VBoxContainer

# 独立出来是为了在多个函数中引用
var _hand_outro: Tween
var _label_outro: Tween

var _item_should_clear: bool

@onready var label: Label = $Label
@onready var prev: TextureButton = $ItemBar/Prev
@onready var prop: Sprite2D = $ItemBar/Use/Prop
@onready var hand: Sprite2D = $ItemBar/Use/Hand
@onready var next: TextureButton = $ItemBar/Next
@onready var timer: Timer = $Label/Timer


func _ready() -> void:
#	Game.inventory.add_item(preload("res://items/key.tres"))
#	Game.inventory.add_item(preload("res://items/mail.tres"))
	hand.hide()
	hand.modulate.a = 0.0
	label.hide()
	label.modulate.a = 0.0
	
	_item_should_clear = false
	# 每次改变都更新UI
	Game.inventory.connect("changed", Callable(self, "_update_ui"))
	_update_ui(true)

#var is_last_item_active := false
#func _physics_process(delta: float) -> void:
#	if is_last_item_active != (Game.inventory.active_item != null):
#		print("[%s] %s" % [Engine.get_physics_frames(), Game.inventory.active_item])
#	is_last_item_active = Game.inventory.active_item != null

func _input(event: InputEvent) -> void:
	if _item_should_clear:
		Game.inventory.active_item = null
		_item_should_clear = false
	if event.is_action_pressed("interact") and Game.inventory.active_item:
#		print("[%s] input!" % Engine.get_physics_frames())
		_item_should_clear = true
#		Game.inventory.set_deferred("active_item", null)
		_hand_outro = create_tween()
		_hand_outro.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_parallel()
		# 设置放大和透明效果
		_hand_outro.tween_property(hand, "scale", Vector2.ONE * 3, 0.15)
		_hand_outro.tween_property(hand, "modulate:a", 0.0, 0.15)
		_hand_outro.chain().tween_callback(Callable(hand, "hide"))


func _update_ui(is_init := false) -> void:
	var count := Game.inventory.get_item_count()
	# 箭头禁用
	prev.disabled = count < 2
	next.disabled = count < 2
	# 整体的可见性
	visible = count > 0
	
	var item := Game.inventory.get_current_item()
	if not item:
		return
	
	label.text = item.description
	prop.texture = item.prop_texture
	
	# 场景初始化时不要调用动画
	if is_init:
		return
	
	# 动画回弹效果
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(prop, "scale", Vector2.ONE, 0.15).from(Vector2.ZERO)
	
	_show_label()


func _show_label():
	if _label_outro and _label_outro.is_valid():
		_label_outro.kill()
		_label_outro = null
	label.show()
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_callback(Callable(timer, "start"))


func _on_prev_pressed() -> void:
	Game.inventory.select_prev()


func _on_use_pressed() -> void:
	Game.inventory.active_item = Game.inventory.get_current_item()
	# 点击物品时也会显示label（不仅仅是切换物品栏）
	_show_label()
	
	# 动画还在进行之中
	if _hand_outro and _hand_outro.is_valid():
		_hand_outro.kill()
		_hand_outro = null
	hand.show()
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel()
	tween.tween_property(hand, "scale", Vector2.ONE, 0.15).from(Vector2.ZERO)
	tween.tween_property(hand, "modulate:a", 1.0, 0.15)


func _on_next_pressed() -> void:
	Game.inventory.select_next()


func _on_timer_timeout() -> void:
	_label_outro = create_tween()
	_label_outro.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_label_outro.tween_property(label, "modulate:a", 0.0, 0.2)
	_label_outro.tween_callback(Callable(label, "hide"))
