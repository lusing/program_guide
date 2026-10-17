# 第 15 章 特殊屏幕与菜单定制

到目前为止，你游戏里的对话窗口、选项列表、确认框，长得都和所有 Ren'Py 游戏一个样——因为它们来自官方模板文件 `screens.rpy`。这一章把这块"公共骨架"拆开给你看：引擎其实留了一排**带保留名的钩子屏幕**，你在自己项目里定义同名屏幕，就能整体替换任何一块。读完这章，模板就从"黑盒"变成"素材库"。

## 15.1 十三个特殊屏幕总览

Ren'Py 引擎在特定时机寻找特定名字的屏幕来使用，这些名字就是保留名。全集如下：

| 屏幕 | 触发时机 | 参数约定 | 职责 |
| --- | --- | --- | --- |
| `say` | 每条对话语句 | `say(who, what)` | 对话窗口 |
| `choice` | `menu` 语句 | `choice(items)` | 选项列表 |
| `input` | `renpy.input()` | `input(prompt)` | 文本输入 |
| `nvl` | NVL 模式对话 | `nvl(dialogue, items=None)` | NVL 文字窗 |
| `notify` | `renpy.notify()` 等 | `notify(message)` | 轻量通知 |
| `skip_indicator` | 快进进行中 | 无 | "快进中"指示 |
| `ctc` | 对话结束等待点击 | 五个参数（15.6） | "点击继续"指示 |
| `main_menu` | 游戏启动/回主菜单 | 无 | 主菜单 |
| `navigation` | 被别的屏幕 `use` | 无 | 菜单按钮列 |
| `save` / `load` | `ShowMenu` | 无 | 存读档页 |
| `preferences` | `ShowMenu` | 无 | 偏好设置页 |
| `confirm` | 需要玩家确认时 | `confirm(message, yes_action, no_action)` | 是/否对话框 |

三个约定要提前说清：

- **参数是引擎传的**：`say(who, what)` 的 `who` 是角色名字符串（旁白时为 None），`what` 是对话文本——你不用关心它们从哪来，引擎每次对话都会喂进来；
- **id 是引擎找的**：某些屏幕里必须有带特定 id 的显示物（say 里的 `id "what"`、input 里的 `id "input"`），引擎靠 id 找到它们来注入文字逐字显示、输入焦点这类引擎级行为；
- **`quick_menu` 不是特殊屏幕**。它虽然也长在模板里，但只是个普通屏幕，靠一行 `config.overlay_screens.append("quick_menu")` 挂成"永远显示的覆盖层"。想自定义底部快捷栏，改普通屏幕即可。

替换的方式也有两档：**整套重写**（本章各节的自定义版本）或**只改样式**（15.10 的 style 语句）——大多数游戏改样式就够了，重写留给"形状都不一样"的需求。

## 15.2 say 屏幕：每句对话都从这过

先看官方模板的默认实现——全文就这几行，却定义了你对"视觉小说"的全部印象：

```renpy
screen say(who, what):

    window:
        id "window"

        if who is not None:

            window:
                id "namebox"
                style "namebox"
                text who id "who"

        text what id "what"


## If there's a side image, display it above the text. Do not display
## on the phone variant - there's no room.
if not renpy.variant("small"):
    add SideImage() xalign 0.0 yalign 1.0
```

逐行拆：

- `window: id "window"`：对话窗容器。模板配套样式（`style window`）给它定了位置——底部横条、贴着 `gui/textbox.png` 背景图。引擎认 `id "window"` 这个标记：玩家按键调整窗口透明度等引擎特性，作用对象就是它；
- `if who is not None:`：旁白（叙述者无名）时不显示名字框。这个判断几乎每个自定义 say 都要继承；
- `window: id "namebox"`：名字框，套 `style "namebox"`（模板里它定位在窗口左上、贴 `gui/namebox.png` 背板）。紧跟的 `config.character_id_prefixes.append('namebox')`（模板 init 块里）让 Character 对象的 namebox 相关样式参数能作用到这个显示物上——你在剧本里写 `Character("艾琳", who_color="#e0b354")` 时，颜色就是顺着这条通道流进 `text who` 的；
- `text what id "what"`：**全屏幕的命脉**。引擎靠 `id "what"` 找到这个 text 显示物，把逐字显示、快进、文本标签处理都挂上去。自定义 say 无论如何改版，`id "what"` 丢了对话就没了；
- `add SideImage()`：角色侧立绘（Character 的 `side` 参数指定的那张小头像），`xalign 0.0 yalign 1.0` 贴左下角；小屏设备（手机）没空间，跳过。

现在写一个免素材的自定义版：整块深色面板、名字金色、完全脱离模板的图片资源：

```renpy
screen say(who, what):
    window:
        id "window"
        background Frame(Solid("#1b1b2f"), 8, 8, 8, 8)
        yalign 1.0
        yfill True
        ymaximum 260
        padding (40, 24)

        vbox:
            spacing 8
            if who is not None:
                text who color "#e0b354" size 26
            text what id "what" size 24
```

- `Solid("#1b1b2f")` 是一块纯色显示物；`Frame(..., 8, 8, 8, 8)` 把它按"四边各留 8 像素"切九片做九宫格拉伸——纯色块加边距，得到一块**边缘带柔性缩放的素色面板**。这是免素材游戏的万能背景配方（`Frame(纯色, 边距)`），第 12 章的立绘背景也用过同款思路；
- `yalign 1.0` 贴屏幕底部，`yfill True` 拉满宽度（window 默认横向填充，这里显式写清楚），`ymaximum 260` 限高——对话窗高 260 像素，不随文本膨胀；
- `vbox` 让名字与正文纵向排开，比模板的"名字浮在窗口上沿"布局更朴素直白。

