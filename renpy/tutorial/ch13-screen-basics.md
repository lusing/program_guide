# 第 13 章 Screen 语言基础

> [← 第 12 章 Layered Images 立绘系统](ch12-layered-images.md) ｜ [目录](index.md) ｜ [第 14 章 Screen 动作与数据绑定 →](ch14-screen-actions.md)

## 13.1 第一个 screen：一块会自己更新的面板

先看一个最小的 screen 定义：

```renpy
screen stats_panel():
    frame:
        align (0.02, 0.05)
        vbox:
            spacing 6
            text "姓名：苏晓"
            text "体力：[hp] / [hp_max]"
```

逐行拆开看：

- `screen stats_panel():` 声明一个名为 `stats_panel` 的屏幕。名字后面必须带一对括号——因为 screen 本质上像一个可调用的函数；将来要传参数时，参数就写在这对括号里。screen 体内是缩进块。
- `frame:` 是一个带背景的面板容器（默认模板里用 `gui/frame.png` 做背景）。容器后面跟冒号，其子元素缩进排列在它下面。
- `align (0.02, 0.05)` 是定位属性：水平方向 2% 处、垂直方向 5% 处。定位属性几乎对每个显示物都有效，是 screen 语言的通用语言。
- `vbox:` 纵向排列容器（vertical box），`spacing 6` 表示子元素之间的间距是 6 像素。
- 两条 `text` 各显示一行文字。注意 `[hp]` 和 `[hp_max]`——screen 的文本同样支持第 7 章讲过的插值规则，取的是全局变量的当前值。

定义只是"图纸"，要把它显示出来需要在剧本中调用：

```renpy
label start:
    default hp = 12
    default hp_max = 20

    show screen stats_panel
    "你独自站在宿舍楼下，秋天的风把衣角吹得鼓起来。"
    hide screen stats_panel
    "面板已经收起。"
    return
```

`show screen stats_panel` 把面板"挂"到界面上，然后剧本继续往下走——**show screen 不会打断对话**，玩家照常点击推进。`hide screen stats_panel` 则把它摘下来。顺带一提，`default hp = 12` 写在 label 里也是合法的，它保证变量在进入剧情时被赋值（第 6 章讲过 `default` 的补值语义）。

`show screen` 后面不带参数时括号可以省略；一旦要传参数，括号就必须写：`show screen stats_panel(compact=True)`。

现在做一个小实验，体会"声明式"三个字的分量：

```renpy
label start:
    show screen stats_panel
    "你独自站在宿舍楼下。"
    $ hp -= 4
    "一阵冷风灌进领口，你打了个寒颤。"
    hide screen stats_panel
    return
```

`$ hp -= 4` 执行完，面板上的文字会自动变成"体力：8 / 20"——没有任何一行代码去"刷新"它。原因正是开篇说的：screen 描述的是"任意时刻界面应有的样子"，`hp` 变了，重算出来的界面自然就变了。习惯命令式 GUI 编程的读者要特别留意这一点：在 Ren'Py 里，你从不主动刷新界面，只改数据。

## 13.2 call screen：让界面成为一次"提问"

`show screen` 是"挂一块面板，继续剧情"；`call screen` 则是"弹出界面，停下来等玩家操作，拿到结果再继续"。它会开启一次新的交互，直到界面里的某个按钮执行 `Return` 动作交回一个值：

```renpy
screen yes_no(question):
    modal True

    frame:
        align (0.5, 0.5)
        vbox:
            spacing 16
            text question
            hbox:
                spacing 24
                textbutton "是" action Return(True)
                textbutton "否" action Return(False)

label start:
    call screen yes_no("要直接进入第一章吗？")
    if _return:
        jump chapter_one
    jump prologue
```

这段代码里有几个新面孔：

- `screen yes_no(question):` 这次 screen 带参数了。参数就是普通变量，在 screen 体里直接使用——`text question` 显示的就是调用时传进来的字符串。
- `modal True` 是 screen 语句级的修饰参数：这个屏幕显示期间，**它下层的所有界面都收不到鼠标和键盘输入**。做确认框、模态对话框时几乎必写，否则玩家还能点到下层内容。
- `textbutton "是" action Return(True)`：textbutton 是"文字按钮"，`action` 属性指明点击后执行的动作。`Return(True)` 会在点击时结束这次 `call screen` 交互，并把 `True` 交回去。
- `call screen yes_no("...")` 执行期间剧本暂停；返回之后，返回值存放在特殊变量 `_return` 里——这和第 5 章 `call label` 用的 `_return` 是同一套约定。所以紧接着的 `if _return:` 就能根据玩家选择分岔。

