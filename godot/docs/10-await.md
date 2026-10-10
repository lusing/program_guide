# 10 · await 与计时器

> 对应示例：`examples/10_timers/`

## 10.1 示例全文

`examples/10_timers/main.gd`：

```gdscript
extends SceneTree

func _initialize():
    print("倒计时开始")
    for i in range(3, 0, -1):
        print(i, "……")
        await create_timer(0.5).timeout
    print("发射！")

    var timer := create_timer(0.3)
    print("先做点别的，稍后再等这个计时器……")
    await timer.timeout
    print("0.3 秒计时器到期")

    quit()
```

实测输出：

```text
倒计时开始
3……
2……
1……
发射！
先做点别的，稍后再等这个计时器……
0.3 秒计时器到期
```

## 10.2 `await`：让出函数，等一个信号

`await` 后面跟的**不是值，是信号**（或协程的恢复点）。语义：暂停当前函数的执行、
把控制权交还主循环，直到目标信号发射再从暂停处继续。示例里每一句
`await create_timer(0.5).timeout` 就是"造一个一次性计时器，等它的 `timeout`
信号"——主循环照常跑帧，函数在 0.5 秒后复活。

由此推出 GDScript 协程的三条基本法则：

1. **函数体内出现 `await`，该函数即协程**：调用它不会同步跑完，而是立刻返回一个
   挂起状态；想拿到它的结果要在调用处也 `await`：

   ```gdscript
   func _initialize():
       await play_cutscene()   # 不写 await 就是"发射后不管"，_initialize 会直接跑到 quit()
       quit()
   ```

2. **等待期间世界是活的**：`_process` 照常执行（第 09 章示例正是靠这一点——
   `await create_timer(1.0).timeout` 的 1 秒里 player 每帧都在移动）。
3. **await 的返回值就是信号参数的值**：`var who = await player_died` 能直接接住
   信号携带的数据（08 章的带参信号在这里二次受益）。

## 10.3 计时器的三种形态

| 形态 | 用法 | 场景 |
|---|---|---|
| `create_timer(sec)`（`SceneTree.create_timer`，节点脚本里写 `get_tree().create_timer`） | 代码里随手造一次性计时器；返回 `SceneTreeTimer`，`await` 它的 `timeout` | 延迟执行、连招窗口、伪动画节拍 |
| `Timer` 节点 | 场景里摆一个，设 `wait_time`/`one_shot`，连它的 `timeout` 信号；`start()` 启动 | 冷却、刷怪、需要中途取消/重开的周期性事件 |
| `SceneTreeTimer` 实例存变量延后 await（示例第二段） | 先起计时、后等——"截止时间"模式 | 输入窗口期（QTE）、限时事件 |

示例第二段演示了 `create_timer` 返回对象可以先存下、稍后再 `await`——这使
"0.3 秒内必须完成 X，否则 Y"成为可写的逻辑（10.5 见完整套路）。

**4.7.1 实测坑**：想跳过 `create_timer` 直接 `SceneTreeTimer.new(0.3)` 会遭遇
一串编译错误：

```text
Parse Error: Native class "SceneTreeTimer" cannot be constructed as it is abstract.
```

`SceneTreeTimer` 没有公开构造函数，**只能由 `create_timer` 生产**——记姿势别记绕路。

## 10.4 忙等循环为什么是错的

本教程的前身指南里有一个"每 0.5 秒打印一次"的写法：

```gdscript
while elapsed < 3.0:          # 反面教材：忙等
    print("elapsed = ", elapsed)
    elapsed += 0.5
```

它只是把数字加快的假时钟——循环占着 `_initialize` 不返回，主循环一帧都不处理，
elapsed 加到 3 只是一瞬间的事，和"现实过了 3 秒"毫无关系。真实引擎里它更惨：
**整个游戏卡死在 while 里**（帧停、输入停、渲染停）。要做"等 0.5 秒再做事"，
唯一正道是 10.2/10.3 的 await/Timer——示例的 `for i in range(3, 0, -1)` 配
`await create_timer(0.5).timeout` 就是它的对偶写法。

## 10.5 限时窗口：延后等待 + 共享状态（4.7.1 完整实测）

"0.3 秒内确认，否则超时"——GDScript 没有 `await 信号A 或 信号B` 的原生二选一
语法（await 一次只能等一根信号），惯用组合是"计时器先起、稍后再等、中间收集结果"。
但这里藏着 05 章捕获语义的实弹——**朴素布尔标志位会被 lambda 按值截胡**：

```gdscript
signal confirmed

func _initialize():
    var got_it := false
    confirmed.connect(func(): got_it = true)      # 改的是副本！
    var deadline := create_timer(0.3)
    create_timer(0.1).timeout.connect(func(): confirmed.emit())
    await deadline.timeout
    print("窗口内完成" if got_it else "超时")       # 4.7.1 实测：永远打"超时"
    quit()
```

把标志放进引用容器即可（`state` 本身也是按值捕获，但复制的是引用，底层数据共享）：

```gdscript
signal confirmed

func _initialize():
    var state := {"got_it": false}                # Dictionary 引用语义：跨闭包可写
    confirmed.connect(func(): state.got_it = true)
    var deadline := create_timer(0.3)
    create_timer(0.1).timeout.connect(func(): confirmed.emit())
    await deadline.timeout
    print("窗口内完成" if state.got_it else "超时")  # 实测：窗口内完成 ✓
    quit()
```

要点三连：计时器先造（deadline 开始走）、逻辑照常跑、在合适位置才 await——
"等待"与"做事"解耦；而跨 await/闭包传递状态时，**永远用引用容器**（Dictionary/
Array/对象），或对布尔改用实例成员变量（`self.got_it`，方法内改自己总有效）。

## 10.6 坑位清单

1. **调用协程忘 `await`**：函数"看起来没执行/执行到一半消失"，其实是你没等它。
   返回值也别直接 `var x = some_coroutine()`——拿到的是挂起状态不是结果。
2. **`SceneTreeTimer` 不可直接构造**（10.3 实测编译错误），统一 `create_timer`。
3. **忙等循环冻结主线程**（10.4）：任何 `while` 套 `elapsed` 凑秒的冲动都应
   转化为 `await`。
4. **await 之后对象可能已死**：0.5 秒的窗口里场景可能已切换、监听节点可能已
   `free`——恢复执行后第一件事是 `if not is_instance_valid(self): return` 或
   用 `tree_exited` 信号做中止。协程不会自动跟着节点释放而取消。
5. **`create_timer` 默认只响一次且不可复用**：要循环/暂停/重启用 `Timer` 节点
   （`one_shot = false`）。它的后三个参数控制细节：
   `create_timer(sec, process_always, process_in_physics, ignore_time_scale)`——
   想让计时器跟随 `Engine.time_scale`（慢动作），保持第四参默认 `false` 即可。
6. **布尔标志穿不过 lambda**（10.5 实测"永远超时"）：跨闭包改状态用引用容器或
   实例成员。

上一章：[09 · 输入与帧循环](09-input-loop.md) ｜ 下一章：[11 · 实战：回合制战斗](11-mini-rpg.md) ｜ 返回：[README](../README.md)