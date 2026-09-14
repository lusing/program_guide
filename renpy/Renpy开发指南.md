# Ren'Py 开发指南

## 1. 什么是 Ren'Py

Ren'Py 是一套专注于视觉小说与叙事型游戏开发的引擎。它的核心优势是：

- 脚本语法直观，适合文本驱动的故事开发
- 对视觉小说、分支剧情和选择式叙事非常友好
- 与 Python 兼容，扩展逻辑十分灵活
- 适合独立游戏、叙事实验和教学项目

本教程将围绕以下主题展开：

- 工程结构与脚本入口
- 角色、对话和标签
- 变量、分支和菜单
- 状态管理和持久化
- 进阶篇：HUD、跳转流程与复杂游戏结构

---

## 2. 本地工具链

本机安装路径：

- Ren'Py：`G:\scoop\apps\renpy\current\renpy.exe`

命令行验证方式：

```powershell
& 'G:\scoop\apps\renpy\current\renpy.exe' G:\code\guide\renpy\examples\01_hello compile
```

这种方式适合在无图形界面的环境中验证脚本是否能编译成功，便于本地学习和自动化检查。

---

## 3. 最小 Ren'Py 项目结构

最小工程通常是：

```text
project/
├── game/
│   └── script.rpy
├── options.rpy
└── gui.rpy
```

其中：

- `game/script.rpy`：主剧情脚本
- `options.rpy`：可选全局配置
- `gui.rpy`：自定义界面或样式配置

最小脚本：

```renpy
label start:
    "Hello, Ren'Py!"
    return
```

这种结构适合起步和快速验证。

---

## 4. 第一个示例：Hello, Ren'Py

```renpy
label start:
    "Hello, Ren'Py!"
    "这是第一个 Ren'Py 示例。"
    return
```

关键点：

- `label start`：入口标签
- 文本行会被显示为对话或旁白
- `return`：结束当前剧情流程

---

## 5. 角色与对话

Ren'Py 中最常见的写法是先定义角色：

```renpy
define e = Character("Eileen")

label start:
    e "你好，我是 Eileen。"
    e "欢迎来到 Ren'Py 的世界。"
    return
```

角色系统是视觉小说开发的基础：

- 角色名称显示在对话框中
- 更容易控制不同说话风格
- 有利于剧情更清晰、角色差异更明显

---

## 6. 变量与状态

Ren'Py 支持 Python 语法，因此变量非常容易使用：

```renpy
define e = Character("Eileen")

default trust = 0

label start:
    e "我们先做一个小决定。"
    $ trust += 1
    e "你的信任值增加到了 [trust]。"
    return
```

说明：

- `default`：定义默认值
- `$`：执行一段 Python 代码
- `[trust]`：文本插值，显示变量值

---

## 7. 分支与菜单

Ren'Py 强项在于选择分支：

```renpy
define e = Character("Eileen")

label start:
    e "你要继续前进，还是停下观察？"
    menu:
        "继续前进":
            e "你选择了勇敢前行。"
        "停下观察":
            e "你决定谨慎观察。"
    return
```

这里 `menu` 能直接表达“玩家决策 -> 分支剧情”的结构，适合故事游戏的核心设计。

---

## 8. 标签与跳转

标签用于组织故事：

```renpy
define e = Character("Eileen")

label start:
    e "故事开始。"
    jump forest

label forest:
    e "你来到了一片森林。"
    return
```

关键概念：

- `label start`：入口标签
- `jump`：跳转到另一个标签
- `call`：调用标签并在结束后返回

---

## 9. 选择型剧情与状态保存

一个更实用的写法是把选择保存到变量中：

```renpy
define e = Character("Eileen")

default route = "normal"

label start:
    menu:
        "选择勇敢路线":
            $ route = "brave"
        "选择谨慎路线":
            $ route = "careful"
    e "你选择了 [route] 路线。"
    return
```

这里的分支结果可继续用于：

- 后续对话差异
- 裁判/结局判断
- NPC 对应反应
- 分支路线记录

---

## 10. 场景结构设计

一个稍大一些的 Ren'Py 项目，常见结构是：

```text
project/
├── game/
│   ├── script.rpy
│   ├── chapter1.rpy
│   ├── chapter2.rpy
│   ├── characters.rpy
│   └── ui.rpy
├── images/
├── audio/
├── saves/
└── options.rpy
```

通常会把内容拆分为：

- `characters.rpy`：角色定义
- `chapter1.rpy`：第一章剧情
- `chapter2.rpy`：第二章剧情
- `ui.rpy`：界面/屏幕配置
- `script.rpy`：入口与全局标签

拆分结构让项目更容易维护和扩展。