顺带一提：第 14 章会介绍 `Confirm` 动作，它用引擎自带的确认框完成同样的事，日常开发里更省事；`renpy.call_screen()` 的函数形式则放在第 18 章与 Python 语句一起讲。

## 13.3 容器与定位：fixed、hbox、vbox、grid、frame

screen 的根默认是一个 `fixed` 容器——它允许子元素互相重叠，各自按自己的定位摆放。在这个基础上，常用容器有：

- `vbox` / `hbox`：纵向 / 横向排列，`spacing` 控制间距；
- `grid 列数 行数`：网格布局，必须提供恰好"列数 × 行数"个子元素，`spacing` 同样有效；
- `fixed`：自由定位，子元素各摆各的；
- `frame`：自带背景的面板，常用 `padding`、`margin` 调整内边距；
- `null`：什么都不画，只占位，比如 `null height 20` 用来撑开一段空白。

定位属性是所有显示物通用的，常用的有：`xpos`/`ypos`（绝对位置，可用像素或 0~1 的比例）、`xanchor`/`yanchor`（锚点）、`xalign`/`yalign`（比例定位的简写）、`align`（两个 align 的合写，如 `align (0.5, 0.5)` 就是正中）、`xoffset`/`yoffset`（相对偏移）、`xfill`/`yfill`（填满父容器）、`xmaximum`/`ymaximum`（最大尺寸）、`xysize`（同时指定宽高）。

下面用 `grid` 做一张 2×2 的角色卡（素材用 `frame` + `text` 顶替，保持免素材原则）：

```renpy
screen character_grid():
    grid 2 2:
        xalign 0.5
        yalign 0.5
        spacing 12

        for name in ["苏晓", "陆嘉", "叶蓝", "老周"]:
            frame:
                xysize (220, 160)
                text "[name]" align (0.5, 0.5)
```

`grid 2 2` 即两列两行；四个 `frame` 被依次填入四个格子。`for` 在 screen 里同样合法（13.7 节细讲），每次循环生成一个格子。每个 `frame` 用 `xysize (220, 160)` 定下尺寸，里面的 `text` 用 `align (0.5, 0.5)` 居中——`frame` 加 `align` 的组合是免做图时最常用的"卡片"手法。

## 13.4 常用显示物一览

除了容器和文本，screen 语言还提供了这些高频显示物：

- `text 表达式`：文本，支持插值与文本标签；
- `image "图片名"` 或 `add 任意显示物`：`add` 更通用，可以放图片、`Solid` 色块、ATL 动画（第 11 章）等任意显示物；
- `textbutton "文字" action ...`：文字按钮；
- `imagebutton`：图片按钮，`idle`/`hover` 分别指定平时与悬停时的显示物；
- `button:` 容器按钮：把任意内容拼成一个可点击的整体；
- `bar` / `vbar` / `slider`：进度条与滑杆，`value` 属性绑定数值；
- `input`：文本输入框；
- `key`：键盘快捷键；
- `timer`：定时器，到点执行动作；
- `null` / `frame` / `hbox` / `vbox` / `grid`：见上一节。

把这些拼在一起看一个例子：

```renpy
screen demo_widgets():
    frame:
        align (0.5, 0.5)
        vbox:
            spacing 10

            text "体力条" size 22

            bar value StaticValue(hp, hp_max) xmaximum 320

            imagebutton:
                idle Solid("#4a6fa5", xysize=(120, 44))
                hover Solid("#7d9fd3", xysize=(120, 44))
                action Return("icon")

            key "K" action Return("keyboard")
            timer 5.0 action Return("timeout")
```

逐个说明：

