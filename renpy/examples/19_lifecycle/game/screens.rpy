screen main_menu():

    tag menu

    add Solid("#1a1a2e")          # 纯色背景，代替背景图

    vbox:
        align (0.5, 0.35)
        spacing 20
        text "生命周期演示" xalign 0.5 size 48 color "#ffffff"

        # 你已打开主菜单的次数（由 before_main_menu 统计，见 script.rpy）
        text "主菜单打开次数：[persistent.menu_visits]" xalign 0.5 size 20 color "#aaaaff"

    vbox:
        align (0.5, 0.7)
        spacing 12

        textbutton "开始游戏" action Start()          # 第 21.5 节：跳出菜单上下文进 start
        textbutton "退出"     action Quit(confirm=False)   # 主菜单上直接退出，不再问

# -------------------------------------------------------------
# 对话与选项屏幕（第 11 章的 GUI 基础内容，此处给出完整可运行版本）
# -------------------------------------------------------------
# 说一句台词时，引擎会调用名为 say 的 screen，并把 who（角色名，
# 旁白时为 None）与 what（台词文本）作为参数传进来。
# 规范（doc/screen_special.html）要求：必须有一个 id 为 "what" 的 text，
# 可选 id 为 "who" 的 text 与 id 为 "window" 的窗口容器。

screen say(who, what):

    window id "window":
        has vbox

        if who:
            text who id "who"

        text what id "what"

style say_window:
    background Solid("#101020")
    xalign 0.5
    xfill True
    yalign 1.0
    ysize 220
    padding (40, 24)

style say_label:
    color "#ffd479"
    size 30
    xalign 0.02
    yalign 0.05

style say_dialogue:
    color "#ffffff"
    size 26
    xalign 0.02
    yalign 0.35

# menu 语句会用名为 choice 的 screen 显示游戏内选项。
# items 列表里每个元素都有 caption（选项文本）与 action（被选中时执行的动作）字段。
screen choice(items):

    vbox:
        align (0.5, 0.3)
        spacing 14

        for i in items:
            textbutton i.caption action i.action
