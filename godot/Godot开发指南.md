# Godot 开发指南

## 1. 什么是 Godot

Godot 是一个跨平台、开源的 2D/3D 游戏引擎与交互式应用开发平台。与传统的纯脚本语言不同，Godot 采用“节点（Node） + 场景（Scene） + 信号（Signal）”的结构模型，使游戏开发和可视化编程更自然。

在本教程中，我们重点使用 GDScript 语言来快速掌握 Godot 的核心机制：

- 项目结构
- 节点与场景
- 变量与数据类型
- 函数与控制流
- 集合与字典
- 信号与事件
- 运行循环与输入处理

---

## 2. 工具链与环境

本机安装路径：

- Godot：`G:\scoop\apps\godot\current\godot.console.exe`

如果你使用的是命令行环境，可以直接验证脚本：

```powershell
G:\scoop\apps\godot\current\godot.console.exe --headless --path G:\code\guide\godot\examples\01_hello --script G:\code\guide\godot\examples\01_hello\main.gd
```

这类命令不需要启动编辑器窗口，也能确认脚本在当前环境中的可执行性。

---

## 3. Godot 项目结构

一个最小的 Godot 项目通常包括：

```text
project/
├── project.godot
├── main.gd
├── scenes/
│   └── level.tscn
└── scripts/
    └── player.gd
```

其中：

- `project.godot`：项目配置文件
- `main.gd`：入口脚本
- `.tscn`：场景文件
- `.gd`：脚本文件

在命令行脚本验证场景下，我们可以直接用单个脚本做最小测试，而不必额外创建 UI 窗口。

---

## 4. GDScript 基础：Hello, World

下面是最简单的 Godot 入门脚本：

```gdscript
extends SceneTree

func _initialize():
    print("Hello, Godot!")
    quit()
```

关键点：

- `extends SceneTree`：让脚本作为应用主循环运行
- `print()`：输出调试信息
- `quit()`：退出程序

这是最适合在 headless 环境中验证的脚本模板。

---

## 5. 变量与基本类型

GDScript 是动态类型语言，但依然支持常见数据类型：

```gdscript
extends SceneTree

func _initialize():
    var score := 100
    var player_name := "Alice"
    var is_ready := true
    var hp_ratio := 0.75

    print("name: ", player_name)
    print("score: ", score)
    print("ready: ", is_ready)
    print("hp_ratio: ", hp_ratio)
    quit()
```

GDScript 中的变量通常使用 `var` 声明，支持：

- 整数：`int`
- 浮点数：`float`
- 字符串：`String`
- 布尔值：`bool`
- 数组：`Array`
- 字典：`Dictionary`

---

## 6. 控制流

Godot 也支持常见的控制流结构：

```gdscript
extends SceneTree

func _initialize():
    var value = 10

    if value > 5:
        print("value 大于 5")
    elif value == 5:
        print("value 等于 5")
    else:
        print("value 小于 5")

    for i in range(3):
        print("i = ", i)

    var count = 0
    while count < 3:
        print("count = ", count)
        count += 1

    quit()
```

这类结构和其它主流脚本语言相似，适合用于游戏状态、动画控制和 AI 逻辑。

---

## 7. 函数和返回值

函数是 GDScript 中构建逻辑的核心：

```gdscript
extends SceneTree

func add(a: int, b: int) -> int:
    return a + b

func _initialize():
    var answer = add(7, 5)
    print("7 + 5 = ", answer)
    quit()
```

函数参数可以带类型注解，返回值也可以写成 `-> int`。此外，Godot 允许你将逻辑封装为更清晰的模块化方法。

---

## 8. 数组、字典和集合

```gdscript
extends SceneTree

func _initialize():
    var inventory = ["苹果", "水晶", "药水"]
    inventory.append("火把")
    print("背包：", inventory)

    var stats = {
        "hp": 100,
        "mana": 80,
        "level": 3
    }

    print("HP = ", stats["hp"])
    print("Mana = ", stats.get("mana", 0))
    quit()
```

数组和字典在游戏逻辑中非常常见，例如：

- 物品栏
- 怪物属性
- 关卡配置
- 血量和状态表示

---

## 9. 节点、场景和对象树

Godot 的核心架构是“节点树”（Node Tree）。每个场景由一组节点组成，节点可以有：

- `Node`
- `Sprite2D`
- `CharacterBody2D`
- `Area2D`
- `Control`
- `Node3D`

节点之间通过父子关系组织，游戏逻辑通常附着在节点脚本上。比如：

```gdscript
extends Node2D

func _ready():
    print("节点已准备就绪")
```

`_ready()` 是一个非常重要的回调函数，通常用于初始化对象。

---

## 10. 信号（Signal）

信号是 Godot 中极其重要的机制，用于在不同节点之间通信：

```gdscript
extends SceneTree

signal score_changed

func _initialize():
    connect("score_changed", _on_score_changed)
    emit_signal("score_changed", 120)
    quit()

func _on_score_changed(value):
    print("新分数：", value)
```

信号常见于：

- 按钮点击
- 计时器结束
- 子节点发出事件给父节点
- 动画状态变化

---

## 11. 输入与游戏循环

Godot 中最常见的循环入口是：

- `_process(delta)`：每帧处理逻辑
- `_physics_process(delta)`：适合物理模拟

例如：

```gdscript
extends Node2D

var speed = 200.0

func _process(delta):
    var direction = Vector2.ZERO
    if Input.is_action_pressed("ui_left"):
        direction.x -= 1
    if Input.is_action_pressed("ui_right"):
        direction.x += 1
    if Input.is_action_pressed("ui_up"):
        direction.y -= 1
    if Input.is_action_pressed("ui_down"):
        direction.y += 1

    position += direction * speed * delta
```

这个模式适合角色移动、相机跟随、敌人 AI 和 UI 状态更新。

---

## 12. 一个完整的小例子：移动计时器

下面是一个简洁的示例，模拟一个计时器并输出状态：

```gdscript
extends SceneTree

var elapsed := 0.0

func _initialize():
    print("启动计时器")
    while elapsed < 3.0:
        print("elapsed = ", elapsed)
        elapsed += 0.5
        await get_tree().create_timer(0.5).timeout
    print("计时结束")
    quit()
```

这展示了：

- 循环
- 延时
- 事件驱动等待
- 程序退出

---

## 13. 实战建议

学习 Godot 时建议按下面顺序练习：

1. 先写最小的 `SceneTree` 脚本，确认环境可运行
2. 掌握 GDScript 基础语法：变量、函数、循环
3. 学会 `Array` 和 `Dictionary` 的使用
4. 理解节点与信号如何协作
5. 逐步加入输入、动画和物理逻辑
6. 最后构建一个完整的小型游戏或交互演示

---

## 14. 实战目标

本目录的示例包括：

- 01_hello：最小启动脚本
- 02_variables：变量、字符串和布尔值
- 03_functions：函数和复用逻辑
- 04_signals：事件与信号机制
- 05_input_and_loop：输入与循环处理

通过这些练习，你将打下较扎实的 Godot 2D 开发基础。

---

## 15. 结论

Godot 的好处在于：

- 教学友好
- 可视化编辑器强大
- 2D/3D 功能均衡
- GDScript 易于上手
- 适合快速 prototyping 和独立游戏开发

如果你已经掌握了脚本基础并能在本机运行示例，那么下一步就可以进入：

- 节点树和场景设计
- 角色控制
- 碰撞检测
- UI 和菜单
- 资源加载与动画系统

继续深入学习 Godot 会更加顺畅。
