# 01 · Godot 全景

## 1.1 Godot 是什么

Godot 是一个跨平台、开源的 2D/3D 游戏引擎与交互式应用开发平台。和"一门纯语言"不同，
学 Godot 实际上是学三样东西：

1. **GDScript**——引擎自带的脚本语言（本教程主线），语法接近 Python，但与引擎 API
   深度绑定；
2. **节点树（Node Tree）**——Godot 的内容组织模型：一切游戏对象都是节点，节点组成
   树，树就是场景；
3. **信号（Signal）**——节点之间的解耦通信机制，相当于内置的观察者模式。

对会编程（Python/JS/C 家族背景皆可）的读者，GDScript 语法半天上手，真正的学习曲线
在后两者：**节点树的生命周期**与**信号驱动的事件流**。本教程把重点放在这两处。

## 1.2 版本格局：为什么必须分清 3.x 与 4.x

Godot 3 与 Godot 4 的 API 有实质性断裂，而网上教程半数是 3.x 时代的。最典型的差异
就是信号写法——3.x 用字符串 API：

```gdscript
# Godot 3 风格（网上老教程常见）——本教程不采用
connect("score_changed", "_on_score_changed")
emit_signal("score_changed", 120)
```

4.x 中信号是一等对象，用点号 API：

```gdscript
# Godot 4 风格（本教程采用）
score_changed.connect(_on_score_changed)
score_changed.emit(120)
```

字符串风格在 4.x 里仍能跑通（兼容层），但类型化的 `signal` 声明 + 点号调用能在写错
参数时立刻报错，教学与工程价值都更高。读到任何 Godot 资料，先确认版本号。

## 1.3 本教程的验证环境与工具链

所有示例都在本机实测通过：

- **Godot 4.7.1**（macOS，MacPorts）：`/opt/local/bin/godot`
- 示例工程声明 `config/features=PackedStringArray("4.3")`，即按 4.3 语法编写、
  在 4.7.1 上回归验证——4.x 小版本向后兼容，代码在两处都成立。

验证通过命令行 **headless 模式**完成，不启动任何窗口：

```bash
cd godot
godot --headless --path examples/02_hello --script main.gd
```

三个参数的分工：

| 参数 | 作用 |
|---|---|
| `--headless` | 无渲染、无窗口，纯命令行运行 |
| `--path <目录>` | 指定工程根（内含 `project.godot`），此后脚本路径以 `res://` 相对它解析 |
| `--script <脚本>` | **相对工程根**的脚本路径，引擎加载它并作为主循环运行 |

## 1.4 `extends SceneTree`：教学模板，不是真实项目形态

本教程前 10 章的示例脚本都以这样的模板开头（第 02 章逐行讲解）：

```gdscript
extends SceneTree

func _initialize():
    print("Hello, Godot!")
    quit()
```

让脚本继承 `SceneTree`（引擎主循环本身），`_initialize()` 就会在启动时被调用，
`quit()` 退出——这让我们在命令行里直接验证 GDScript 语法与引擎 API。

**但要明确边界**：真实游戏项目里，逻辑写在挂在场景节点上的脚本中（`extends Node2D`
等），由编辑器里的场景驱动；`SceneTree` 模板只是无编辑器环境下的最小可运行载体。
第 07 章起会过渡到真实的节点树模型。

## 1.5 章节地图与学法

| 段 | 章 | 内容 |
|---|---|---|
| 语言基础 | 02–06 | 运行模型、变量、控制流、函数、集合 |
| 引擎核心 | 07–10 | 节点树、信号、输入与帧循环、await 异步 |
| 实战 | 11 | 回合制战斗系统（整合全部知识点） |
| 收尾 | 12 | 进入编辑器与真实项目的进阶路线 |

每章标准学法：**读讲解 → 跑示例 → 改代码再跑**。本章讲解用到的所有代码都完整
嵌在正文里；示例目录（如 `examples/02_hello/`）是同一份代码的可运行副本，
用 `./run-all.sh` 批量验证。

## 1.6 坑位清单

1. **`--script` 路径相对工程根**：传绝对路径或工程外路径会被解析成 `res://…` 并报
   `File not found`——更阴的是进程仍以退出码 0 结束，CI 里必须校验输出文本而非退出码。
2. **3.x 教程遍地**：`get_node("x")` 的字符串风格、`emit_signal()`、无类型信号参数，
   都是 3.x 特征；照抄进 4.x 工程要么报错要么埋雷。
3. **`SceneTree` 模板有盲区**：`_ready`/`_process` 的真实触发时序在无编辑器模式下与
   正常跑游戏略有差异（07 章实测讲解），不要把模板行为当成引擎行为的完整样本。

上一章：无（本章是第一章） ｜ 下一章：[02 · 第一个程序与项目结构](02-hello.md) ｜ 返回：[README](../README.md)