把它存进项目（比如 `myscreens.rpy`），模板的同名 say 就被遮蔽——启动游戏，所有对话都换新装。

## 15.3 choice 屏幕：选项按钮的生产线

`menu` 语句的选项，就是被这块屏幕渲染出来的：

```renpy
screen choice(items):
    style_prefix "choice"

    vbox:
        for i in items:
            textbutton i.caption action i.action
```

这可能是全部特殊屏幕里最短的一个，但有三处值得抄走的设计：

- `items` 的每个元素是引擎构造的**选项对象**，带两个字段：`caption`（选项文本）与 `action`（点击动作）。动作是引擎替你组装好的——`menu:` 里的 `option if 条件:`、选项后接的 `$` 语句，最终都化在这一个 `i.action` 里。你的屏幕只管渲染，**逻辑一个字都不用碰**；
- `for i in items:`：选项几个就渲染几个，菜单语句写多少条 `:` 分支都接得住；
- `style_prefix "choice"`：给整块屏幕指定样式前缀，内部的 textbutton 自动找 `choice_button` 样式、按钮文字找 `choice_button_text`。模板配套样式里 `choice_vbox` 定位在屏幕水平居中、`ypos gui.scale(270)` 的位置，选项间距 `gui.choice_spacing`——所以默认选项总是居中偏上、竖排。这套前缀机制 15.10 专讲。

自定义版把竖排改横排、加手写编号：

```renpy
screen choice(items):
    style_prefix "choice"

    vbox:
        xalign 0.5 yalign 0.6
        spacing 12

        hbox:
            spacing 20
            xalign 0.5
            for i in items:
                textbutton i.caption action i.action

        text "（用鼠标点选）" size 18 color "#888888"
```

布局随便你怎么折腾——只要每个选项的 `i.caption` 和 `i.action` 原样接到 textbutton 上，菜单行为就分毫不差。

## 15.4 input 屏幕：renpy.input 的前台

第 7 章用过 `renpy.input()` 收玩家输入的姓名，当时没追问"输入框是哪来的"——答案就是这块屏幕：

```renpy
screen input(prompt):
    style_prefix "input"

    window:

        vbox:
            xanchor gui.dialogue_text_xalign
            xpos gui.dialogue_xpos
            xsize gui.dialogue_width
            ypos gui.dialogue_ypos

            text prompt style "input_prompt"
            input id "input"
```

- 参数只有 `prompt`：调用 `renpy.input("问题")` 时传的问题文本；
- `input id "input"`：输入焦点所在的显示物。**关键机制**：你调用 `renpy.input()` 时给的所有参数——`default`（默认值）、`length`（最大长度）、`allow`/`exclude`（字符白名单黑名单）、`hideable` 等——引擎会**原样转交给这个 id 为 "input" 的显示物**。屏幕代码里看不到它们，也不该写它们：屏幕只提供"输入框放在哪、长什么样"，输入规则全在调用侧。这是特殊屏幕"参数由引擎传递"约定的典型样本；
- 定位属性全套来自 `gui.*` 变量（对话区的坐标与宽度），所以默认观感与 say 窗口严丝合缝。

回顾一下剧本侧的完整用法，两行就能收一个名字：

```renpy
define p = Character("[player_name]")

label naming:
    $ player_name = renpy.input("你的名字是？（最长 20 字）", length=20)
    $ player_name = player_name.strip() or "小澄"
    p "我叫[player_name]！"
```

`length=20` 这个参数玩家端"感受不到代码"，但它实际穿过了 input 屏幕、落在 `id "input"` 的显示物上——理解了这条传递链，你就明白为什么屏幕里不该再写一遍 length。

自定义版把输入框做成居中卡片，告别"贴着对话窗"的默认布局：

```renpy
screen input(prompt):
    style_prefix "input"

    frame:
        xalign 0.5 yalign 0.5
        padding (40, 30)
        background Frame(Solid("#262640"), 8, 8, 8, 8)

        vbox:
            spacing 14
            text prompt size 26
            input id "input" size 26
```

## 15.5 notify 屏幕：两秒钟的轻反馈

通知屏幕是引擎的"气泡提示"：快速存档、截图、还有第 14 章你写进 `renpy.notify()` 的每一句话，都由它展示。模板实现带了一个精巧的 ATL 小变换：

```renpy
screen notify(message):

    zorder 100
    style_prefix "notify"

    frame at notify_appear:
        text "[message!tq]"

    timer 3.25 action Hide('notify')


transform notify_appear:
    on show:
        alpha 0
        linear .25 alpha 1.0
    on hide:
        linear .5 alpha 0.0
```

四件事值得学：

- `zorder 100`：通知永远浮在同层其他界面之上——HUD、菜单都不该挡住它；
- `frame at notify_appear:`：`at` 把 ATL transform 挂到 frame 上。`notify_appear` 用 `on show` / `on hide` 两个事件分支：显示时 0.25 秒淡入，移除时 0.5 秒淡出。**没有任何 Python 代码**，纯声明式的进出场动画；
- `text "[message!tq]"`：插值旗标 `!tq` 是二合一——`!t` 按翻译键查译文（没译文则原样），`!q` 把文本里的 `[`、`{` 等特殊字符转义掉，防止消息内容被误当成插值或文本标签。给"可能含用户输入或特殊符号"的消息插值时，`!q` 是安全带；
- `timer 3.25 action Hide('notify')`：timer 显示物是**一次性倒计时器**——3.25 秒后执行 `Hide('notify')`，屏幕自我了断。淡入 0.25 秒、展示约两秒多、淡出交给 hide 事件的 0.5 秒，时间线全靠这行 timer 串起来。