---

## 11. 真正的视觉小说项目结构篇

如果目标是做一个真正的视觉小说项目，而不仅仅是几个脚本片段，那么推荐把项目拆为“入口脚本 + 角色定义 + 分章剧情 + 界面配置”四层结构。

```text
project/
├── game/
│   ├── script.rpy
│   ├── characters.rpy
│   ├── chapter1.rpy
│   ├── chapter2.rpy
│   ├── choices.rpy
│   ├── gui.rpy
│   └── persistence.rpy
├── audio/
├── images/
├── tl/
├── saves/
├── options.rpy
├── screens.rpy
└── gui.rpy
```

其中：

- `script.rpy`：项目入口、全局变量和流程总入口
- `characters.rpy`：定义所有角色和名称
- `chapter1.rpy`、`chapter2.rpy`：分章节剧情内容
- `choices.rpy`：分支逻辑和结局判断
- `gui.rpy`：界面颜色、字体和布局设定
- `persistence.rpy`：存档与持久化状态

典型结构示例：

```renpy
# script.rpy

default player_name = "玩家"
default affection = 0
default route = "none"

label start:
    call chapter_one
    return
```

```renpy
# characters.rpy

define e = Character("Eileen")
define m = Character("梅尔")
```

```renpy
# chapter1.rpy

label chapter_one:
    e "你醒来时，窗外的雨还在落下。"
    menu:
        "继续前进":
            $ route = "forward"
            $ affection += 1
        "停下观察":
            $ route = "observe"
            $ affection += 2

    e "你选择了 [route] 路线。"
    return
```

```renpy
# gui.rpy

define gui.text_size = 32
```

这种结构有几个明显优势：

- 新人能更快定位剧情和角色定义
- 分支和结局逻辑更容易维护
- UI 和脚本职责分离，后续扩展更清晰
- 项目能从简单 demo 逐步升级为完整游戏

在真实项目中，通常还会继续分出：

- `save.rpy`：保存/加载逻辑
- `transforms.rpy`：动画和位置变换
- `inventory.rpy`：道具系统
- `ending.rpy`：结局判定与不同路线文本

这就是从“教程示例”升级为“工程化视觉小说项目”的关键步骤。

---

## 12. 进阶篇：自定义屏幕（screen）

在 Ren'Py 中，`screen` 可以给游戏添加状态栏、对话框、菜单、快捷栏、全局 HUD 等内容。

下面是一个最小状态栏示例：

```renpy
define e = Character("Eileen")

default health = 75

default chapter_name = "第一章"

screen status():
    zorder 100
    frame:
        xalign 0.02
        yalign 0.02
        vbox:
            text "生命值: [health]"
            text "章节: [chapter_name]"

label start:
    show screen status
    e "现在显示状态栏。"
    $ health = 90
    $ chapter_name = "第二章"
    e "你的生命值提升到了 [health]。"
    return
```

这种方式适合：

- 显示血量、体力、状态值
- 展示当前章节和目标
- 给玩家提供实时反馈

---

## 12. 进阶篇：持久化数据（persistent）

`persistent` 可用于跨存档、跨回合保留数据，例如：

- 最好分数
- 已解锁路线
- 角色好感度
- 已查看过的剧情节点

示例：

```renpy
init python:
    if not hasattr(persistent, "best_score"):
        persistent.best_score = 0

label start:
    $ score = 120
    $ persistent.best_score = max(persistent.best_score, score)
    "最佳分数已更新为 [persistent.best_score]。"
    return
```

这个机制特别适合：

- 视觉小说的重复游玩
- 分支剧情状态追踪
- 角色感情值和路线推进

---

## 13. 进阶篇：复杂分支与路线控制

当项目逐渐变大时，通常需要把路线抽象成变量：

```renpy
define e = Character("Eileen")

default route = "normal"

label start:
    menu:
        "选择勇敢路线":
            $ route = "brave"
        "选择谨慎路线":
            $ route = "careful"

    if route == "brave":
        jump brave_path
    else:
        jump cautious_path

label brave_path:
    e "你走上了勇敢路线。"
    return

label cautious_path:
    e "你走上了谨慎路线。"
    return
```

这样有几个好处：

- 后续剧情可以共享状态
- 路线判断更清晰
- 更容易做多结局故事

---

## 14. 进阶篇：菜单联动与玩家选择反馈

Ren'Py 的菜单可以与变量、状态和图形界面配合，形成更成熟的交互体验：

