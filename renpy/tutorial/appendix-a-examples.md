# 附录 A 示例集总览与构建方法

> [← 第 24 章 构建与发布](ch24-build-and-distribution.md) ｜ [目录](index.md) ｜ [返回教程首页 →](index.md)

本仓库 `renpy/examples/` 下的示例工程与本书章节一一对应，全部**不依赖任何图片/音频素材**（用引擎内建的 `Solid`、`Text`、`<silence>` 等代替），因此 clone 后即可直接编译运行。

## A.1 示例一览

| 示例 | 对应章节 | 主题 |
| --- | --- | --- |
| `01_first_game` | 第 3 章 | 第一个游戏：对话与角色 |
| `02_images_and_stage` | 第 4 章 | 图像与舞台 |
| `03_labels_and_flow` | 第 5 章 | 标签与控制流 |
| `04_menus_and_variables` | 第 6 章 | 菜单、变量与分支 |
| `05_text_and_dialogue` | 第 7 章 | 对话进阶与文本 |
| `06_nvl_mode` | 第 8 章 | NVL 模式 |
| `07_audio_and_video` | 第 9 章 | 音频与视频 |
| `08_atl_and_transform` | 第 10 章 | ATL 与 transform |
| `09_transitions` | 第 11 章 | 转场 |
| `10_layeredimage` | 第 12 章 | Layered Images 立绘系统 |
| `11_screens` | 第 13 章 | Screen 语言基础 |
| `12_actions` | 第 14 章 | Screen 动作与数据绑定 |
| `13_special_screens` | 第 15 章 | 特殊 screen、菜单定制与样式 |
| `14_save_rollback` | 第 16 章 | 变量、存档与回滚 |
| `15_persistent` | 第 17 章 | 持久化数据 |
| `16_full_project` | 第 18 章 | Python 语句与引擎 API（一个较完整的工程骨架） |
| `17_input_history` | 第 19 章 | 玩家输入、对话历史与通知 |
| `18_extras` | 第 20 章 | 画廊、音乐室与剧情回放 |
| `19_lifecycle` | 第 21 章 | 开场动画与游戏生命周期 |

> 每个示例目录的内部结构都是标准的 Ren'Py 工程，且刻意保持到最小：

```
NN_example_name/
└── game/
    └── script.rpy      ← 该章讲解的完整脚本
```

`16_full_project` 会额外拆出几个文件（`characters.rpy`、`options.rpy` 等），用来演示多文件工程的拆分方式——多文件工程与单文件工程在引擎眼里没有区别，`game/` 下所有 `.rpy` 都会在启动时合并编译。

## A.2 最小工程为什么能跑起来

只放一个 `game/script.rpy` 就能 `compile`、`lint`、`run`，这可能会让刚接触 Ren'Py 的读者意外——毕竟官方模板里还有 `gui.rpy`、`screens.rpy`、`options.rpy`。原因是 Ren'Py 把这些文件里可以被省略的部分都做成了**可缺省的**，缺什么就用引擎内置的默认行为顶替：

- **缺 `screens.rpy`**：完全不定义任何 screen 时，游戏**不会出现主菜单**。`renpy/common/00start.rpy` 里的 `_main_menu_screen`（L327）依次检查三个特殊 label——`main_menu`、`main_menu_screen`、`_library_main_menu`——只要一个都找不到，它就执行 `return`；而它的调用者 `_invoke_main_menu`（L294）在 `renpy.call_in_new_context("_main_menu")` 返回之后会立刻 `renpy.jump("start")`（L307）。于是引擎**直接跳进 `start` label，游戏开演**。这正好方便写示例：不用每次先去点一下"开始游戏"。
  - 顺带说明：引擎内置的那套"经典"主菜单（`_library_main_menu`，定义在 `renpy/common/_compat/mainmenu.rpym`）**只在兼容模式下才会被载入**——载入它的是 `layout.compat()`（`00layout.rpy` L303），而 `layout.compat()` 只在 `script_version <= (6, 5, 0)` 时被调用（`00compat.rpy` L344）。现代工程没有 `script_version.txt`，`config.script_version` 是 `None`，`_set_script_version(None)` 开头就 `return`（L39），所以这条路根本不会走。**别指望现代工程里有内置主菜单兜底。**