自定义版换个配色与位置，其余机制原封不动：

```renpy
screen notify(message):
    zorder 100

    frame at notify_appear:
        ypos 90
        padding (24, 12)
        background Frame(Solid("#000000c0"), 8, 8, 8, 8)
        text "[message!tq]" color "#ffffff" size 22

    timer 3.25 action Hide('notify')
```

`Solid("#000000c0")` 末两位 `c0` 是十六进制透明度——半透明黑，通知悬在画面上不喧宾夺主。

## 15.6 skip_indicator 与 ctc：快进指示与点击继续

这两个屏幕都回答同一个问题："现在该干嘛？"

**skip_indicator** 在快进进行中显示、停止时自动消失。模板版自带一个逐个闪烁的三箭头：

```renpy
screen skip_indicator():

    zorder 100
    style_prefix "skip"

    frame:

        hbox:
            spacing gui.scale(6)

            text _("Skipping")

            text "▸" at delayed_blink(0.0, 1.0) style "skip_triangle"
            text "▸" at delayed_blink(0.2, 1.0) style "skip_triangle"
            text "▸" at delayed_blink(0.4, 1.0) style "skip_triangle"


## This transform is used to blink the arrows one after another.
transform delayed_blink(delay, cycle):
    alpha .5

    pause delay

    block:
        linear .2 alpha 1.0
        pause .2
        linear .2 alpha 0.5
        pause (cycle - .4)
        repeat
```

- `delayed_blink(delay, cycle)` 是**带参数的 ATL transform**（第 10 章讲过）：三个箭头分别传 delay 0.0、0.2、0.4——起步错开 0.2 秒，波浪式接力闪烁；`block: ... repeat` 让每个箭头在自己的周期里"亮起→停顿→变暗→等待"无限循环；
- `gui.scale(6)`：按 gui 缩放系数换算数值，分辨率适配用（模板里 gui 变量体系在第 22 章展开）；
- 模板还给它配了 `font "DejaVuSans.ttf"`——"▸"这个字形不在默认字体里，注释特意说明了这点。自定义时若用特殊字符，同样要确认字体覆盖。

**ctc**（click-to-continue）是"点击继续"的小指示物。它默认**不是屏幕而是显示物**——`Character(ctc=...)` 直接挂一张图或一个 transform；当你在项目里定义了 ctc 屏幕，引擎就改走屏幕路线。参数共五个：

- `arg`：Character 的 ctc 参数指定的那个显示物；
- `ctc_kind`：触发类型，"click"（点一下继续）/ "pause"（`pause` 语句的停顿）/ "timedpause"（`pause 1.5` 这类限时停顿）；
- `ctc_last`：这条对话是不是整段的最后一句；
- `ctc_pause`：当前是不是普通停顿；
- `ctc_timedpause`：当前是不是限时停顿。

最常用的定义就是转发：

```renpy
screen ctc(arg):
    add arg
```

`add arg` 把 Character 指定的显示物放到默认位置（对话窗右下角附近）。进阶玩法是按停顿类型换文案——"剧情没完，停顿后面还有话"与"这段说完了，点击继续"用不同指示：

```renpy
screen ctc(arg):
    if ctc_pause:
        text "…略作停顿" xalign 0.97 yalign 0.95 size 18 color "#cccccc"
    else:
        add arg xalign 0.97 yalign 0.95
```

免素材游戏里，`arg` 本身就可以是个 ATL transform：

```renpy
define bounce = Transform("•", size=30)     # 或者任何显示物

define e = Character("艾琳", ctc=bounce)
```

（严格说 `ctc=` 接受显示物或变换，模板游戏普遍传一张小图——免素材时传 Text/Solid 做的显示物同样成立。）

## 15.7 主菜单、导航栏与游戏菜单框架

到目前为止我们讲解的特殊屏幕都只负责“一小块”体验：说话框、选项、通知。真正撑起整个游戏骨架的，是三个相互配合的屏幕：`navigation`（那列菜单按钮）、`main_menu`（主菜单页）、`game_menu`（所有“系统页”的共用框架）。模板把导航按钮单独抽成一个屏幕，是为了让主菜单页和系统页能复用同一列按钮——这是很值得学习的工程手法。

### 15.7.1 navigation：一列复用的菜单按钮

先看模板中 `navigation` 屏幕的原文（摘自模板工程的 `screens.rpy`）：

```renpy
screen navigation():

    vbox:
        style_prefix "navigation"

        xpos gui.navigation_xpos
        yalign 0.5

        spacing gui.navigation_spacing

        if main_menu:

            textbutton _("Start") action Start()

        else:

            textbutton _("History") action ShowMenu("history")

            textbutton _("Save") action ShowMenu("save")

        textbutton _("Load") action ShowMenu("load")

        textbutton _("Preferences") action ShowMenu("preferences")

        if _in_replay:

            textbutton _("End Replay") action EndReplay(confirm=True)

        elif not main_menu:

            textbutton _("Main Menu") action MainMenu()

        textbutton _("About") action ShowMenu("about")

        if renpy.variant("pc") or (renpy.variant("web") and not renpy.variant("mobile")):

            ## Help isn't necessary or relevant to mobile devices.
            textbutton _("Help") action ShowMenu("help")

        if renpy.variant("pc"):

            ## The quit button is banned on iOS and unnecessary on Android and Web.
            textbutton _("Quit") action Quit(confirm=not main_menu)
```