```renpy
define e = Character("Eileen")

default mood = "normal"

label start:
    menu:
        "微笑":
            $ mood = "happy"
        "沉默":
            $ mood = "quiet"
        "愤怒":
            $ mood = "angry"

    if mood == "happy":
        e "你的情绪很稳定，大家都放松了下来。"
    elif mood == "quiet":
        e "你沉默了一会儿，周围的气氛慢慢转变。"
    else:
        e "你的情绪愈发强烈，事情开始失控。"
    return
```

这种模式在剧情设计中非常常见：

- 角色表情状态
- 互动反馈
- 事件影响
- 分支情绪变化

---

## 15. 进阶篇：本仓库中的高级示例

本目录包含的进阶示例：

- `06_advanced_systems`：展示 `screen`、状态变量和 `persistent` 数据管理

示例脚本使用了：

- `screen status()`：显示实时 HUD
- `default`：保存当前变量状态
- `persistent.best_score`：保留跨场景数据
- `menu`：模拟剧情决策
- `jump` / `return`：控制流程

这几项能力是 Ren'Py 从“入门脚本”走向“真实叙事游戏”的关键步骤。

---

## 16. 实战建议

如果你准备继续开发更完整的 Ren'Py 游戏，可以按下面顺序推进：

1. 建立统一的故事入口：`label start`
2. 拆分角色定义与故事脚本
3. 使用 `screen` 构建 HUD 和菜单界面
4. 用 `persistent` 管理多结局和回放状态
5. 设计分支逻辑，确保每个路线都有明确输出
6. 最后补充音频、图片和交互优化
7. 对工程进一步拆分为目录化视觉小说结构，如 `characters`、`chapters`、`ui`、`saves`

---

## 17. 结论

Ren'Py 的学习曲线很平缓，但它的表现力非常强：

- 对视觉小说工程友好
- 适合剧情设计和分支推演
- 变量机制可直接驱动故事状态
- `screen` 和 `persistent` 让项目扩展性更强

如果你已经掌握了 `label`、`menu` 和 `variable`，那么你已经具备建立完整叙事游戏的核心能力。后续可以继续扩展：

- 自定义 UI
- 音乐与背景
- 多结局设计
- 存档管理
- 图片和立绘

在这一点上，Ren'Py 是一个非常值得继续深入的引擎。

---

## 18. 真实项目延伸篇：多结局 / 存档 / 背景 / 音频 / 进程分层

如果你要把一份 Ren'Py 教程示例升级成一个真正可扩展的视觉小说项目，通常还需要处理以下几类工程问题：

- 多结局设计：不同路线产出不同结局文本
- 存档与回读：保存剧情状态、玩家选择、好感度、章节进度
- 背景和音频：`scene`、`play music`、`stop music` 等管理方式
- 资产分层：把角色、章节、音乐、UI 和结局分离为独立脚本文件
- 进程管理：让 `chapter`、`route`、`score`、`persistent` 共同驱动游戏状态

下面是一个更真实工程中的结构示例：

```text
project/
├── game/
│   ├── script.rpy
│   ├── characters.rpy
│   ├── chapter1.rpy
│   ├── chapter2.rpy
│   ├── endings.rpy
│   ├── persistent_state.rpy
│   ├── screens.rpy
│   └── sound.rpy
├── images/
│   ├── bg/
│   ├── chars/
│   └── ui/
├── audio/
│   ├── bgm/
│   └── sfx/
├── saves/
├── options.rpy
└── gui.rpy
```

对应的脚本设计思路如下：

```renpy
# script.rpy

default score = 0
default route = "neutral"
default ending = "none"

label start:
    call chapter_one
    call determine_ending
    return
```

```renpy
# endings.rpy

label determine_ending:
    if score >= 10 and route == "brave":
        $ ending = "happy_end"
    elif route == "careful":
        $ ending = "mystery_end"
    else:
        $ ending = "bad_end"

    e "你达成了 [ending]。"
    return
```

```renpy
# persistent_state.rpy

init python:
    if not hasattr(persistent, "seen_endings"):
        persistent.seen_endings = []

label record_ending:
    if ending not in persistent.seen_endings:
        $ persistent.seen_endings.append(ending)
    return
```

```renpy
# sound.rpy

label play_background_music:
    play music "audio/bgm/ambient.ogg" loop
    return
```

这些设计让视觉小说从“单页脚本”升级成“可维护的互动叙事工程”。

---

## 19. 真实项目延伸篇：立绘、场景切换、BGM 与菜单 UI

真正的视觉小说项目往往还需要处理以下几类内容：

- 背景图切换：`scene` 和 `show` 管理环境变化
- 立绘/角色表情：使用不同角色图像表现状态变化
- BGM / 音效：`play music`、`play sound` 与 `stop music`
- 菜单 UI：`screen` 自定义主菜单、暂停菜单和状态栏
- 章节切换：将故事分解成明确的章节逻辑