- **缺 `gui.rpy`**：示例不依赖它。需要说明的是，`gui.init(width, height)`（定义在 `renpy/common/00gui.rpy`）**并不定义任何 screen**，它只做四件事：设置 `config.screen_width`/`config.screen_height`、据此计算 `config.perspective`（3D 透视）、调用 `layout.defaults()` 把一批样式变量灌进 `style` 系统、并把 `_preferences.virtual_size` 设为该分辨率。它是"设定尺寸 + 应用 GUI 主题"的入口，screen 的实际定义始终来自 `screens.rpy`。
  - 这一点还有第二个后果：`layout.defaults()`（`00layout.rpy` L109）正是"把 `screen` 接上引擎的入口 label"的地方——它在 `renpy.has_screen("main_menu")` 时载入 `_layout/screen_main_menu` 模块，而该模块提供 `label main_menu_screen`（见 `renpy/common/_layout/screen_main_menu.rpym` L26）。没有 `gui.rpy`（也没有主题）时 `layout.defaults()` 不会被调用，所以 `main_menu_screen`、以及 `save`/`load`/`preferences` 等模板界面**统统不存在**。第 13 章及以后的示例如果需要这些界面，会在 `script.rpy` 里自行定义（例如自己写 `label main_menu` + `screen main_menu`，用 `Start()`/`Quit()` 动作），而不是假设引擎会提供。
- **缺 `options.rpy`**：就用引擎默认的 `config.name`（取自目录名）、默认存档目录、默认主题。

这套缺省机制正是示例可以"零素材、零模板文件"的原因：**你只需要写真正要讲的那段剧本**。反过来说，当你用启动器创建正式项目时，它给你的 `gui.rpy`/`screens.rpy`/`options.rpy` 就是把上面这些默认行为**替换成可自定义的实现**——`gui.rpy` 里的 `gui.init()` 会触发 `layout.defaults()`，把模板里定义好的 `screen main_menu`/`screen save`/`screen preferences` 接上引擎的入口 label。这正是第 13 章讲屏幕定制时的起点。

## A.3 编译与验证

```bash
SDK=/path/to/renpy-8.5.x-sdk

# 1) 编译（等价于启动器的 Force Recompile）
"$SDK/renpy.sh" examples/01_first_game compile

# 2) 静态检查（有错时退出码非 0）
"$SDK/renpy.sh" examples/01_first_game lint --error-code

# 3) 运行
"$SDK/renpy.sh" examples/01_first_game run

# 4) （可选）跑自动化测试
"$SDK/renpy.sh" examples/01_first_game test --hide-execution all
```

`examples/` 下每个工程都应当能通过第 1、2 步；这正是本仓库的验收标准。

## A.4 批量脚本

`renpy/build.sh`（Linux/macOS）与 `renpy/build.ps1`（Windows）是本仓库自带的便捷脚本，作用是把上面的命令对**全部示例**循环执行一遍：

```bash
# build.sh 的等价逻辑（伪代码）
for proj in examples/*/; do
    "$SDK/renpy.sh" "$proj" compile || exit 1
    "$SDK/renpy.sh" "$proj" lint --error-code || exit 1
done
```

> 再次说明（见 24.13.4）：**这两个脚本是本书自带的工具，不是 Ren'Py 官方文档中的东西**。官方对构建的标准入口只有启动器 Build 页与 `renpy.sh launcher distribute`。

---

> [← 第 24 章 构建与发布](ch24-build-and-distribution.md) ｜ [目录](index.md) ｜ [返回教程首页 →](index.md)
