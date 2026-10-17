# ============================================================
# 11_screens —— 第 13 章「Screen 语言基础」示例工程
# 目标：从零搭几个自定义 screen，并在脚本里用 show screen / call screen 调用。
# 说明：本工程只有一个脚本文件，所有界面都用引擎内置显示部件
#       （Solid / Frame / Frame 里的 frame/vbox/hbox/text/textbutton/viewport）搭出来。
# ============================================================


# ------------------------------------------------------------
# 1. 数据与背景
#    default 语句也是顶层语句，在游戏开始（不是 init）时给变量一个初值。
# ------------------------------------------------------------
default hp = 100
default mp = 40
default answer = None
default answer2 = None
default skills = [
    "斩击", "突刺", "横斩", "格挡", "闪避", "火球术",
    "冰霜箭", "治疗术", "疾风步", "铁壁", "连击", "终结技",
]

image bg dark = Solid("#0d1017")


# ------------------------------------------------------------
# 2. screen stat_row：最小的“可复用屏幕”
#    - 屏幕参数写在 screen 名字后面的括号里
#    - 反复被别的屏幕 use 的时候就“当作一个积木”用
# ------------------------------------------------------------
screen stat_row(name, value, tone="#cbd5e1"):
    hbox:
        spacing 14
        text "[name]：" size 22 color "#9fb3c8" min_width 96
        text "[value]" size 22 color tone


# ------------------------------------------------------------
# 3. screen status_panel(title)：状态面板
#    - zorder 10：同屏多个屏幕时，数值越大越靠前
#    - 屏幕会在“每次交互开始时”重新求值，所以改了 hp 之后自动刷新
#    - 用 use stat_row(...) 带参数复用第 2 节的小屏幕
# ------------------------------------------------------------
screen status_panel(title):
    zorder 10

    frame:
        background Solid("#151b28")
        xpadding 24
        ypadding 18
        xalign 0.02
        yalign 0.04

        vbox:
            spacing 8
            text "[title]" size 26 color "#ffd166"
            use stat_row("生命值", hp, "#ef476f")
            use stat_row("魔法值", mp, "#118ab2")


# ------------------------------------------------------------
# 4. screen confirm_box(message)：一个会“返回值”的屏幕
#    - Return(True) / Return(False) 把结果交给调用方
#    - 用 call screen 或 renpy.call_screen 调用后，结果放在 _return 里
# ------------------------------------------------------------
screen confirm_box(message="确定吗？"):
    modal True
    zorder 200

    frame:
        background Solid("#20242e")
        xpadding 30
        ypadding 24
        xalign 0.5
        yalign 0.45

        vbox:
            spacing 18
            text "[message]" size 26 color "#f1f5f9"

            hbox:
                spacing 24
                textbutton "确定" action Return(True)
                textbutton "取消" action Return(False)


# ------------------------------------------------------------
# 5. screen skill_list()：viewport + 垂直滚动条
#    - scrollbars "vertical" 会自动给 viewport 右侧加一条滚动条
#    - 用 SetScreenVariable 把玩家的选择记在“屏幕变量”里
# ------------------------------------------------------------
screen skill_list():
    zorder 20
    default chosen = "（还没选）"

    frame:
        background Solid("#101725")
        xpadding 22
        ypadding 18
        xalign 0.5
        yalign 0.5

        vbox:
            spacing 10
            text "技能列表（当前选择：[chosen]）" size 24 color "#ffd166"

            viewport:
                xysize (520, 300)
                scrollbars "vertical"
                mousewheel True
                draggable True

                vbox:
                    spacing 6
                    for i, s in enumerate(skills):
                        textbutton "[s]" action SetScreenVariable("chosen", s)


# ------------------------------------------------------------
# 6. 在脚本里使用这些屏幕
# ------------------------------------------------------------
label start:

    scene bg dark

    # 6.1 show screen：把屏幕显示出来，参数直接写在括号里。
    show screen status_panel("冒险者状态")

    "（旁白）第 13 章示例：Screen 语言基础。"

    # 6.2 改全局变量后，屏幕不会立刻重画；
    #     但只要发生一次交互（比如 with Pause），它就会重新求值并刷新。
    $ hp = 68
    $ mp = 25
    with Pause(0.5)

    "（旁白）hp 改成了 [hp]、mp 改成了 [mp]，停顿那一下面板就刷新了。"

    # 6.3 show screen / hide screen：屏幕可以随时显示、隐藏。
    #     skill_list 的 zorder 是 20，会盖在状态面板（zorder 10）前面。
    show screen skill_list

    "（旁白）中间是带垂直滚动条的 viewport，可以用滚轮或拖动来翻。"

    hide screen skill_list

    # 6.4 call screen：屏幕用 Return(...) 交回结果，结果放在 _return 变量里。
    call screen confirm_box("确定要继续吗？")
    $ answer = _return

    "（旁白）confirm_box 交回了 [answer]。"

    # 6.5 renpy.call_screen()：脚本里的 Python 写法，返回值直接拿到手里。
    $ answer2 = renpy.call_screen("confirm_box", "再确认一次？")

    "（旁白）renpy.call_screen 交回了 [answer2]。"

    hide screen status_panel

    "（旁白）演示结束，感谢观看。"

    return