一个更真实的工程结构通常会扩展成：

```text
project/
├── game/
│   ├── script.rpy
│   ├── characters.rpy
│   ├── chapter1.rpy
│   ├── chapter2.rpy
│   ├── screens.rpy
│   ├── music.rpy
│   └── ui.rpy
├── images/
│   ├── bg/
│   ├── chars/
│   └── ui/
├── audio/
│   ├── bgm/
│   └── sfx/
├── saves/
├── options.rpy
└── gui.rpy
```

典型脚本示例：

```renpy
define e = Character("Eileen")

default chapter = 1

screen status_bar():
    frame:
        xalign 0.02
        yalign 0.02
        vbox:
            text "章节：[chapter]"
            text "状态：待命"

label start:
    show screen status_bar
    scene black
    play music "audio/bgm/ambient.ogg" loop
    e "夜色降临，风声穿过窗台。"
    $ chapter = 2
    e "舞台切换完成，音乐与场景都已经更新。"
    stop music
    return
```

这里体现的核心思想是：

- `scene` 用于切换背景
- `show`/`hide` 管理角色和界面层
- `play music` 用于强调情绪与氛围
- `screen` 用于构建 HUD 和菜单
- 分章节管理，让项目更易维护

这种设计是从“单文件剧情脚本”进化到“真实游戏工程”的关键一步。

---

## 20. 角色立绘与情绪系统

视觉小说在走向真实项目时，角色往往不再只是文本，而是会伴随立绘与情绪变化。一个常见的结构是：

- 角色定义：名称、立绘、表情状态
- 情绪状态：`happy`、`angry`、`sad`、`quiet`
- 表达切换：根据分支变化切换角色图像
- 叙事关联：不同情绪对应不同对白和场景反应

例如：

```renpy
define e = Character("Eileen")

default emotion = "neutral"

label start:
    e "你看着我，想知道我现在的情绪。"
    menu:
        "微笑":
            $ emotion = "happy"
        "沉默":
            $ emotion = "quiet"
        "生气":
            $ emotion = "angry"

    if emotion == "happy":
        e "我现在很开心。"
    elif emotion == "quiet":
        e "我今天不想说太多。"
    else:
        e "我有些生气，你最好注意一点。"
    return
```

更进一步，项目中通常会分成：

```text
project/
├── game/
│   ├── characters.rpy
│   ├── emotions.rpy
│   ├── script.rpy
│   └── chapter1.rpy
├── images/
│   ├── chars/
│   └── bg/
└── gui.rpy
```

其中：

- `characters.rpy`：角色定义
- `emotions.rpy`：情绪状态管理与图像映射
- `chapter1.rpy`：剧情章节
- `script.rpy`：总入口和全局状态

这种结构让角色表达与剧情逻辑分离，从而更容易做复杂叙事和状态调试。

---

## 21. 主菜单 / 暂停菜单 / 选项菜单

一个成熟的视觉小说项目，通常需要具备基础菜单系统，而不仅只是故事脚本。常见的菜单包括：

- 主菜单：开始游戏、读取存档、设置
- 暂停菜单：继续、存档、退出
- 选项菜单：音量、文本速度、全屏等

Ren'Py 中，菜单通常由 `screen` 定义：

```renpy
screen main_menu():
    tag menu
    modal True

    add "gui/menu.png"

    vbox:
        xalign 0.5
        yalign 0.5
        spacing 20

        textbutton "开始游戏" action Start()
        textbutton "读取存档" action ShowMenu("load")
        textbutton "设置" action ShowMenu("preferences")
        textbutton "退出" action Quit(confirm=True)
```

暂停菜单：

```renpy
screen pause_menu():
    tag menu
    modal True

    vbox:
        xalign 0.5
        yalign 0.5
        spacing 20

        textbutton "继续" action Hide("pause_menu")
        textbutton "存档" action ShowMenu("save")
        textbutton "退出" action MainMenu()
```

选项菜单：

```renpy
screen preferences():
    tag menu

    vbox:
        xalign 0.5
        yalign 0.5
        spacing 20

        text "音量"
        bar value Preference("music volume")
        text "文本速度"
        bar value Preference("text speed")
```

这些菜单能让项目看起来更像一款正式的视觉小说或交互故事游戏，而不是纯脚本动画。

---

## 22. 本仓库中可用的命令

```powershell
cd G:\code\guide\renpy
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -Project 11_main_menu_and_pause
```

清理输出：

```powershell
.\build.ps1 -Clean
```

这样既满足本仓库的统一标准，也能确保每个 Ren'Py 示例都经过真实编译验证。
