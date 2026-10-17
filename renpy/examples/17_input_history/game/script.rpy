# 第 19 章示例：玩家输入、对话历史与通知
#
# 本示例演示三件事：
#   （一）renpy.input 的常用参数：length / default / allow / exclude；
#   （二）renpy.notify 的瞬时通知；
#   （三）自定义对话历史界面（遍历 _history_list）。
#
# 说明：本版本（Ren'Py 8.5.3）没有 renpy.get_history() 这个函数，
# 对话历史统一通过 store 中的 _history_list 列表访问。
# 列表里每个元素是 character.HistoryEntry，常用字段是 who 与 what。

# ── 1. 配置与变量 ───────────────────────────────────────────────

# 开启对话历史：历史最多保留 250 条记录。
# 该变量在 renpy/config.py 中定义，默认值是 None，也就是不记录历史。
define config.history_length = 250

# 主角名字，默认值。玩家输入后会被覆盖。
default player_name = "无名氏"

# 英文代号，用来演示 default= 预填与 allow= 限定字符。
default nickname = "Hero"

# ── 2. 自定义对话历史界面 ───────────────────────────────────────

# 引擎没有内置的历史界面，这里自己写一个。
screen history():

    # modal 表示界面打开时，点击它以外的地方不会传到剧情里。
    modal True

    # 半透明遮罩。
    add Solid("#000000cc")

    frame:
        align (0.5, 0.5)
        xsize 820
        ysize 600
        background Solid("#1a1a2e")
        padding (30, 24)

        vbox:
            spacing 14

            text "对话历史" size 30

            # 用 viewport 承载可能很长的历史列表。
            viewport:
                ysize 440
                mousewheel True
                draggable True
                scrollbars None

                vbox:
                    spacing 10

                    # 倒序遍历，最新的对话显示在最上面。
                    # 每条记录用 who（说话人）与 what（内容）两个字段。
                    for h in reversed(_history_list):
                        vbox:
                            spacing 2

                            # 旁白没有 who，所以要先判断。
                            if h.who:
                                text "[h.who]" color "#7fd1ff" size 20

                            text "[h.what]" size 22

            textbutton "关闭（Esc）" action Hide("history")

    # 按 Esc 或右键也能关闭。
    key "game_menu" action Hide("history")

# 一个常驻的小按钮，让历史界面随时可见、可打开。
screen history_button():
    zorder 100

    textbutton "历史" align (0.98, 0.02) action Show("history")

    # H 键也能打开历史界面。
    key "h" action Show("history")

# ── 3. 剧情 ────────────────────────────────────────────────────

# 一个带名字的角色，方便在历史里看到 who 字段。
define guide = Character("向导")

label start:

    scene black

    "欢迎来到第 19 章的示例：玩家输入、对话历史与通知。"

    # 把常驻按钮挂出来。
    show screen history_button

    "右上角有一个「历史」按钮，也可以按键盘的 H 键打开对话历史。"

    # （一）renpy.input 基本用法：length 限制长度，exclude 排除字符。
    guide "先请你输入名字，最多 8 个字符，且不能包含 < > | / 这些符号。"

    $ player_name = renpy.input("你叫什么名字？", length=8, exclude="<>|/").strip()

    # 如果没有输入内容，就沿用默认值。
    if player_name == "":
        $ player_name = "无名氏"

    guide "你好，[player_name]！名字已经保存到变量 player_name 里了。"

    # （二）renpy.input 的 default 预填与 allow 限定字符集。
    guide "接下来输入一个英文代号，输入框里已经预填了默认文本。"

    $ nickname = renpy.input("你的代号是？", default="Hero", allow="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", length=12).strip()

    if nickname == "":
        $ nickname = "Hero"

    guide "代号已保存为 [nickname]。"

    # （三）renpy.notify：瞬时通知，不会阻塞剧情。
    #
    # renpy.notify 会调用引擎内置的 notify 界面，显示一小段文字，
    # 大约 3 秒后自动消失，期间剧情不需要玩家点击就能继续。
    $ renpy.notify("已记录你的名字：%s" % player_name)

    guide "注意屏幕一角刚才出现的提示：renpy.notify 不会阻塞剧本。"

    # 多聊几句，好让历史记录里有点内容。
    guide "第一句：下面这几句话都会被写进对话历史。"
    guide "第二句：自定义的历史界面会按顺序把它们列出来。"
    guide "第三句：每条记录都包含 who 与 what 两个字段。"
    guide "第四句：旁白（没有名字的行）的 who 字段是空的。"

    "现在打开历史界面看看效果：点右上角按钮，或者按 H 键。"

    "关闭历史界面可以用里面的按钮，也可以按 Esc 或右键。"

    "示例到此结束，感谢阅读。"

    return