这个屏幕没有任何参数，只包含一个竖排 `vbox`，里面全是条件化的 `textbutton`。值得逐条讲清的是它的四个分支：

**分支一：`if main_menu:`**。`main_menu` 是引擎自动维护的内置变量（模板的 `00start.rpy` 中会在进入主菜单时把它置为 `True`，开始游戏后置为 `False`），你不需要也不应该自己赋值。它在导航栏里的作用是：主菜单时显示“开始游戏”，游戏内则换成“历史/存档”。这正是第 14 章讲过的 `Start()` 与 `ShowMenu(...)` 两个流程动作的实战分工。

**分支二：`if _in_replay:`**。`_in_replay` 也是引擎内置变量：当玩家从“从场景回放”进入游戏片段时它为真。此时导航栏显示“结束回放”（`EndReplay(confirm=True)`），并跳过“回到主菜单”——因为回放期间“主菜单”按钮毫无意义。`elif not main_menu:` 保证这条分支只在游戏内出现。回放功能的完整用法在第 20 章展开，这里只需理解这两个内置变量如何驱动同一份导航代码表现出不同形态。

**分支三：`renpy.variant("pc")`**。`renpy.variant()` 返回当前平台是否属于某变体（`"pc"`、`"mobile"`、`"web"` 等）。模板用它隐藏两类按钮：移动端不需要 Help 页；iOS/安卓/网页版根本不该有“退出程序”按钮（网页版没有退出概念，iOS 则禁止）。你的游戏若要支持多平台，就该沿用这个模式，而不是让按钮在手机上点了没反应。

**分支四：`Quit(confirm=not main_menu)`**。同一动作，参数按场景变化：在游戏内退出要弹确认框（防止误触丢进度），在主菜单退出则直接退（反正没有进度可丢）。`confirm` 接受表达式而非常量，这是动作参数可以“随状态计算”的好例子。

样式部分还有一个小机关：

```renpy
style navigation_button:
    size_group "navigation"
    properties gui.button_properties("navigation_button")
```

`size_group "navigation"` 把所有同组显示物拉到相同宽度——导航栏每个按钮文字长短不一（“Preferences” 和 “About”），但 `size_group` 让它们共享最宽者决定的宽度，视觉上整齐对齐。不需要图片、不需要算像素，一个属性解决。`gui.button_properties(...)` 则来自 `gui.rpy` 的变量体系，15.10 节专门讲。

### 15.7.2 main_menu：一个屏幕就是一个页面

主菜单屏幕本身出奇地短：

```renpy
screen main_menu():

    ## This ensures that any other menu screen is replaced.
    tag menu

    add gui.main_menu_background

    ## This empty frame darkens the main menu.
    frame:
        style "main_menu_frame"

    ## The use statement includes another screen inside this one. The actual
    ## contents of the main menu are in the navigation screen.
    use navigation

    if gui.show_name:

        vbox:
            style "main_menu_vbox"

            text "[config.name!t]":
                style "main_menu_title"

            text "[config.version]":
                style "main_menu_version"
```

四块内容，每块都有讲究：

**`tag menu`**——整个屏幕的“互斥锁”。第 13 章讲过 `tag` 让同标签屏幕互相替换，而 `"menu"` 这个标签被保留用于菜单页：玩家从主菜单点“读取存档”时，`ShowMenu("load")` 显示 load 屏幕，它的 `tag menu` 自动顶掉 main_menu 屏；再点“设置”，preferences 又顶掉 load。所有模板菜单页都以 `tag menu` 开头，这就是“菜单页永远只有一个”的实现机制。你自定义任何系统页时，第一行也应该是 `tag menu`。

**`add gui.main_menu_background`**——背景图不是写死的路径，而是引用 `gui.rpy` 里的变量 `define gui.main_menu_background = "gui/main_menu.png"`。想换主菜单图，改 `gui.rpy` 一行即可；想做“随章节变化的主菜单”，也可以在脚本里给这个变量赋别的值（或干脆在自己的 main_menu 屏里写 `add "images/bg/menu.jpg"`）。

**`use navigation`**——组合而非复制。菜单按钮列是共享屏幕，主菜单只是把它嵌进来。前面 game_menu 也会 `use navigation`，同一列按钮出现在两个页面而代码只有一份。

**`if gui.show_name:`**——游戏名与版本号显示与否由 `gui.rpy` 变量控制（`define gui.show_name = True`）。`text "[config.name!t]"` 里是两个前面讲过的知识点叠加：方括号插值取 `config.name`（项目名，在 options.rpy 定义），`!t` 走翻译——这样外文版主菜单会自动显示翻译后的游戏名。`config.version` 同理取版本号字符串。

模板样式里给主菜单文字加了一层“压暗左边”的手法，也值得一提：

```renpy
style main_menu_frame:
    xsize gui.scale(280)
    yfill True

    background "gui/overlay/main_menu.png"
```

一个空的 `frame` 铺满左侧 280 像素宽、全高，背景是一张半透明的渐变 PNG——按钮列底下垫一层暗色，白字才不会被亮背景吃掉。免素材的做法我们已经很熟：把 background 换成 `Solid("#00000080")` 即可得到半透明黑幕。`gui.scale(...)` 是 `gui.rpy` 提供的缩放函数：模板界面按 1280×720 设计，若项目分辨率更高，所有尺寸自动等比放大——这就是“模板界面任意分辨率都不糊”的秘密，15.10 节展开。

