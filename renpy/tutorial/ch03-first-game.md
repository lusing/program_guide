# 第 3 章 第一个游戏：对话与角色

（配套示例：`examples/01_first_game`）

## 3.1 最小可运行游戏

Ren'Py 的一切从 `label start` 开始。玩家在主菜单点"开始游戏"（Start），引擎就把控制权交给这个名字固定为 `start` 的标签：

```renpy
label start:

    "Hi there! How was class?"

    "Good..."

    "I can't bring myself to admit that it all went in one ear and out the other."

    return
```

逐条讲解：

- `label start:` 定义一个**标签（label）**，即脚本中的跳转锚点。`start` 是特殊名字：主菜单的 Start 动作从这里执行。
- 下面四行缩进的语句构成一个**块**。Ren'Py 用缩进划分块（惯例 4 空格），同一块内缩进必须一致——这与 Python 相同。
- **单独一个字符串的语句是 say（对话/旁白）语句**：显示这段文字，然后等待玩家点击才继续。没有角色名时，它以"旁白"身份出现在对话框里。
- `return` 结束当前脚本流程。当没有更外层的 `call` 时，`return` 意味着**游戏结束**，引擎回到主菜单。

这个游戏没有选择分支，属于"动态小说"（kinetic novel）。官方 quickstart 明确指出：掌握到这里，你已经能发布一部完整的动态小说了。

## 3.2 对话的四种写法与转义

say 语句共有四种形式（官方文档 dialogue 页原文）：

```renpy
"This is narration."
"Eileen" "This is dialogue, with an explicit character name."
e "This is dialogue, using a character object instead."
"Bam!!" with vpunch
```

- 第一行：单字符串 = **旁白**。
- 第二行：两个字符串 = **显式角色对话**，第一个字符串直接充当说话者名字。适合一次性角色。
- 第三行：**Character 对象** + 对话文本。`e` 是一个先前定义的角色变量（下一节）。这是正式项目的标准写法。
- 第四行：对话后跟 `with` 子句，在显示这句话的同时播放 `vpunch`（画面纵向震动）转场，用于强调。

字符串中有特殊字符时需要转义。包含双引号的对话：

```renpy
"Sylvie" "Did you ever hear Lincon's famous saying, \"The problem with Internet quotations is that many of them are not genuine.\""
```

其他常见转义：`%%` 或 `\%` 显示百分号；`[[` 显示方括号 `[`（方括号默认用于变量插值）；`{{` 显示花括号（花括号默认用于文本标签）；`\\` 显示反斜杠。官方示例：

```renpy
"I walked past a sign saying, \"Let's give it 100%%!\""
```

## 3.3 Character 对象

给角色起名、上色、加口癖，都通过 `Character` 对象完成。用 `define` 语句定义（`define` 在初始化阶段求值，详见 16.1）：

```renpy
define s = Character('Sylvie', color="#c8ffc8")
define m = Character('Me', color="#c8c8ff")
```

- 第一个参数是**显示给玩家看的名字**；`color` 是名字的颜色（网页色格式 `#rrggbb`）。
- 定义后，剧本里用 `s "..."`、`m "..."` 说话，对话框中会显示彩色名字。

Character 的参数非常多，最常用的几组：

**前缀后缀与动态名字：**

```renpy
# A character that has its dialogue enclosed in parenthesis.
define e = Character("Eileen", what_prefix='(', what_suffix=')')

# A character that pulls its name from a variable.
define p = Character("player_name", dynamic=True)
```

`what_prefix`/`what_suffix` 自动包裹对话正文（上面这个角色说的每句话都会带括号）；`dynamic=True` 让名字每次显示时从变量求值——配合第 19 章的玩家取名，对话框会显示玩家输入的名字。

**旁白角色与名字省略：** 引擎的旁白本身就是名为 `narrator` 的 Character，可以重定义它来统一旁白风格；任何 `name=None` 的角色说话时都不显示名字。

**继承模板（kind）：** 以另一个角色为模板派生新角色：

```renpy
define nvle = Character(kind=nvl, color="#c8c8cff")
```

（`kind=nvl` 表示以引擎内建的 NVL 角色 `nvl` 为模板，用于第 8 章的 NVL 模式。）此外 `define character.e = Character("Eileen")` 这种**命名 store 写法**在 8.x 中可用，角色会注册到 `character.` 命名空间，便于翻译系统定位角色名。

**图像关联（image）：** `define e = Character("Eileen", image="eileen")` 后，say 语句可以直接附加图像属性（如 `e happy "..."` 自动切换立绘表情），这是第 4 章与第 12 章立绘系统的枢纽。

完整的参数清单（`who_prefix`/`who_suffix`、`ctc` 系列、`voice_tag`、`condition`、`interact`、`callback`、`screen` 等）见官方 *Defining Character Objects* 一节；本指南在用到时会就地讲解。

## 3.4 完整的第一个游戏（示例 01）

把上述内容组合起来就是示例 `01_first_game` 的 `script.rpy`，与 quickstart 中"The Question"的开场结构一致：

```renpy
# 角色定义：define 在游戏启动时执行一次。
define s = Character('Sylvie', color="#c8ffc8")
define m = Character('Me', color="#c8c8ff")

# 剧情开关变量：default 声明"默认值"，会随存档保存（第 16 章详述）。
default book = False

label start:

    "It's only when I hear the sounds coming from the classroom next door that I realize I've been daydreaming again."

    play music "<silence 2.0>" fadeout 1.0 fadein 1.0

    scene bg lecturehall with fade

    "I'm running late for class, as usual."

    s "Hi there! How was class?"

    m "Good..."

    menu:

        "It's a videogame.":
            jump game

        "It's an interactive book.":
            jump book

label game:

    m "It's a kind of videogame you can play on your computer or a console."

    jump marry

label book:

    $ book = True

    m "It's like an interactive book that you can read on a computer or a console."

    jump marry

label marry:

    if book:

        "Our first game is based on one of Sylvie's ideas, but afterwards I get to come up with stories of my own, too."

    else:

        "Sylvie helped with the script on our first video game."

    ".:. Good Ending."

    return
```

这一段覆盖了本指南前半部分的全部主干语句，先给读者一个整体印象，逐个机制在后续章节展开：

- `default book = False`：声明剧情旗帜变量。用 `default` 而不是 `define`，因为它是要**随存档变化**的状态（16.1 详解二者区别）。
- `play music ...`：播放音频（示例用 `<silence 2.0>` 静音片段代替真实音频文件，因此示例工程无需素材即可运行；第 9 章讲解音频语句）。
- `scene bg lecturehall with fade`：清空舞台并显示背景，伴随淡入转场（第 4 章）。
- `menu:`：显示选项菜单，每个 `"选项":` 带一个缩进块（第 6 章）。
- `jump game`：跳转到对应标签；`$ book = True`：执行一行 Python 赋值。
- `if book:`：Ren'Py 脚本级条件语句（第 6 章）。
- `".:. Good Ending."`：官方 quickstart 的惯例——结束前显示结局名，然后 `return`。

---

上一章：[02 安装、启动器与命令行](ch02-install-launcher-cli.md) · 下一章：[04 图像与舞台](ch04-images-and-stage.md)
