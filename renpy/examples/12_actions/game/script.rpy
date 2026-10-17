# ============================================================
# 12_actions —— 第 14 章「Screen 动作与数据绑定」示例工程
# 目标：一个屏幕里把常用动作演一遍，并演示变量 / 屏幕变量的绑定。
# 说明：本工程只有一个脚本文件，界面只用引擎内置显示部件搭出来。
# ============================================================


# ------------------------------------------------------------
# 1. 数据：default 语句在游戏开始时给变量一个初值
# ------------------------------------------------------------
default score = 0
default flag = False

image bg console = Solid("#0d1017")


# ------------------------------------------------------------
# 2. screen notify(message)：Notify() 动作和 renpy.notify() 的显示面板。
#    引擎内置的 renpy.notify 会去 show_screen("notify")，
#    本工程没有内置的 notify 屏幕，所以必须自己定义它，
#    否则运行时会报“屏幕不存在”。
# ------------------------------------------------------------
screen notify(message):
    zorder 100

    frame:
        background Solid("#101820")
        xpadding 24
        ypadding 12
        xalign 0.5
        yalign 0.08
        text "[message]" size 24 color "#ffe066"


# ------------------------------------------------------------
# 3. screen confirm(message, yes_action, no_action)：Confirm() 动作的确认框。
#    config.confirm_screen 默认为 True，只要定义了 confirm 屏幕，
#    引擎就会用它；yes_action / no_action 由 Confirm 动作传进来。
# ------------------------------------------------------------
screen confirm(message, yes_action, no_action):
    modal True
    zorder 200

    frame:
        background Solid("#20242e")
        xpadding 30
        ypadding 24
        xalign 0.5
        yalign 0.42

        vbox:
            spacing 18
            text "[message]" size 26 color "#f1f5f9"

            hbox:
                spacing 24
                textbutton "确定" action yes_action
                textbutton "取消" action no_action


# ------------------------------------------------------------
# 4. screen action_panel()：动作与数据绑定的主演示台
#    - 它用 call screen 显示，这样 Return / Jump / Call 才有明确效果；
#      脚本里会循环地再次调用它，所以可以反复进入、看到状态变化。
#    - 屏幕内用 default 声明两个“屏幕变量”，
#      供 SetScreenVariable / ToggleScreenVariable 修改；
#      全局变量 score / flag 则用 SetVariable / ToggleVariable 修改。
# ------------------------------------------------------------
screen action_panel():
    modal True
    zorder 50
    default count = 0
    default highlight = False

    frame:
        background Solid("#12161f")
        xpadding 30
        ypadding 24
        xalign 0.5
        yalign 0.5

        vbox:
            spacing 10

            text "动作与数据绑定演示台" size 30 color "#ffd166"
            text "全局变量 score = [score]，flag = [flag]" size 22 color "#cbd5e1"
            text "屏幕变量 count = [count]，highlight = [highlight]" size 22 color "#cbd5e1"

            # 4.1 操作全局变量的动作：SetVariable / ToggleVariable
            hbox:
                spacing 10
                textbutton "score +1" action SetVariable("score", score + 1)
                textbutton "score 归零" action SetVariable("score", 0)
                textbutton "切换 flag" action ToggleVariable("flag")

            # 4.2 操作屏幕变量的动作：SetScreenVariable / ToggleScreenVariable
            #     selected 表示“这个按钮是否处于选中态”，由表达式决定。
            hbox:
                spacing 10
                textbutton "count +1" action SetScreenVariable("count", count + 1)
                textbutton "切换 highlight" action ToggleScreenVariable("highlight")
                textbutton "已选中：highlight" selected highlight action NullAction()

            # 4.3 通知类动作：Notify 和 Function(renpy.notify, ...)
            #     sensitive 为假时按钮变灰、点不动，这里要求 score >= 2。
            hbox:
                spacing 10
                textbutton "Notify 通知" action Notify("这是一条 Notify 通知")
                textbutton "Function(renpy.notify)" action Function(renpy.notify, "这条来自 Function(renpy.notify, ...)")
                textbutton "score≥2 才可点" sensitive (score >= 2) action Notify("score 已经达到 2")

            # 4.4 流程类动作：If / Jump / Call
            hbox:
                spacing 10
                textbutton "If 分支（看 flag）" action If(flag, Jump("flag_end"), Notify("flag 为假，什么也不做"))
                textbutton "Call 子标签" action Call("sub_label")

            # 4.5 Confirm 动作：确认后才执行动作列表里的内容
            hbox:
                spacing 10
                textbutton "Confirm 重置分数" action Confirm("确定把 score 归零吗？", [SetVariable("score", 0)], Notify("已取消"))

            # 4.6 Return 动作：把值交回 call screen 的调用处
            hbox:
                spacing 10
                textbutton "再次进入面板" action Return("again")
                textbutton "结束演示" action Return("quit")


# ------------------------------------------------------------
# 5. 演示流程
# ------------------------------------------------------------
label start:

    scene bg console

    "（旁白）第 14 章示例：Screen 动作与数据绑定。"

    jump panel_loop


# 循环显示动作面板：Return("quit") 时才跳出循环。
label panel_loop:

    call screen action_panel
    $ result = _return

    if result == "quit":
        jump finish

    "（旁白）面板交回了 [result]，再进一次看看状态是否保留。"

    jump panel_loop


# If(flag, Jump("flag_end"), ...) 跳到这里。
label flag_end:

    "（旁白）flag 为真，If() 动作让我们 Jump 到了这个标签。"

    # 把 flag 关掉，方便跳回主循环继续演示。
    $ flag = False

    jump panel_loop


# Call("sub_label") 会在这个标签里跑一段，再回到面板。
label sub_label:

    "（旁白）Call() 动作在一个新上下文里执行了这个标签，然后自动回到面板。"

    return


# 收尾：用 renpy.call_screen() 再演示一次 Python 写法。
label finish:

    "（旁白）面板选择了“结束演示”，跳出循环。"

    $ final = renpy.call_screen("action_panel")

    "（旁白）renpy.call_screen 返回了 [final]，演示到此结束。"

    return
