# =============================================================
# 第 18 章 多文件工程示例：script.rpy
# -------------------------------------------------------------
# 本文件是「剧情脚本」，演示 Python 语句与引擎 API。
# 与之配套的还有：
#   game/options.rpy    —— 全局配置
#   game/characters.rpy —— 角色与初始化数据
#
# 说明：game/ 目录里的所有 .rpy 文件会在编译时被合并。
# 因此对运行时来说，「多文件工程」与「单文件工程」完全一样，
# 拆分只是为了可读性与可维护性。
# =============================================================

# -------------------------------------------------------------
# 1. init python：启动时执行一次的初始化代码
# -------------------------------------------------------------

init python:
    # 由 init python 准备好的问候语，供下面的剧情使用。
    demo_greeting = "（这句问候语来自 init python 块）"

# -------------------------------------------------------------
# 2. 一个自定义 screen，用来演示 renpy.show_screen / renpy.get_screen
# -------------------------------------------------------------

screen demo_badge(who):
    zorder 100
    frame:
        xalign 0.5
        yalign 0.1
        background Solid("#203050")
        padding (24, 12)
        text "欢迎，[who]！" color "#ffffff" size 28

# -------------------------------------------------------------
# 3. 剧情：演示各种 Python 语句与引擎 API
# -------------------------------------------------------------

label start:

    # ------ 3.1 引擎 API：播放静音音乐 ------
    # renpy.music.play 接收一个文件；"<silence 2.0>" 是引擎内置的静音片段。
    $ renpy.music.play("<silence 2.0>")

    # 通知气泡：renpy.notify 会显示一条短暂的提示
    $ renpy.notify("演示开始")

    "多文件工程示例：内容分布在 options.rpy、characters.rpy、script.rpy 三个文件里。"

    mc "这三个文件在编译时会被合并，运行时和单文件工程没有任何区别。"

    mc "[demo_greeting]"

    # ------ 3.2 python: 块 ------
    # python: 块里可以书写任意 Python 代码，并访问游戏变量。
    python:
        # 调用 characters.rpy 里定义的辅助函数，随机抽一条属性
        picked = random_stat()
        # renpy.random.choice 也可以直接在脚本里使用
        lucky = renpy.random.choice(["上上签", "上签", "中签"])

    mc "随机抽到的属性是「[picked]」，今日运势是「[lucky]」。"

    # ------ 3.3 引擎 API：renpy.say ------
    # renpy.say 与普通的对话语句等价，这里用 Python 直接调用它。
    $ renpy.say(mentor, "我是通过 renpy.say(...) 说出的这句台词。")

    # ------ 3.4 引擎 API：renpy.input ------
    # renpy.input 弹出输入框并返回玩家输入的文字。
    python:
        name = renpy.input("请输入你的名字：", default="无名氏")
        name = name.strip() or "无名氏"

    mc "你好，[name]。"

    # ------ 3.5 引擎 API：show_screen / get_screen ------
    # 显示刚才定义的 demo_badge 屏幕，再用 renpy.get_screen 确认它存在。
    $ renpy.show_screen("demo_badge", who=name)
    $ badge_on = renpy.get_screen("demo_badge") is not None
    "横幅是否已显示：renpy.get_screen(\"demo_badge\") 返回非 None = [badge_on]。"
    $ renpy.hide_screen("demo_badge")

    "本示例到此结束。"
    return
