# 12 · 进阶路线与总结

> 对应示例：无（本章是地图与路线）

## 12.1 你已经掌握的与还缺的

十节课走完，你现在具备：GDScript 语言全貌（02–06）、引擎对象模型（07）、事件
驱动（08）、实时循环（09–10）、以及一个整合小系统（11）。这些恰好是 Godot 官方
文档 "Getting started" 与 "GDScript the basics" 两节的深度——**语言关已过**，
接下来的全部课题是**工程关**：把 headless 脚本思维切换到编辑器 + 场景工作流。

## 12.2 切入真实工作流：场景与编辑器

本教程用 `--script` 绕开了编辑器，现在把它捡回来——`godot -e --path <目录>`
或下载官方编辑器，新建工程后你会面对三样东西：

1. **场景（.tscn）**：节点的序列化树。用文本打开任何一个 `.tscn`，格式与 07 章
   代码搭出的树一一对应：

   ```ini
   [gd_scene load_steps=2 format=3]

   [node name="Player" type="Node2D"]
   script = ExtResource("1_abcde")

   [node name="Sprite" type="Sprite2D" parent="."]
   ```

   `[node ...]` 一节一个节点，`parent="."` 指根——`$Sprite` 取的就是它；编辑器
   里的"新建场景→添加子节点→挂脚本"改写的就是这个文件（因此 `.tscn` 适合进
   版本控制，diff 可读）。

2. **主场景**：`project.godot` 里 `run/main_scene="res://scenes/main.tscn"`，
   F5 启动即实例化它——对比 02 章的空字符串，这就是脚本模式与游戏模式的分界。

3. **节点即功能**：常用起手节点清单——

   | 需求 | 节点 |
   |---|---|
   | 角色移动+碰撞 | `CharacterBody2D` + `CollisionShape2D` + `Sprite2D` |
   | 触发区域（拾取、传送） | `Area2D` + `body_entered` 信号（08 章直接复用） |
   | UI | `Control` 家族：`Label`/`Button`/`TextureButton`，锚点+容器布局 |
   | 关卡瓦片 | `TileMapLayer` |
   | 动画 | `AnimationPlayer`（时间轴驱动属性/信号轨道）、`AnimatedSprite2D` |
   | 音频 | `AudioStreamPlayer`（`finished` 信号接 10 章 await） |

   角色控制器在 09 章 `player.gd` 基础上换 `velocity` + `move_and_slide()` 形态：

   ```gdscript
   extends CharacterBody2D

   func _physics_process(delta: float) -> void:
       var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
       velocity = direction * 200.0
       move_and_slide()
   ```

   `Input.get_vector` 一行完成 09 章四个 if + normalized 的全套（对角限速内置），
   `move_and_slide()` 负责沿碰撞面滑行。

## 12.3 学习路线（按依赖排序）

1. **官方 First 2D Game 教程**——用编辑器重做一遍本教程第 11 章的系统，把字典
   换成类、日志换成 UI；
2. **资源与存档**：`Resource` 自定义类（`class_name GameData extends Resource`）、
   `FileAccess` 读写 JSON（`JSON.new().stringify()`）；
3. **物理与碰撞层**：`Area2D`/`RayCast2D`、碰撞掩码（layer/mask 是新手劝退点，
   画图理解）；
4. **UI 与输入映射**：容器布局、`Theme`、手柄/键盘重映射（09 章动作抽象的兑现）；
5. **动画与状态机**：`AnimationPlayer` 信号轨道→08 章信号、`match`→04 章；
6. **导出与分发**：编辑器 Export 预设出 macOS/Windows/Linux/Web；
7. **性能深水区**：`_process` 预算（09 章 5）、对象池、`MultiMeshInstance`、
   GDExtension（C++/Rust 热路径）——本仓库的 [rust](../../rust/README.md) 可衔接。

## 12.4 与其他语言的对照速查

| 概念 | GDScript | 你熟悉的对应物 |
|---|---|---|
| 无括号条件、缩进块 | `if x > 1:` | Python |
| `:=` 推断 | `var n := 5` | C++/Go `auto`/`:=` |
| 值/引用分界 | Array/Dictionary/Object 引用；其余值 | Swift 结构体/类分界 |
| 观察者 | `signal` + `connect`/`emit` | Qt 信号槽、C# event |
| 协程 | `await 信号` | JS `await Promise`（但等的是事件） |
| 帧回调 | `_process(delta)` | 游戏引擎通用 delta 模式 |
| 无插值字符串 | `"%s" % v` / `.format()` | Python `%`/f-string 的半残版 |

## 12.5 结语

Godot 的教学友好在于分层清晰：语言一周、节点模型一周、工程习惯一月。本教程
解决前两层并给出第三层的地图。下一步最值得做的一件事：**用编辑器把第 11 章的
回合制战斗做成带界面的小游戏**——每个知识点都会以"原来你在编辑器里长这样"的
方式再学一遍。

上一章：[11 · 实战：回合制战斗系统](11-mini-rpg.md) ｜ 下一章：无（末章） ｜ 返回：[README](../README.md)
