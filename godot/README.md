# Godot 开发指南（4.x 实测）

面向**会编程（Python/JS/C 家族背景皆可）、初学 Godot** 的读者：从 GDScript 语言
基础教到节点树、信号、帧循环与 await 异步，最后用回合制战斗小系统收束全部知识点。
**Godot 特色全部独立成章细讲**：节点与场景树（07）、信号（08）、输入与帧循环（09）、
await 与计时器（10）。每章"读讲解 → 跑示例 → 改代码再跑"，讲解用到的代码全部
嵌在正文里，且每章输出都是本机实测结果。

> ⚠️ 网上 Godot 教程半数是 3.x 时代（字符串信号 API、无类型声明、`yield` 协程）。
> 本教程按 **4.3 语法基线编写、4.7.1 实测回归**，第 01 章专门梳理 3.x/4.x 差异。

> ⚠️ headless 验证形态（`extends SceneTree` + `--script`）是教学载体，不是真实
> 项目形态；第 12 章负责切换到编辑器 + `.tscn` 场景工作流。

## 目录结构

```text
godot/
├── README.md       本文件
├── run-all.sh      macOS/Linux 统一验证入口（带看门狗，防挂死）
├── build.ps1       Windows 验证入口（scoop 工具链）
├── docs/           12 章教程（01 → 12 顺序阅读）
└── examples/       10 个示例工程（章号 = 目录号；01/12 为路线章无示例）
    ├── 02_hello/ … 11_mini_rpg/
    └── 每个目录含 project.godot + main.gd（09 另含 player.gd）
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 引擎三件套、3.x/4.x 版本格局、headless 工具链 | — |
| [02 第一个程序](docs/02-hello.md) | `SceneTree` 模板、`project.godot` 解剖、CLI 三参数与退出码陷阱 | `02_hello` |
| [03 变量与基本类型](docs/03-variables.md) | `:=` 推断、类型注解、整除截断、无 f-string 实测 | `03_variables` |
| [04 控制流](docs/04-control.md) | for/while、`match` 模式与守卫、未命中静默行为 | `04_control` |
| [05 函数](docs/05-functions.md) | 默认参数、Callable、lambda 按值捕获实测 | `05_functions` |
| [06 集合](docs/06-collections.md) | 类型化数组、字典三姿势读值、引用语义、无 `items()` | `06_collections` |
| [07 节点与场景树](docs/07-nodes.md) | 组合模型、路径 API、headless 时序坑实测 | `07_nodes` |
| [08 信号](docs/08-signals.md) | 类型化信号、connect/emit、重复连接行为、3.x 对照 | `08_signals` |
| [09 输入与帧循环](docs/09-input-loop.md) | delta 帧率无关、动作抽象、headless 注入按键 | `09_input_loop` |
| [10 await 与计时器](docs/10-await.md) | 协程三法则、计时器三形态、忙等反例、限时窗口惯用法 | `10_timers` |
| [11 实战](docs/11-mini-rpg.md) | 回合制战斗：全知识整合、信号总线、双循环骨架 | `11_mini_rpg` |
| [12 进阶路线](docs/12-roadmap.md) | 编辑器/`.tscn` 工作流、节点清单、学习路线 | — |

## 构建工具链

- macOS（本机实测）：Godot **4.7.1**，`/opt/local/bin/godot`（MacPorts）
- Windows（历史实测）：`G:\scoop\apps\godot\current\godot.console.exe`——路径固化在
  `build.ps1` 顶部，升级工具链只改那一行
- 示例工程声明 `config/features=PackedStringArray("4.3")`：按 4.3 语法编写、4.7.1
  回归通过

## 验证命令

```bash
cd godot
./run-all.sh                 # 全部 10 个示例（看门狗 30s，检查输出含 ERROR 也判失败）
./run-all.sh 07_nodes        # 单个示例
```

单跑某个示例（每章标准学法——改完代码立刻看效果）：

```bash
godot --headless --path examples/02_hello --script main.gd
```

Windows：`pwsh -File build.ps1 -All` / `-Project 07_nodes` / `-Clean`。

## 相关教程

同类引擎/交互开发：[renpy](../renpy/README.md)（视觉小说）、[flutter](../flutter/README.md)
（应用）、[sdl2](../sdl2/README.md)（底层多媒体）；语言基础可对照
[python 风格的 zig](../zig/README.md) 与 [rust](../rust/README.md)（GDExtension 热路径）。
