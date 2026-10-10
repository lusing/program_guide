# 09 · 输入与帧循环

> 对应示例：`examples/09_input_loop/`（`main.gd` + `player.gd` 两个脚本）

## 9.1 每帧的节拍：`_process` 与 delta

节点进入场景树后，引擎每帧调用其 `_process(delta)`；物理帧另有
`_physics_process(delta)`（固定步长，默认 60Hz，处理 `RigidBody`/`CharacterBody`
的移动与碰撞）。`delta` 是**上一帧到这一帧的真实耗时（秒）**——所有"每秒多少
单位"的逻辑（速度、冷却、插值）都必须乘以它，才能在 30/60/144 帧的机器上表现一致。
这是实时编程第一课：**按秒编程，不要按帧编程**。

## 9.2 示例全文

移动逻辑挂在真实节点脚本 `examples/09_input_loop/player.gd`：

```gdscript
extends Node2D

var speed := 200.0

func _process(delta: float) -> void:
    var direction := Vector2.ZERO
    if Input.is_action_pressed("ui_right"):
        direction.x += 1
    if Input.is_action_pressed("ui_left"):
        direction.x -= 1
    if Input.is_action_pressed("ui_down"):
        direction.y += 1
    if Input.is_action_pressed("ui_up"):
        direction.y -= 1
    position += direction * speed * delta
```

驱动与观测在 `examples/09_input_loop/main.gd`：

```gdscript
extends SceneTree

const PlayerScript := preload("res://player.gd")

func _initialize():
    var player: Node2D = PlayerScript.new()
    player.name = "Player"
    root.add_child(player)

    print("起点：", player.position)
    Input.action_press("ui_right")
    print("模拟按住右键 1 秒……")
    await create_timer(1.0).timeout
    print("按住后位置：", player.position)

    Input.action_release("ui_right")
    await create_timer(0.5).timeout
    print("松开后位置：", player.position)
    print("期间共处理帧数：", Engine.get_process_frames())
    quit()
```

实测输出（数值随机器帧率小幅浮动）：

```text
起点：(0.0, 0.0)
模拟按住右键 1 秒……
按住后位置：(201.2121, 0.0)
松开后位置：(201.2121, 0.0)
期间共处理帧数：196
```

## 9.3 逐段讲解

**输入读的是"动作名"，不是按键码。** `Input.is_action_pressed("ui_right")` 查
**动作（action）**：`ui_up/ui_down/ui_left/ui_right` 是引擎内置动作（默认绑了方向键
与手柄十字键），项目动作在编辑器 Project Settings → Input Map 里自定义（如
`jump` 同时绑空格和手柄 A）。代码永远只写动作名——换键位、加手柄、做重映射全部
不碰逻辑代码，这就是抽象层的价值。判断单次按下/松开用 `is_action_just_pressed` /
`is_action_just_released`（跳跃触发用 just_pressed，按住蓄力用 pressed）。

**位移公式一行看三个知识点**（`player.gd` 末行）：

```gdscript
position += direction * speed * delta
```

1. `Vector2` 值语义 + `+=` 就地改写节点属性——`position` 是 `Node2D` 的属性，
   直接赋值即移动；
2. **`delta` 乘法保证帧率无关**：实测输出里 1 秒移动了 201.2 像素（speed=200
   的理论值，多出的 1.2 来自计时器与帧边界的重叠），无论这台机器当时跑了 196 帧
   还是 392 帧；
3. **对角线会超速**：四个 `if` 独立累加，同时按右+下时 `direction=(1,1)`，
   模长 √2——斜着走快 41%。经典修法：`direction = direction.normalized()`（对
   非零向量除以自身模长；`Vector2.ZERO.normalized()` 返回 ZERO，不会除零）。

**headless 怎么"按键"?** `Input.action_press("ui_right")` /
`action_release(...)` 直接向输入系统注入动作状态，等价于玩家按住/松开——这让
输入逻辑在命令行里也可验证（本教程示例的看家技巧），也是做输入回放、连招宏、
自动化测试的正道入口。

**main.gd 的组装**：`preload("res://player.gd")` 编译期加载脚本资源（对比
`load()` 运行期加载；常量位置用 `preload` 是惯例）；`.new()` 实例化脚本对应的
节点类；`player: Node2D = ...` 的显式注解让后面 `player.position` 有静态检查。
`Engine.get_process_frames()` 返回启动以来累计主循环帧数，用来印证"约 1.5 秒
跑了约 200 帧 → 帧率越高 delta 越小、位移不变"。

## 9.4 输入的另一半：事件回调

`_process` 是"每帧轮询"，Godot 同时提供"事件推送"入口：

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            print("Esc 被按下")

func _input(event: InputEvent) -> void:
    pass   # 更早的一层，可用于全局手势；get_viewport().set_input_as_handled() 可吞事件
```

三层管道：`_input` →（GUI Control 消费）→ `_unhandled_input`。轮询适合"持续状态"
（移动、按住蓄力），事件回调适合"离散动作"（Esc 菜单、点击射击）。`echo` 是
键盘自动重复——不判 `not event.echo`，长按 Esc 会反复触发。

## 9.5 坑位清单

1. **忘了乘 delta**：帧率敏感 bug 之王。144Hz 玩家快 2.4 倍，QA 机外才发现。
2. **对角线超速**（9.3）：`normalized()` 一行解决，2D 移动从第一天就写对。
3. **`ui_*` 是内置动作，自定义动作必须先注册**：`is_action_pressed("dash")` 在
   Input Map 里没有 `dash` 时报错——真实项目在编辑器 Project Settings → Input Map
   点选注册；纯 headless 工程可用 `InputMap.add_event()` 配合手工构造的
   `InputEventKey` 代码注册，但那是给测试用的苦力活，别写进业务逻辑。
4. **物理移动写进 `_physics_process`**：`CharacterBody2D.move_and_slide()` 每
   物理帧调用一次才有稳定的碰撞检测；放在 `_process` 里会随帧率抖动。
5. **`_process` 里做重活 = 主动降帧**：每帧预算 16.6ms，射线扫描/寻路要么分摊
   （每帧处理 N 个）、要么丢给 `TaskProcessor`/线程（12 章方向）。

上一章：[08 · 信号](08-signals.md) ｜ 下一章：[10 · await 与计时器](10-await.md) ｜ 返回：[README](../README.md)