### 15.7.3 game_menu：所有系统页共用的框架

“读取存档”“设置”“历史”“关于”“帮助”五个页面长得像：同一张背景、同一个框架、同一列导航、左下角同一个“返回”按钮。模板没有把这份布局复制五遍，而是做一个带参数的框架屏幕 `game_menu`，让每个系统页往里“填内容”。先看原文（有删节处均已保留结构）：

```renpy
screen game_menu(title, scroll=None, yinitial=0.0, spacing=0):

    style_prefix "game_menu"

    if main_menu:
        add gui.main_menu_background
    else:
        add gui.game_menu_background

    frame:
        style "game_menu_outer_frame"

        hbox:

            ## Reserve space for the navigation section.
            frame:
                style "game_menu_navigation_frame"

            frame:
                style "game_menu_content_frame"

                if scroll == "viewport":

                    viewport:
                        yinitial yinitial
                        scrollbars "vertical"
                        mousewheel True
                        draggable True
                        pagekeys True

                        side_yfill True

                        vbox:
                            spacing spacing

                            transclude

                elif scroll == "vpgrid":

                    vpgrid:
                        cols 1
                        yinitial yinitial

                        scrollbars "vertical"
                        mousewheel True
                        draggable True
                        pagekeys True

                        side_yfill True

                        spacing spacing

                        transclude

                else:

                    transclude

    use navigation

    textbutton _("Return"):
        style "return_button"

        action Return()

    label title

    if main_menu:
        key "game_menu" action ShowMenu("main_menu")
```

这个屏幕是 `use` + `transclude` 组合的标准教案，参数逐个讲：

**`title`**——页面标题字符串（如 `_("Load")`），最后由 `label title` 渲染在页面顶部。注意 `label title` 写成了一行：label 是容器型语句，此处没有子内容，单行形式即可。

**`scroll`**——内容区形态开关，三选一：
- `scroll="viewport"`：内容包进带竖向滚动条的 `viewport`，滚轮、拖拽、翻页键全开。适合“长度不定的一列内容”，如 preferences 的分组。
- `scroll="vpgrid"`：内容包进 `cols 1` 的 `vpgrid`（单列网格）加滚动条。适合“每条等高的条目列表”，如 history 页的逐条发言。
- `scroll=None`（默认）：内容区直接 `transclude`，不套滚动。适合内容固定、高度可控的页面，如 about 页。

**`transclude`**——框架的“留白”。调用方写在 `use game_menu(...):` 语句块里的所有内容，会原位填进 `transclude` 所在处。这就是第 13 章 `use ... :` 块语法的完整应用：框架负责布局装饰，调用方负责内容，两者解耦。

**`textbutton _("Return"): action Return()`**——框架自带返回键。`Return()` 动作结束当前交互；由 `ShowMenu` 显示的菜单页收到 `Return` 后，引擎会退回上一个界面（游戏中按 Esc 打开菜单再按返回，就回到游戏；从主菜单进入的页面则回到主菜单）。所以“每个系统页都有返回”不需要各页自己写，框架统一提供。

**`if main_menu: key "game_menu" action ShowMenu("main_menu")`**——只有当系统页是从主菜单打开时（此时背景用的还是主菜单图，`if main_menu:` 第一个分支能证明这一点），才注册 `game_menu` 键映射（即右键/Esc）为“回到主菜单”。在游戏内打开的系统页里，右键的 `game_menu` 键由引擎的默认行为处理为返回。键映射作为屏幕语句、可以条件注册，这是它和 `config.keymap` 全局映射的区别。

看一个真实调用方——模板的 about 页就是这么用框架的：

```renpy
screen about():

    tag menu

    ## This `use` statement includes the game_menu screen here. The vbox
    ## child is then included inside the viewport inside the game_menu
    ## screen.
    use game_menu(_("About"), scroll="viewport"):

        style_prefix "about"

        vbox:

            spacing gui.scale(8)

            text "[config.name!t]"
            text _("Version [config.version!q]\n")

            ## gui.about is usually set in options.rpy.
            if gui.about:
                text "[gui.about!t]\n"

            text _("Made with {a=https://www.renpy.org/}Ren'Py{/a} [renpy.version_only].\n\n[renpy.license!t]")
```

`tag menu` 保证互斥；`use game_menu(_("About"), scroll="viewport"):` 后面的整块 vbox 就是塞进 `transclude` 的内容；文本里的 `[config.version!q]` 用了 `!q` 转义、`{a=...}` 是文本标签超链接。你自己加系统页时照抄这个骨架即可，比如给游戏加一个“状态页”：

```renpy
screen stats_page():

    tag menu

    use game_menu(_("状态"), scroll="viewport"):

        vbox:
            spacing 10

            text "好感度：[affection]"
            text "金钱：[gold] G"
            text "已解锁结局：[endings_count] / 5"
```

再在任意按钮上配 `action ShowMenu("stats_page")`，一个带标题、带导航、带滚动条、带返回键的系统页就完成了——布局代码一行没写。这就是模板框架的价值。

## 15.8 存读档界面：save、load 与 file_slots

模板的存读档界面是“框架复用 + 智能动作”的又一次示范。save 和 load 两个屏幕短到只有三行：

```renpy
screen save():

    tag menu

    use file_slots(_("Save"))


screen load():

    tag menu

    use file_slots(_("Load"))
```

真正的布局在共享屏幕 `file_slots` 里，save 与 load 只是把标题不同地传进去。而槽位按钮的核心动作 `FileAction` 我们在第 14 章已经讲过：空槽上它表现为“保存”，有档槽上表现为“读取”（配合确认），所以同一个 `file_slots` 屏幕不加修改就能同时服务存与读。下面是 `file_slots` 的原文，分三段讲：