- `bar value StaticValue(hp, hp_max)`：`bar` 需要 `value` 属性提供一个"数值源"。`StaticValue(当前值, 范围)` 在求值时读取 `hp` 与 `hp_max` 算出比例。括号里是直接传变量值，所以 `hp` 变化时界面照样会更新——因为整个 screen 每次重算都会重新执行 `StaticValue(hp, hp_max)`。
- `imagebutton` 的 `idle` 与 `hover` 接受任意显示物。这里用 `Solid("#4a6fa5", xysize=(120, 44))` 造了两块不同颜色的实心矩形当按钮皮——完全不需要图片素材。
- `key "K" action Return("keyboard")`：按下 K 键等价于点击。
- `timer 5.0 action Return("timeout")`：5 秒后自动执行动作。到点未操作会返回 `"timeout"`，常用于限时选择、自动关弹窗。

如果想让进度条"双向绑定"——变量变条就动，甚至玩家拖动滑杆还能把值写回变量——用 `VariableValue`：

```renpy
bar value VariableValue("hp", hp_max) xmaximum 320
```

`VariableValue` 的第一个参数是**变量名的字符串**。它每次刷新时按名字去全局变量区读取 `hp`；若放在 `slider` 上，玩家拖动时还会把新值写回 `hp`。这是"数据绑定"最直白的形式，第 14 章还会回到数据绑定这个话题。

## 13.5 screen 的参数与屏幕作用域

screen 像 Python 函数一样接受参数，可以带默认值，也可以被别的 screen 调用：

```renpy
screen stat_row(label_text, value, max_value=100):
    hbox:
        spacing 12
        yalign 0.5

        text "[label_text]" xsize 120
        bar value StaticValue(value, max_value) xmaximum 260
        text "[value]/[max_value]"

screen stats_panel():
    vbox:
        spacing 10
        use stat_row("体力", hp, hp_max)
```

`use stat_row("体力", hp, hp_max)` 把 `stat_row` 当组件"调用"了一次。`use` 是 screen 之间的函数调用语法，13.6 节展开。

除参数外，screen 内还可以用 `default` 声明**屏幕作用域**变量：

```renpy
screen door_buttons():
    default tries = 0

    vbox:
        spacing 8
        text "已尝试 [tries] 次"

        textbutton "推门" action SetScreenVariable("tries", tries + 1)
        textbutton "放弃" action Return("give_up")
```

要点有三个：

1. `default tries = 0` 在每次显示这个 screen 时初始化 `tries`（若屏幕作用域中还没有它）。摘下再挂上，`tries` 归零——因为屏幕作用域跟着 screen 的生命周期走。
2. `SetScreenVariable("tries", tries + 1)` 只修改**屏幕作用域**里的变量。对比 `SetVariable("tries", ...)`（第 14 章详述）修改的是**全局**变量。写错对象是最常见的新手 bug：明明点了按钮数字却不涨，多半是 action 和变量的作用域对不上。
3. screen 体里也可以用 `$ tries += 1` 这类语句，它操作的同样是屏幕作用域。

## 13.6 use 与 transclude：把 screen 当组件拼装

`use` 复用 screen；如果被复用的 screen 里有 `transclude`，那么调用方还能"塞"一段自己的内容进去：

```renpy
screen titled_panel(title_text):
    frame:
        vbox:
            spacing 12
            text title_text:
                size 24
                bold True
            transclude

screen shop():
    use titled_panel("商店"):
        textbutton "面包（恢复体力）" action Return("bread")
        textbutton "火把（照明用）" action Return("torch")
```

`use titled_panel("商店"):` 带了冒号，冒号下面的缩进块就是"塞进去的内容"，它会被安放在 `titled_panel` 里 `transclude` 出现的位置。可以理解为"函数调用 + 回调"：标题栏由组件统一提供，具体按钮由调用方现场决定。官方模板的 `game_menu` 正是用这个手法，让存档、读档、设置页共用一套外框（15.7 节会拆解它）。

## 13.7 if 与 for：随数据生长的界面

screen 里的 `if`、`for` 语法与剧本语言相同，但**求值时机完全不同**：剧本的 `if` 在执行到那一行时判断一次；screen 的 `if` 在**每次重算界面时**重新判断。这就是动态界面的来源：

```renpy
screen inventory(items):
    vbox:
        spacing 8

        if items:
            for item in items:
                textbutton item action Return(item)
        else:
            text "（口袋空空）"
```

`items` 是空列表时显示"（口袋空空）"；捡到东西后再显示这个 screen，列表会自动展开成一排按钮。你不需要写"增删按钮"的代码，只需要保证数据正确——界面是数据的投影。

