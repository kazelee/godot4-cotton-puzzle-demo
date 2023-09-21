# godot4_cotton_puzzle_demo
基于 timothyqiu 的“《迷失岛2》游戏框架开发”教程，在 Godot 4 中复刻

【强调】只是个人学习项目归档，仅供参考

教程链接：[制作《迷失岛2》游戏框架 | 面试题详解 | Godot游戏开发教程\_哔哩哔哩\_bilibili](https://www.bilibili.com/video/BV1Cg411o7G3/)

这里给出 Godot 4 与教程不同的地方：

### 1. 实现场景转换

Godot 4 的语法/操作更新：

1. 窗口拉伸模式由 `2d` 变动为 `canvas_item`
2. `.interact(xxx)` 改成 `super(xxxx)`
3. `export(String,FILE,"*.tscn")` 换成 `@export_file("*.tscn")`
4. `tween_callback` 的参数更改为 `Callable(color_rect, "show")`
5. `tween.tween_callback(get_tree(), "change_scene", [path])` 更改为`tween.tween_callback(Callable(get_tree(),  "change_scene_to_file").bind(path))`（注意，get_tree() 的方法 change_scene 已经更改成了 change_scene_to_file；call_back 函数需要用 Callable 来调用，bind() 函数来绑定参数）

强调：

1. 一开始的场景 sprite 位置是使用 node2d 的 transform 调整的，不是 offset
2. scene_changer 设置全局加载，并用 SceneChanger 代替 Teleporter 的 `get_tree()`
3. 按住 Ctrl 就可以点击查看函数的详情；按下 Ctrl+Shift+D 复制当前行，按下 Alt+方向键 移动当前行
4. “进入”的缓动效果：P3，01，12'55" 开始
5. “参数未使用”“返回值未使用”的警告关闭（本项目未关闭）

问题补充：

Q：sprite 的offset 里面有 centered 开关，把那个关掉就行了，不用那么麻烦
A：我一开始是用这种方法的。但在制作最后的进场动画的时候，如果原点在左上角，写起来就会更加麻烦
【补充】转场的进入效果是与 Anchor 有关的（包括后面的对话气泡）

Q：在sceneChanger.gd中 用tween控制color 透明度 顺序是：
show、color:a 1.0、切换场景、color:a 0.0、hide
如果吧 第一个color:1.0 delay时间设置为0.5s 或者 1s
当H1 点击Area2D进入H2，直接显示为show（直接显示一个黑屏的页面，并持续0.5s，后才显示H2场景页面）
A：你可以检查一下场景里 ColorRect 的颜色是不是黑色、Alpha 为 0。这个会影响到它的初始状态。如果此处的 Alpha 是 1，那么第一次转场就相当于是先从 Alpha 1 变化到 Alpha 1（也就是持续显示不透明的黑色，不存在过渡）

### 2. 实现人物对话

相关链接：[【Godot教程】如何实现对话系统\_哔哩哔哩\_bilibili](https://www.bilibili.com/video/BV1y64y127n5/)

备注：用户界面 节点就是 Control 节点

不同的操作记录：
1. 1'19" 对 DialogueBubble - Handle 的操作，使用 Anchors 左下 替代
2. 九宫格的设置在 Sub-Region 中的“编辑区域”里
3. ~~Content 的字体设置不再有 DynamicFont，这里直接加载字体并唯一化，然后另存；大小通过下方的 Font Sizes 改动~~另存 *.tres 必须先唯一化，而唯一化会拖慢场景的加载时间，所以生成 *.tres 文件后应该先清除字体，然后再加载生成的 *.tres 文件（然而，直接加载 *.tres 文件仍然会卡顿，所以这里直接使用原本的字体文件）

补充强调：
1. Godot 4 无需将渲染2D的九宫格模式设置为 Fixed
2. 旧版本调整图像宽度位置的操作与新版大相径庭，这里只是用新方法基本模拟出教程的效果
3. 需要用脚本控制鼠标等操作时，应把 Mouse 的 Filter 设置为 Stop，然后用信号处理
4. 对某一个已有脚本场景的特殊化处理：对场景扩展脚本

出现的问题：新增 Granny 后，任何场景进入 H2 都会黑屏更长时间
解决：不应该将字体唯一化，否则 *.tscn 文件会很大，拖慢加载时间

### 3. 道具拾取

工具脚本参考：[【Godot教程】如何使用工具脚本\_哔哩哔哩\_bilibili](https://www.bilibili.com/video/BV1Kq4y1V73X/)

1. `rect.extents = v.get_size()/2`：extents 的定义就是 texture 的 1/2
2. Godot3 的导出变量类型只能是基础类型和内置资源（Godot 4 已经支持）
3. `property_list_changed_notify()` -> `notify_property_list_changed()`
4. 不直接使用 Interactable，或者只在 SceneItem 里面声明函数，也还是为了后面复用

评论区补充：
最后那段捡到东西的效果可以用yield来做，代码如下
```gdscript
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self,"scale",Vector2.ZERO,0.15)
	yield(tween,"finished")
	queue_free()
```
这样效果完全一样，代码还少了好多

【问题】没有办法处理up说的「连续点击」的问题，需要做其他处理，比较麻烦

### 4. 状态的记录

1. 使用 Game.gd 脚本全局判断事情的发生
2. `is_editor_hint()` 判断帮助工具模式下不影响编辑器

【评论区】使用 NativeScript 定制你的道具精灵 MyScript，根据脚本运行状态，editor mode or game mode 表现不同的动作（搁置）

### 5. 实现状态栏

1. 使用 VBoxContainer 节点制作背包 UI：VBox 是上下结构，HBox 是左右结构；左右结构的每一个交互对象用 TextureButton 实现
2. 按钮竖直居中：Control - Layout - Container Sizing - Vertical 居中收缩；Anchor 和生长方向在 Godot4 中无需修改
3. `_input` 在所有的事件函数（如 `_unhandled_input`）发生之前，`set_deferred`在所有行为发生完成之后
4. Godot 4 中没有 SceneTreeTween，这里直接使用 Tween 了
5. 设置全局 HUD 的时候建议关闭全局变量，因为后续也用不到了

【注】设计 Inventory 的 UI 的时候，需要将 BoxContainer 的 Alignment 设为 End

【问题】出现了 Game.inventory.active_item 随机出现 null 的情况：在交互的瞬间，active_item 有可能之前就已经变成 null 了（评论区也有指出）。初步判断可能是 Godot 4 中关于 _input 函数和 set_deferred 函数的问题（可能不能确保在一帧结束后再调用？或者 _input 函数不总是能在其他函数之前运行？具体原因尚不明确）

【暂时的解决方案】在 inventory.gd 中开头新增变量 `var _item_should_clear: bool`，在 _ready 函数中初始化为 false， 在 _input 中将原本的 `Game.inventory.set_deferred("active_item", null)` 更改为 `_item_should_clear = true`，然后在 _input 函数开头写下：
```gdscript
if _item_should_clear:
	Game.inventory.active_item = null
	_item_should_clear = false
```
这样下一次交互的开始，会先将上一帧应该删除的对象删除。这样既不会出现上一帧中对象中途变成 null 的情况，也不会对下一帧的交互产生影响

### 6. 实现信箱

（没什么需要补充的）

### 7. 小游戏数据

1. PoolIntArray 更改为 PackedInt64Array（同理，TYPE_INT_ARRAY -> TYPE_PACKED_INT32_ARRAY）
2. 直接使用 @export 比较麻烦（例如一条线需要设置两个方向），可以使用属性方法（构造相对友好的交互界面供开发者设计关卡）
3. PoolStringArray -> PackedStringArray，但不再有 join 方法；可以使用字符串反向 join：`",".join(PackedStringArray(Slot.keys()))`
4. 这部分涉及到位运算、图数据结构，以及 Godot 内置的数据结构转换等，相对枯燥晦涩；这里建议不需要深入了解，大致明白原理，然后套用即可

【大问题】按照教程去除 @export，更改为高级导出，保存的 *tres 文件不包含字典数据；检查器也没有对应的选单，即使更改后保存脚本，检查器也不会及时做出反应！

【解决】删除 _set_property_list 函数的 强返回类型 即可（原因不详：虚函数或返回类型不确定，不应该注明返回类型？但参照教程和 Godot 4 文档中的案例，除了返回类型标注外完全一致，不得已尝试删除返回类型标注，结果成功了）

相关文档内容：[Object — Godot Engine (stable) documentation in English](https://docs.godotengine.org/en/stable/classes/class_object.html#class-object-method-get-property-list)

可能有关的 issue 等：
- [GDScript 2.0：高级导出（“\_get\_property\_list（）”）不起作用 ·问题 #58239 ·戈多引擎/戈多](https://github.com/godotengine/godot/issues/58239)
- [Deleting only repeating "Scripted Variables" props by object71 · Pull Request #58443 · godotengine/godot](https://github.com/godotengine/godot/pull/58443)

关于枚举和字典：
- [What is enum? - Godot Engine - Q&A](https://ask.godotengine.org/37768/what-is-enum)
- [GDScript reference — Godot Engine (latest) documentation in English](https://docs.godotengine.org/en/latest/tutorials/scripting/gdscript/gdscript_basics.html#enums)

### 8. 小游戏逻辑

1. 重新绘制的更新函数 update() 在 Godot 4 中更改为 queue_draw()
2. 如果遇到工具脚本的效果无法在编辑器中直接查看，但运行正常的情况，再手动重启即可
3. Godot 4 中 enum 类型不支持 values() 这样的 非 dictionary built-in methods
4. 处理 H2 -> H3 门的部分：重申 ToH3 父节点为新节点 FlagSwitch
5. Area2D 只在无材质的时候需要设置碰撞体，有材质的时候默认碰撞体为材质的长宽
6. 二周目可以重新创建一个更难的 hard.tres，然后使用信号判断在脚本中设置即可

### 9. 回到主菜单

（没什么需要补充的）

### 10. 保存与加载

1. File -> FileAccess，且必须用open函数赋值，不能创建无参的对象；open函数返回的也是FileAccess对象，如果没有创建成功则返回null
2. to_json(data) -> JSON.stringify(data)
3. 正式游戏需要在读档时对数据进行检查（是否读取成功？是否是字典？是否有需要的字段？）
4. `"current_scene": get_tree().current_scene.filename.get_file().get_basename()` -> `"current_scene": get_tree().current_scene.scene_file_path.get_file().get_basename()`：Node 中的 filename 属性更改为 scene_file_path
5. 全局变量初始化的顺序，就是项目设置中全局变量的排列顺序
6. 保存游戏存档的位置路径一般写成 `user://xxx` 而不是 `res://xxx`，这样游戏数据会保存到用户本地的位置而不是项目文件中（实际存放的路径根据不同设备设置等有所不同）