```renpy
screen file_slots(title):

    default page_name_value = FilePageNameInputValue(pattern=_("Page {}"), auto=_("Automatic saves"), quick=_("Quick saves"))

    use game_menu(title):

        fixed:

            ## This ensures the input will get the enter
            ## event before any of the buttons do.
            order_reverse True

            ## The page name, which can be edited by clicking on a button.
            button:
                style "page_label"

                key_events True
                xalign 0.5
                action page_name_value.Toggle()

                input:
                    style "page_label_text"
                    value page_name_value
```

第一段是**页名编辑区**。`FilePageNameInputValue` 是一个 InputValue（第 19 章细讲输入系统，这里看用法即可）：它知道当前在第几页，并按 `pattern` 生成名字——“Page {}” 里的 `{}` 会被页号替换；若当前是自动存档页则显示 `auto` 参数的文本，快速存档页同理。`input` 显示物通过 `value page_name_value` 绑定它，于是页名成了可编辑文本；`page_name_value.Toggle()` 让点击按钮在“可编辑/只显示”间切换。`button` 上的 `key_events True` 让按钮自己先把回车键事件收下来（编辑完按回车确认，而不是触发别的按钮），`fixed` 的 `order_reverse True` 再保证输入显示物比按钮更早拿到事件——两行注释写的就是这两个机关为什么必须存在。给存档页起别名（“第一章 ending”）这种体贴功能，模板免费送给你了。

```renpy
            ## The grid of file slots.
            grid gui.file_slot_cols gui.file_slot_rows:
                style_prefix "slot"

                xalign 0.5
                yalign 0.5

                spacing gui.slot_spacing

                for i in range(gui.file_slot_cols * gui.file_slot_rows):

                    $ slot = i + 1

                    button:
                        action FileAction(slot)

                        has vbox

                        add FileScreenshot(slot) xalign 0.5

                        text FileTime(slot, format=_("{#file_time}%A, %B %d %Y, %H:%M"), empty=_("empty slot")):
                            style "slot_time_text"

                        text FileSaveName(slot):
                            style "slot_name_text"

                        key "save_delete" action FileDelete(slot)
```

第二段是**槽位网格**。`grid gui.file_slot_cols gui.file_slot_rows` 用 `gui.rpy` 变量决定行列（默认 3×2），`for i in range(cols*rows)` 生成每个槽，`$ slot = i + 1` 转成从 1 起的页内槽号——`FileAction(slot)`、`FileScreenshot(slot)` 等动作和函数都吃这个号（第 14 章讲过：name 是页内槽号，实际全局槽名形如 “1-3”，由当前页与槽号组合而来）。每个槽是一个 `button`，`has vbox`（第 13 章讲过）让按钮内容竖排：存档截图（`FileScreenshot`，空槽返回 None 则不显示）、存档时间（`FileTime`，`format` 串前面的 `{#file_time}` 是翻译标记、不计入显示，`empty` 指定空槽文案）、存档时的对话名（`FileSaveName`）。最后 `key "save_delete" action FileDelete(slot)`：把键映射 `save_delete`（默认为删除键）转发给“删除这个槽”的动作——光标停在哪个槽，按键就删哪个槽。

```renpy
            ## Buttons to access other pages.
            vbox:
                style_prefix "page"

                xalign 0.5
                yalign 1.0

                hbox:
                    xalign 0.5

                    spacing gui.page_spacing

                    textbutton _("<") action FilePagePrevious()
                    key "save_page_prev" action FilePagePrevious()

                    if config.has_autosave:
                        textbutton _("{#auto_page}A") action FilePage("auto")

                    if config.has_quicksave:
                        textbutton _("{#quick_page}Q") action FilePage("quick")

                    ## range(1, 10) gives the numbers from 1 to 9.
                    for page in range(1, 10):
                        textbutton "[page]" action FilePage(page)

                    textbutton _(">") action FilePageNext()
                    key "save_page_next" action FilePageNext()

                if config.has_sync:
                    if CurrentScreenName() == "save":
                        textbutton _("Upload Sync"):
                            action UploadSync()
                            xalign 0.5
                    else:
                        textbutton _("Download Sync"):
                            action DownloadSync()
                            xalign 0.5
```

第三段是**页码行**。`FilePagePrevious()`/`FilePageNext()` 翻页（`FilePageNext` 的 `max` 参数可封顶，默认封到 9）；`<` `>` 按钮旁各注册一个键映射实现键盘翻页。中间按条件列出特殊页：`config.has_autosave` 为真才有自动页按钮（`FilePage("auto")`），`config.has_quicksave` 为真才有快速页（`FilePage("quick")`），然后 `range(1, 10)` 循环出 1-9 九个普通页按钮。文案里的 `{#auto_page}`、`{#quick_page}` 同样是翻译标记。最后一段云同步按钮是较新版模板加入的：`config.has_sync` 开启后，存档页显示“上传同步”、读档页显示“下载同步”——`CurrentScreenName()` 函数返回当前屏幕名，用它区分两种身份。不用云同步就在 options.rpy 里把 `config.has_sync` 设为 False，这段 UI 自动消失。

## 15.9 confirm：确认对话框

模板里所有“真的要退出吗？”“真的要读档吗？”都走同一个特殊屏幕 `confirm`。引擎在需要确认时（例如 `Quit(confirm=True)` 被点击、`MainMenu()` 在游戏中被点击）自动 `Show("confirm")` 并把问题和两个后续动作作为参数传进来：

