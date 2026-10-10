# 08 · 信号

> 对应示例：`examples/08_signals/`

## 8.1 信号是什么

信号是 Godot 内置的**观察者模式**：一个对象（发射方）声明"某件事发生了"，
不关心谁在听；任何数量的对象（接收方）事先订阅回调，事后各做各的。节点之间因此
不必互相持有引用——UI 按钮不需要认识游戏逻辑，游戏逻辑也不需要认识 UI。

Godot 里最常用的三类信号源：

- **控件自带**：`Button.pressed`、`LineEdit.text_submitted`、`Timer.timeout`——
  编辑器里拖线或用代码连接，是全引擎的交互骨架；
- **物理/区域**：`Area2D.body_entered`、`Area2D.body_exited`——碰撞检测的事件入口；
- **自定义**：游戏状态变化（分数、血量、剧情标记）——本章示例的主线。

## 8.2 示例全文

`examples/08_signals/main.gd`：

```gdscript
extends SceneTree

signal score_changed(new_score: int)
signal item_picked(item: String, count: int)

func _initialize():
    score_changed.connect(_on_score_changed)
    item_picked.connect(func(item: String, count: int):
        print("拾取 %s x%d" % [item, count]))

    score_changed.emit(120)
    item_picked.emit("金币", 3)

    print("是否仍连接：", score_changed.is_connected(_on_score_changed))
    score_changed.disconnect(_on_score_changed)
    print("断开后再 emit，_on_score_changed 不会再执行：")
    score_changed.emit(999)
    quit()

func _on_score_changed(value: int) -> void:
    print("新分数：", value)
```

实测输出：

```text
新分数：120
拾取 金币 x3
是否仍连接：true
断开后再 emit，_on_score_changed 不会再执行：
```

## 8.3 逐行拆解

**声明**：`signal score_changed(new_score: int)` ——4.x 的信号**带类型参数**。
发射时传错参数个数/类型，静态检查直接拦住；3.x 的信号是无类型的，只能靠约定。

**订阅**：两种形态示例各用了一种。

- `score_changed.connect(_on_score_changed)`：把方法名当值传 → 自动成为绑定本实例
  的 `Callable`（05 章 5.3 的知识在这里兑现）。回调命名惯例 `_on_<信号名>`，
  参数表与信号声明对齐（`value: int` 接住 `new_score`）。
- `item_picked.connect(func(...): ...)`：**lambda 直接当回调**，适合三行以内的
  一次性逻辑；缺点是没法单独 disconnect（没人持有它的 Callable 引用），
  需要反悔时先用变量接住再连。

**发射**：`score_changed.emit(120)` 同步依次调用所有已连回调——emit 返回时回调
全部执行完毕。发射方不需要知道有没有监听者、有几个。

**反注册**：`disconnect()` 与 `is_connected()` 成对出现。示例断开后 `emit(999)`
没有再打印回调行（输出第四行之后归于平静），演示的就是"没监听者的信号是安全的
空操作"。

## 8.4 与 3.x 写法对照（读懂老教程用）

| Godot 3（字符串 API，4.x 仍兼容但过时） | Godot 4（本教程采用） |
|---|---|
| `connect("score_changed", "_on_score_changed")` | `score_changed.connect(_on_score_changed)` |
| `emit_signal("score_changed", 120)` | `score_changed.emit(120)` |
| `signal score_changed`（无参） | `signal score_changed(new_score: int)` |
| 编辑器连线为主 | 代码连接为主，编辑器连线生成同名桩函数 |

老项目迁移时最阴的兼容坑：字符串连接在信号改名后**不报编译错**，运行时才炸；
点号 API 则改名即报错——这也是选 4.x 风格的原因之一。

## 8.5 进阶开关：连接参数

`connect` 的第二个参数是位标志（`ConnectFlags` 枚举），常用两个：

```gdscript
signal fired

fired.connect(_on_fired, ConnectFlags.CONNECT_ONE_SHOT)  # 触发一次后自动断开
fired.connect(_on_fired, ConnectFlags.CONNECT_DEFERRED)  # 回调延到下帧执行
```

`CONNECT_ONE_SHOT` 适合"一次性事件"（过场结束、奖励领取）；`CONNECT_PERSIST`
是编辑器连线时写进 `.tscn` 的标记，代码连接一般用不到。节点释放时其成员方法
回调会被**自动断开**（引擎按绑定对象清理连接），这是信号比手写回调列表安全的关键
——但 lambda 回调不随节点释放自动清理，它捕获的 `self` 可能把已 `queue_free` 的
节点"续命"成幽灵监听者，订阅时优先用具名方法。

## 8.6 跨节点实战形态（真实项目速写）

本章示例为了 headless 可运行把发射方和监听方放在同一脚本；真实项目里它们分属
不同节点，模式如下（讲解用伪场景，非示例文件）：

```gdscript
# player.gd —— 数据的主人声明并广播信号
signal died

func take_damage(amount: int) -> void:
    hp -= amount
    if hp <= 0:
        died.emit()

# main.gd —— 组装方负责连线，两个节点互不认识
func _ready() -> void:
    $Player.died.connect(_on_player_died)
    $HUD.show_gameover.connect($Player.reset)

func _on_player_died() -> void:
    $HUD.game_over()
```

"信号定义在数据主人身上、连线发生在组装场景"——记住这条职责划分，Godot 的
事件流就顺了。

## 8.7 坑位清单

1. **emit 是同步的**：回调里再 emit 会递归/连环立即执行，复杂时序用第 10 章
   `await` 拆段或 `call_deferred` 延到下帧。
2. **同一 Callable 重复 connect 会被拒绝**（4.7.1 实测：运行时 ERROR"already
   connected"，第二根线不生效但不崩溃）——想要"再连一次换行为"先 `disconnect`
   再 `connect`；判断用 `is_connected()`（示例演示过）。
3. **lambda 监听者无法单独断开**（8.3），且可能拖住已释放节点的幽灵引用（8.5）——
   需要生命周期管理时写具名方法。
4. **回调签名必须能接住信号参数**：参数多了编译报错、少了运行时炸——改信号声明
   时全项目搜索回调点，这正是带类型声明的价值。

上一章：[07 · 节点与场景树](07-nodes.md) ｜ 下一章：[09 · 输入与帧循环](09-input-loop.md) ｜ 返回：[README](../README.md)
