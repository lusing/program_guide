# =============================================================
# 第 15 章 示例工程 13：特殊 screen、菜单定制与样式
# -------------------------------------------------------------
# 本工程演示如何覆盖「引擎保留（reserved）」的特殊 screen：
#   main_menu  —— 主菜单（本引擎环境没有内置主菜单，必须自己写）
#   say        —— 对话显示（定义它就会替换引擎原来的对话渲染）
#   choice     —— 游戏内选项菜单
# 并演示一个自定义的快捷菜单 screen，以及用 style 定制外观。
#
# 本工程只使用脚本文件，不引用任何 gui.* 变量，也不使用任何素材。
# =============================================================

# -------------------------------------------------------------
# 1. 角色定义
# -------------------------------------------------------------
# Character(...) 在没有任何 gui.rpy 的环境下也可以直接使用。
# who_style / what_style 指定角色名与对话文字使用的样式名，
# 我们会在第 4 节中用 style 语句重新定制这两个样式。
define e = Character("阿绫", color="#a0d0ff", who_style="say_label", what_style="say_dialogue")

# -------------------------------------------------------------
# 2. 自制主菜单
# -------------------------------------------------------------
# 引擎在启动时会在新上下文里调用 label _main_menu，
# 而 label _main_menu_screen 会检查是否存在名为 main_menu 的 label：
# 若存在就 jump 过去（见 renpy/common/00start.rpy）。
# 因此只要我们自己写一个 label main_menu，就完全接管了主菜单。
#
# 标准写法：label main_menu 的主体就是 call screen main_menu，
# 屏幕里放 Start() 与 Quit() 两种动作。

label main_menu:
    # call screen 会显示屏幕并等待玩家操作。
    # 屏幕里的 Start() 会执行 jump_out_of_context("start")，
    # 跳出主菜单上下文、进入游戏；Quit() 则直接退出。
    call screen main_menu
    return

# 屏幕名与 label 同名不冲突（label 与 screen 属于不同的命名空间）。
screen main_menu():

    # 用 Solid 铺一层纯色背景（Solid 是引擎内置显示体，无需素材）。
    add Solid("#1a1a2e")

    vbox:
        xalign 0.5
        yalign 0.42
        spacing 18

        # 标题
        text "特殊屏幕示例" size 48 xalign 0.5 color "#ffffff"
        text "第 15 章 · 菜单定制与样式" size 22 xalign 0.5 color "#9099b0"

        # 空的占位显示体，用来和标题拉开距离
        null height 20

        # 用 Start() 开始游戏、用 Quit() 退出。
        # Start 的签名是 Start(label="start")，默认跳到 start 标签。
        # Quit 的签名是 Quit(confirm=None)，这里传 confirm=False 表示不弹确认框。
        textbutton "开始游戏" action Start() xalign 0.5
        textbutton "退出" action Quit(confirm=False) xalign 0.5

# -------------------------------------------------------------
# 3. 覆盖对话屏幕 screen say
# -------------------------------------------------------------
# 说一句台词时，引擎会调用名为 say 的 screen，并把 who（角色名，可为 None）
# 与 what（台词文本）作为参数传进来。
# 只要我们在脚本里定义 screen say，就会替换引擎原来的对话渲染方式。
#
# 规范（见 doc/screen_special.html）要求：
#   - 必须创建至少一个 id 为 "what" 的 text（引擎依赖它计算自动前进等）
#   - 可以创建 id 为 "who" 的 text（角色名）
#   - 可以创建 id 为 "window" 的 window / frame（对话框容器）

screen say(who, what):

    # window id "window" 会接收角色对象传来的窗口样式（默认样式名 say_window）
    window id "window":
        # has vbox 表示窗口内直接使用一个竖直排列容器
        has vbox

        # 只有存在角色名时才显示名字
        if who:
            text who id "who"

        # 台词文本，id 必须为 "what"
        text what id "what"

# -------------------------------------------------------------
# 4. 用 style 定制对话外观
# -------------------------------------------------------------
# style 语句可以在顶层定义 / 覆盖样式。
# 这里定制的三个样式正是第 3 节屏幕里用到的默认样式名：
#   say_window   （id "window" 的容器）
#   say_label    （id "who" 的角色名文字）
#   say_dialogue （id "what" 的台词文字）
#
# 关于 style 属性与取值范围，可参考 doc/style_properties.html。

style say_window:
    # background 接受一个显示体，这里用纯色 Solid 作为对话框底
    background Solid("#101020")
    xalign 0.5
    xfill True
    yalign 1.0
    ysize 220
    padding (40, 24)

style say_label:
    color "#ffd479"
    size 30
    # outlines 是「描边」列表，每项为 (大小, 颜色, x偏移, y偏移)
    outlines [ (2, "#000000", 0, 0) ]
    xalign 0.02
    yalign 0.05

style say_dialogue:
    color "#ffffff"
    size 26
    outlines [ (2, "#222222", 0, 0) ]
    xalign 0.02
    yalign 0.35

# -------------------------------------------------------------
# 5. 覆盖选项屏幕 screen choice
# -------------------------------------------------------------
# menu 语句会用名为 choice 的 screen 来显示选项。
# 它只接收一个参数 items：这是一个列表，列表里的每个元素都有
# caption（选项文本）与 action（被选中时执行的动作）字段。
# 定义 screen choice 即可重新排版游戏内菜单。

screen choice(items):

    vbox:
        xalign 0.5
        yalign 0.3
        spacing 14

        # 逐个渲染每个选项
        for i in items:
            textbutton i.caption action i.action

# -------------------------------------------------------------
# 6. 自定义的快捷菜单 screen
# -------------------------------------------------------------
# 本引擎没有内置快捷菜单，这里演示一个自制的「快捷菜单」，
# 提供跳过、自动前进、退出三个按钮。
#   Preference("skip", "toggle")        —— 切换「跳过」
#   Preference("auto-forward", "toggle")—— 切换「自动前进」
#   Quit(confirm=False)                 —— 直接退出
# 这些动作都可在 renpy/common/00preferences.rpy 与 00action_menu.rpy 中查证。

screen demo_quick_menu():
    # zorder 100 让快捷菜单显示在其它屏幕之上
    zorder 100

    hbox:
        xalign 0.5
        yalign 1.0
        spacing 10

        textbutton "跳过" action Preference("skip", "toggle")
        textbutton "自动前进" action Preference("auto-forward", "toggle")
        textbutton "退出" action Quit(confirm=False)

# -------------------------------------------------------------
# 7. 剧情：走一遍上述所有定制
# -------------------------------------------------------------

label start:

    # 播放一段「静音」音乐（<silence 2.0> 是引擎内置的静音片段，无需素材）
    play music "<silence 2.0>"

    # 显示第 6 节定义的自定义快捷菜单
    show screen demo_quick_menu

    e "你好，欢迎来到第 15 章的示例。"

    "现在看到的对话框、角色名，都是由我们自己写的 screen say 与 style 画出来的。"

    "接下来是一段选项——它由自定义的 screen choice 重新排版。"

    menu:
        "你想怎样回应？"

        "回应一":
            e "你选择了「回应一」。"

        "回应二":
            e "你选择了「回应二」。"

    e "屏幕底部的按钮就是自定义快捷菜单，可以点「跳过」或「自动前进」试试。"

    "本示例到此结束。"

    # 收起快捷菜单，然后返回（游戏将回到主菜单）
    hide screen demo_quick_menu
    return