```renpy
screen confirm(message, yes_action, no_action):

    ## Ensure other screens do not get input while this screen is displayed.
    modal True

    zorder 200

    style_prefix "confirm"

    add "gui/overlay/confirm.png"

    frame:

        vbox:
            xalign .5
            yalign .5
            spacing gui.scale(30)

            label _(message):
                style "confirm_prompt"
                xalign 0.5

            hbox:
                xalign 0.5
                spacing gui.scale(100)

                textbutton _("Yes") action yes_action
                textbutton _("No") action no_action

    ## Right-click and escape answer "no".
    key "game_menu" action no_action
```

三个参数，两种身份：`message` 是问题文本（“读取该存档吗？”），`yes_action` 与 `no_action` 是引擎替你准备好的动作——点“是”执行确认的事，点“否”取消。注意 `textbutton _("Yes") action yes_action`：message 和按钮文案都要过 `_(...)` 走翻译，而传入的动作参数**不再包裹翻译函数**——动作是对象不是文本，这是新手常犯的包错。

四行防御性属性各自必要：`modal True` 挡住底下屏幕的一切输入（确认框出现时按钮点不到）；`zorder 200` 压过一切常规界面；`add "gui/overlay/confirm.png"` 是一张全屏半透明暗化图，把玩家注意力聚焦到中央小框（免素材可换 `add Solid("#00000080")`）；`key "game_menu" action no_action` 让右键/Esc 等于点“否”——确认框永不劫持玩家的退出路径，最坏情况是取消。

这个屏幕的调用方你也可以仿写。游戏里自制确认（比如“重开一周目？”）不必等引擎，直接自己 Show：

```renpy
screen restart_confirm():

    modal True
    zorder 200

    add Solid("#00000080")

    frame:
        xalign 0.5
        yalign 0.5
        padding (40, 30)

        vbox:
            spacing 20

            text "要重新开始吗？未保存的进度将丢失。"

            hbox:
                spacing 40
                xalign 0.5

                textbutton "重新开始" action [ Hide("restart_confirm"), Jump("prologue") ]
                textbutton "取消" action Hide("restart_confirm")

    key "game_menu" action Hide("restart_confirm")
```

与特殊屏幕的区别只在参数：特殊屏幕由引擎传参，自制屏幕自己定参数、自己传动作。逻辑完全一致。

## 15.10 界面样式基础：style 语句与 gui 变量体系

前面十几节里我们反复见到 `style_prefix`、`is`、`gui.xxx`，这一节把它们一次讲透。Ren'Py 的样式系统回答一个问题：**显示物的每个外观属性（颜色、字号、内边距、背景图）从哪里来？** 答案是样式（style）：每个显示物按名字找到一条样式，样式里的属性决定外观；屏幕语言里写的内联属性（如 `xalign 0.5`）只是临时覆盖。

### 15.10.1 style 语句与 is 继承

`style` 语句定义一条样式。模板文件开头那一串就是最典型的教材：

```renpy
style default:
    properties gui.text_properties()
    language gui.language

style input:
    properties gui.text_properties("input", accent=True)
    adjust_spacing False

style hyperlink_text:
    properties gui.text_properties("hyperlink", accent=True)
    hover_underline True

style gui_text:
    properties gui.text_properties("interface")


style button:
    properties gui.button_properties("button")

style button_text is gui_text:
    properties gui.text_properties("button")
    yalign 0.5
```

三个要点：

**继承用 `is`**。`style button_text is gui_text:` 意思是 button_text 样式基于 gui_text 样式——gui_text 有的属性它都有，除非自己再写一份覆盖。`button_text` 是按钮内文字的默认样式，继承自界面文字样式，于是界面文字一改全局按钮文字跟着变。Ren'Py 预置了一条继承链的根：所有文本样式最终都该能追到 `default`。模板里的 `style label_text is gui_text`、`style prompt_text is gui_text` 都是这个思路：先共享，再微调。

**`properties gui.text_properties(...)` 是什么**。这是 `gui.rpy` 提供的函数，返回一组属性字典。`gui.text_properties("button")` 返回与按钮文字相关的全部属性（字体、字号、颜色……），值来自同名的 gui 变量（如 `gui.button_text_size`）。它的价值是**解耦**：screen 文件里写 `properties gui.text_properties("button")`，外观数值全部集中在 gui.rpy 里，改字号不用碰 screens.rpy。常用三个：`gui.text_properties(prefix, accent=False)` 文本属性、`gui.button_properties(prefix)` 按钮属性（含自动取 `gui.button_text_properties`）、以及 bar/frame 等各自的一套。`accent=True` 表示取强调色而非正文色。

**[prefix_] 占位符**。看滚动条样式：

```renpy
style scrollbar:
    ysize gui.scrollbar_size
    base_bar Frame("gui/scrollbar/horizontal_[prefix_]bar.png", gui.scrollbar_borders, tile=gui.scrollbar_tile)
    thumb Frame("gui/scrollbar/horizontal_[prefix_]thumb.png", gui.scrollbar_borders, tile=gui.scrollbar_tile)
```

`[prefix_]` 会在应用样式时被替换成样式前缀。同一个 `scrollbar` 样式，被 `style_prefix "slot"` 的屏幕用到时，图片路径变成 `gui/scrollbar/horizontal_slot_bar.png`——每个前缀一个专属图片文件，而样式只写一次。若替换后文件不存在，回退到无前缀版本。这套机制让“换肤”变成换图片文件，样式代码零修改。

