# 07 · 节点与场景树

> 对应示例：`examples/07_nodes/`

## 7.1 节点模型：Godot 的世界观

Godot 里一切运行时对象都是**节点（Node）**：画面上的角色是 `Sprite2D` 节点，物理
碰撞是 `Area2D` 节点，UI 按钮是 `Button` 节点，连"游戏本身"也是——节点按父子关系
组成一棵**场景树（Scene Tree）**，树根 `root` 是一个 `Window`。节点自带的通用能力：

- 有名字（同层唯一）、有路径（`/root/Player/Sprite` 这样可从全树定位）；
- 有生命周期回调（`_init` → 进树 → `_ready` → 每帧 `_process` → 出树 → 释放）；
- 能收发信号（第 08 章）；
- 通过**子节点组合**获得功能——"角色 = CharacterBody2D + Sprite2D + CollisionShape2D"
  不是继承出来的，是拼出来的。这是 Godot "组合优于继承"的核心设计。

真实项目里这棵树由编辑器搭、存成 `.tscn` 场景文件；本章用代码在 headless 环境
**手动搭树**，把树的机制本身看清楚。

## 7.2 示例全文

`examples/07_nodes/main.gd`：

```gdscript
extends SceneTree

func _initialize():
    var player := Node2D.new()
    player.name = "Player"
    root.add_child(player)

    var hp_label := Label.new()
    hp_label.name = "HPLabel"
    player.add_child(hp_label)

    var sprite := Sprite2D.new()
    sprite.name = "Sprite"
    player.add_child(sprite)

    print("player 的父节点：", player.get_parent().name)
    print("player 子节点数：", player.get_child_count())
    print("hp_label 排第：", hp_label.get_index())
    print("按路径取节点：", root.get_node("Player/Sprite").name)
    print("player 是否已 ready：", player.is_node_ready())

    await process_frame
    print("player 路径：", player.get_path())
    print("hp_label 路径：", hp_label.get_path())

    _print_tree(root, 0)
    quit()

func _print_tree(node: Node, depth: int) -> void:
    print("  ".repeat(depth), node.name, " (", node.get_class(), ")")
    for child in node.get_children():
        _print_tree(child, depth + 1)
```

实测输出：

```text
player 的父节点：root
player 子节点数：2
hp_label 排第：0
按路径取节点：Sprite
player 是否已 ready：false
player 路径：/root/Player
hp_label 路径：/root/Player/HPLabel
root (Window)
  Player (Node2D)
    HPLabel (Label)
    Sprite (Sprite2D)
```

## 7.3 逐段讲解

**创建与挂树。** `Node2D.new()` 只是构造了实例，此刻它**不在树上**；
`root.add_child(player)` 才把它挂到根窗口下。之后 `player.add_child(hp_label)`
层层往下挂。`name` 可改，同层重名时引擎自动追加 `@2`、`@3` 后缀。

**树内关系 API。** `get_parent()` / `get_child_count()` / `get_children()` /
`get_index()`（在兄弟中的排位——注意**没有** `get_child_index(node)` 这个方法，
父查子排位要用 `get_children().find(x)`，本项目实测踩过）。

**按路径取节点。** `root.get_node("Player/Sprite")` 用相对路径从任意节点向下定位；
脚本里更常见的简写是 `$Player/Sprite` 和 `@onready var sprite := $Sprite`
（`@onready` 让取值延迟到 `_ready` 时执行，见 7.5）。路径找不到会运行时报警
"Node not found"——重构改名后最容易批量引爆的就是这些字符串路径。

**打印全树。** `_print_tree` 递归 `get_children()`，配合 `get_class()`（类名字符串）
输出缩进树——调试结构问题的第一工具；引擎自带的 `root.print_tree()` 也干这事。

## 7.4 时序实测：`--script` 模式下"进树"不即时

两个反直觉输出都值得记住：

1. `player 是否已 ready：false`——明明 `add_child` 了；
2. `player 路径` 两行被放在 `await process_frame` **之后**才打印——因为之前
   `get_path()` 会报错。本项目最初版本在 `add_child` 后直接 `get_path()`，实测得到：

   ```text
   ERROR: Cannot get path of node as it is not in a scene tree.
   ```

原因：`--script` 启动时 `_initialize()` 在**主循环第一次迭代之前**执行，此时整棵树
尚未被引擎"激活"——父子关系已挂上（所以 `get_parent`、`get_node` 都能用），但
`_ready` 通知和路径计算要等第一次迭代。`await process_frame`（等一帧）后一切正常。

**真实游戏里不是这样**：编辑器启动的项目中 `add_child()` 返回时 `_ready` 已经同步
触发、`get_path()` 立即可用。这个差异是 headless 教学模板的盲区（01 章 1.6 就预警
过），读输出时把 `false` 理解为"树还没开机"而不是"ready 机制不可靠"。

## 7.5 生命周期回调与常用操作（真实项目形态）

节点脚本的标准骨架（这段不是示例文件的一部分，是 `extends Node2D` 脚本的通用形）：

```gdscript
extends Node2D

@onready var sprite: Sprite2D = $Sprite   # _ready 前自动完成赋值

func _ready() -> void:
    print("节点已准备就绪")               # 进树且子节点就绪后调用一次

func _process(delta: float) -> void:
    pass                                  # 每帧一次（09 章主场）

func _exit_tree() -> void:
    pass                                  # 出树时清理
```

- **初始化顺序**：父 `_ready` 先于子 `_ready`？不——Godot 保证**子先父后**
  （自底向上），`@onready` 变量在其所在节点 `_ready` 前完成绑定；
- **释放**：`queue_free()` 请求下帧删除节点（及其整棵子树）并自动断连信号；
  `free()` 立即删除但**绝不能在遍历自身子节点时调用**——默认用 `queue_free`；
- `.tscn` 场景文件就是这棵树的序列化：`[node name="Player" type="Node2D"]` 一段
  一个节点，挂脚本、设属性——第 12 章进编辑器后你会回头认它。

## 7.6 坑位清单

1. **`new()` 后不 `add_child` 就是孤儿**：不报错、不处理、不 ready，内存里静躺着。
   忘挂树是新手第一大 bug，症状是"代码全对但什么都不发生"。
2. **headless `_initialize` 里树未激活**（7.4 实测）：路径类 API 前先
   `await process_frame`；或接受"结构验证"与"行为验证"分开跑。
3. **`get_child_index` 不存在**（7.3），别从 Godot 3 记忆或别的语言惯性里写出来。
4. **`free()` 后继续用引用**：所有 `Object` 释放后句柄失效，访问报
   "previously freed"；判活用 `is_instance_valid(node)`，但正确姿势是释放后主动
   置 `null`。
5. **重名静默加后缀**：`$Player` 找的是"名字叫 Player 的孩子"，引擎自动改名
   （`Player@2`）后路径就断了——创建前查重或先设好 `name`。

上一章：[06 · 集合：数组与字典](06-collections.md) ｜ 下一章：[08 · 信号](08-signals.md) ｜ 返回：[README](../README.md)