配合 `for` 的还有熟悉的 `range`：`for i in range(1, 10):` 生成九个元素，官方模板的存档页码按钮正是这么写的（15.8 节）。

## 13.8 screen 语句的修饰参数

`screen` 名字后面、括号之后还可以接一串修饰参数，控制这块屏幕在引擎里的"物理属性"：

```renpy
screen hud_overlay():
    layer "screens"
    zorder 50
    tag hud
    predict False

    ...
```

- `tag hud`：标签。同一时刻同 tag 的 screen（或 image）只显示一个——`show screen` 一个同 tag 的新屏幕会自动替换旧的。菜单系统靠 `tag menu` 实现"页面切换"（15.7 节）。
- `modal True`：挡住下层输入（13.2 节已见）。
- `zorder 50`：同层内的叠放次序，数字大的在上。
- `layer "screens"`：指定所属图层。Ren'Py 的图层从下到上大致是 master、transitions、screens、overlay，自定义图层可用 `config.layers` 扩展。
- `sensitive False`：整块界面不接受输入，"冻结"画面用。
- `variant "small"` / `"touch"` / `"pc"`：设备变体。同名 screen 可以定义多份，引擎按运行环境挑合适的（模板的手机版 quick_menu 就是这样，15.1 节末尾提到）。
- `style_prefix "hud"`：给内部所有元素套样式前缀，15.10 节详讲。
- `predict False`：跳过对此 screen 的预渲染预测。巨大的界面（如对话历史）加上它可以避免无谓的性能开销。

## 13.9 综合实战：一张活着的 HUD

把本章知识拼成完整的一段剧本：右上角常驻 HUD 显示体力条与金币，金币增加时数字自动更新，体力不满时出现"扎营"按钮，点完按钮自动消失。

```renpy
define e = Character("艾琳")

default hp = 6
default hp_max = 10
default gold = 30

screen quest_hud():
    tag hud

    frame:
        align (0.98, 0.02)
        vbox:
            spacing 8

            text "体力" size 20
            bar value VariableValue("hp", hp_max) xmaximum 220

            text "金币 [gold]" size 20

            if hp < hp_max:
                textbutton "扎营休息" action SetVariable("hp", hp_max)

label start:
    scene black
    show screen quest_hud
    e "雨还没停。今晚的月亮，比昨晚更远了些。"
    $ gold += 10
    e "（找到 10 枚金币——看看右上角。）"
    e "（点一下「扎营休息」，体力条会自己涨满，然后按钮自己消失。）"
    pause
    hide screen quest_hud
    return
```

逐条对应知识点：`tag hud` 防止重复挂载；`bar value VariableValue(...)` 双向绑定体力；`$ gold += 10` 一执行，"金币 [gold]" 的插值文本自动重算；`if hp < hp_max` 每次刷新重估——点击"扎营休息"触发 `SetVariable("hp", hp_max)`，`hp` 到达上限，`if` 条件变假，按钮从界面上消失。整个流程没有任何一行"手动刷新"或"手动移除按钮"的代码——这就是声明式界面应有的样子。

## 13.10 小结与实践

- screen 是声明式的：描述"应有状态"，引擎负责重算与重绘，永远不要手写刷新；
- `show screen` / `hide screen` 挂载摘除不打断剧情；`call screen` 弹出界面等待交互，结果存入 `_return`；
- 容器：fixed（根，可重叠）、hbox/vbox（线性）、grid（网格）、frame（面板）、null（占位）；
- 参数与 `default` 造就屏幕作用域；`SetScreenVariable` 管作用域内，`SetVariable` 管全局；
- `use` + `transclude` 组件化拼装界面；
- `if` / `for` 每次重算时重新求值，界面随数据自动生长；
- 修饰参数 tag/modal/zorder/layer/sensitive/variant/style_prefix/predict 控制屏幕的工程属性；
- 示例工程 `11_screens` 实现了 13.9 的 HUD 与 13.6 的组件化商店。

---

> [← 第 12 章 Layered Images 立绘系统](ch12-layered-images.md) ｜ [目录](index.md) ｜ [第 14 章 Screen 动作与数据绑定 →](ch14-screen-actions.md)