### 15.10.2 style_prefix 的映射规则

第 13 章埋的伏笔在此兑现：屏幕或容器上的 `style_prefix "choice"` 会按**位置角色**给内部显示物派生样式名。规则是：

- 容器（vbox/hbox/frame/grid 等）→ `前缀_显示物名`：`choice_vbox`
- 按钮 → `前缀_button`：`choice_button`
- 按钮内文字 → `前缀_button_text`：`choice_button_text`
- 文本 → `前缀_text`、标签文字 → `前缀_label_text`，以此类推

所以 choice 屏幕只写一行 `style_prefix "choice"`，引擎就会去找 `choice_vbox`、`choice_button`、`choice_button_text` 三条样式：

```renpy
style choice_vbox:
    xalign 0.5
    ypos gui.scale(270)
    yanchor 0.5
    spacing gui.choice_spacing

style choice_button is gui_button:
    properties gui.button_properties("choice_button")

style choice_button_text is gui_button_text:
    properties gui.text_properties("choice_button")
```

想改选项按钮外观，改这三条样式或它们背后的 gui 变量即可。你自定义屏幕时同样受益：`style_prefix "shop"` 之下，按钮自动去找 `shop_button`、文字找 `shop_button_text`——按角色自动命名，不需要逐个显示物手工指 style。要精确指定时（如按钮想借用别的样式），用 `style "return_button"` 直接点名。

`[prefix_]` 与 style_prefix 是同一前缀概念在两个维度的应用：一个作用于**样式查找名**，一个作用于**图片路径**。理解了前者，后者自然就懂。

### 15.10.3 gui.rpy 变量：模板界面参数化的核心

打开模板工程的 `gui.rpy`，会看到几百行 `define gui.xxx = ...`：

```renpy
define gui.accent_color = '#cc6666'
define gui.idle_color = '#aaaaaa'
define gui.hover_color = '#e0e0e0'

define gui.text_size = 33
define gui.name_text_size = 45
define gui.interface_text_size = 36

define gui.button_text_size = gui.interface_text_size
```

这些变量就是模板界面的“设置面板”：颜色、字号、间距、图片路径、行列数，全部收拢在一个文件。三层引用关系让它有体系感——基础变量（`gui.interface_text_size = 36`）→ 派生变量（`gui.button_text_size = gui.interface_text_size`）→ 样式（`properties gui.text_properties("button")` 读取派生变量）。改一个基础变量，全界面联动。

`gui.scale(...)` 函数是分辨率适配的钥匙：模板按 1280×720 设计，`gui.init(1280, 720)` 时 scale 就是恒等；项目分辨率设 1920×1080 后，所有经 `gui.scale` 的尺寸自动乘 1.5。这就是“模板游戏换高分辨率不糊”的全部秘密——前提是你的素材也按高分辨率出图。

对自包含教学而言，你只需要记住一套工作流：**改外观先找 gui.rpy 变量；变量没有的才去改 screens.rpy 的 style；一次性微调才用内联属性。** 三层各司其职，项目越大越显出价值。

## 15.11 本章小结与示例工程

本章覆盖了模板 `screens.rpy` 中全部特殊屏幕与框架结构。把要点收拢成一张表：

| 屏幕/机制 | 一句话职责 | 关键机关 |
| --- | --- | --- |
| say | 对话框 | `id "what"` 必需，`who is not None` 区分旁白，namebox 前缀打通 Character 样式 |
| choice | 选项列表 | 只渲染 `i.caption`/`i.action`，逻辑全在引擎 |
| input | 输入框 | `id "input"` 自动接收 renpy.input 的全部参数 |
| notify | 角落通知 | `notify_appear` 变换 + `timer 3.25` 自毁，`[message!tq]` |
| skip_indicator | 快进指示 | `delayed_blink(delay, cycle)` 带参变换接力闪烁 |
| ctc | 点击继续 | 默认走 `Character(ctc=显示物)`；定义屏幕后引擎传五参数 |
| navigation | 菜单按钮列 | `main_menu`/`_in_replay`/`renpy.variant` 三层条件 |
| main_menu | 主菜单页 | `tag menu` 互斥，`use navigation` 复用 |
| game_menu | 系统页框架 | 参数 + 三分支滚动 + `transclude` 留白 |
| save/load/file_slots | 存读档 | `FileAction` 智能档位，页名可编辑，条件页码行 |
| confirm | 确认框 | modal + zorder 200 + key 兜底右键=否 |
| 样式体系 | 外观来源 | `is` 继承、`style_prefix` 映射、`[prefix_]` 路径、gui 变量三层引用 |

本章配套示例工程 **13_special_screens**（`examples/13_special_screens/`），把最有教学价值的部分做成了可运行小游戏：

- `script.rpy`：一个带旁白、带角色、带选项、带输入、带通知的短剧本，用于触发 say/choice/input/notify 四个特殊屏幕的自定义版本；
- `screens.rpy`：自定义 say（半透明底框+左侧名牌）、横排 choice、卡片式 input、底部通知条、自制 confirm 配色，全部免素材（Solid/Frame 手法）；
- `options.rpy`：精简配置。

构建与运行方式见附录 A。学完本章，建议做两个练习：给 say 屏幕加“点击对话框任意处继续”的 hint 文本；把 file_slots 的槽位网格改成 2×3（改 gui.rpy 两个变量即可——体会三层体系的好处）。

---

上一章：[14 Screen 动作与数据绑定](ch14-screen-actions.md) · 下一章：[16 变量、存档与回滚](ch16-save-and-rollback.md)
