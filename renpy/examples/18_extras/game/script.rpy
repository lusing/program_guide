# 第 20 章示例：画廊、音乐室与剧情回放
#
# 本示例演示三件事：
#   （一）Gallery（画廊）：解锁并浏览已看过的图片；
#   （二）MusicRoom（音乐室）：逐个播放已解锁的曲目；
#   （三）剧情回放：Replay 动作与 renpy.call_replay。
#
# 引擎本身不提供现成的画廊 / 音乐室界面，所以三个界面都在这里自己写。

# ── 1. 定义画廊素材 ────────────────────────────────────────────

# 为了不依赖任何图片文件，用引擎内置的 Solid 当作「图片」。
image gal_1 = Solid("#334455")
image gal_2 = Solid("#aa5533")
image gal_3 = Solid("#559922")

# 一个带名字的角色，方便对话更自然。
define guide = Character("向导")

# ── 2. 创建画廊对象 ────────────────────────────────────────────

init python:

    # Gallery() 的参数与用法见 renpy/common/00gallery.rpy。
    g = Gallery()

    # 浏览图片时的转场。
    g.transition = Dissolve(0.4)

    # navigation 打开后，浏览图片时会出现上一张 / 下一张等按钮
    # （由引擎内置的 gallery_navigation 界面提供）。
    g.navigation = True

    # 第一个按钮：只有看过 gal_1 之后才解锁。
    g.button("btn_1")
    g.image("gal_1")
    g.unlock("gal_1")

    # 第二个按钮：用 condition 给它一个恒为真的条件，所以始终解锁。
    g.button("btn_2")
    g.image("gal_2")
    g.condition("True")

    # 第三个按钮：看过 gal_3 之后解锁。
    g.button("btn_3")
    g.image("gal_3")
    g.unlock("gal_3")

# ── 3. 创建音乐室对象 ──────────────────────────────────────────

init python:

    # MusicRoom() 的参数与用法见 renpy/common/00musicroom.rpy。
    mr = MusicRoom(channel="music", loop=True, fadein=0.5, fadeout=0.5)

    # 加入两段静音音频，避免依赖真实音乐文件。
    # always_unlocked=True 表示一开始就解锁；否则要听过才算解锁。
    mr.add("<silence 2.0>", always_unlocked=True)
    mr.add("<silence 3.0>")

# ── 4. 三个自定义界面 ──────────────────────────────────────────

screen gallery():
    modal True
    add Solid("#000000d0")

    frame:
        align (0.5, 0.5)
        xsize 660
        ysize 500
        background Solid("#20203a")
        padding (30, 24)

        vbox:
            spacing 18
            xalign 0.5

            text "画廊" size 30
            text "锁定的按钮无法点击，需要先在剧情里看过对应图片。" size 20

            # g.Action 在按钮未解锁时会返回 None，对应的按钮就是不可点的。
            textbutton "图片一（看过才解锁）" action g.Action("btn_1")
            textbutton "图片二（始终解锁）" action g.Action("btn_2")
            textbutton "图片三（看过才解锁）" action g.Action("btn_3")

            textbutton "返回" action Hide("gallery")

    key "game_menu" action Hide("gallery")

screen music_room():
    modal True
    add Solid("#000000d0")

    frame:
        align (0.5, 0.5)
        xsize 660
        ysize 520
        background Solid("#1c2a1c")
        padding (30, 24)

        vbox:
            spacing 12
            xalign 0.5

            text "音乐室" size 30
            text "未解锁的曲目按钮是灰的，这演示了音乐室的锁定机制。" size 20

            textbutton "播放曲目一" action mr.Play("<silence 2.0>")
            textbutton "播放曲目二（未解锁）" action mr.Play("<silence 3.0>")
            textbutton "暂停 / 继续" action mr.TogglePause()
            textbutton "切换循环" action mr.ToggleLoop()
            textbutton "下一首" action mr.Next()
            textbutton "上一首" action mr.Previous()
            textbutton "停止" action mr.Stop()

            textbutton "返回" action Hide("music_room")

    key "game_menu" action Hide("music_room")

screen extras_hub():
    modal True
    add Solid("#000000c0")

    frame:
        align (0.5, 0.5)
        background Solid("#101028")
        padding (50, 40)

        vbox:
            spacing 22
            xalign 0.5

            text "额外内容" size 34

            textbutton "打开画廊" action Show("gallery")
            textbutton "打开音乐室" action Show("music_room")
            textbutton "回放「经典场景」" action Replay("replay_label", locked=False)
            textbutton "继续剧情" action Return()

# ── 5. 可回放的剧情标签 ────────────────────────────────────────

# 被回放时，这个标签在独立的上下文中运行，最后要用 renpy.end_replay() 结束。
label replay_label:

    scene gal_3

    guide "（回放）这是一段被反复回放的经典场景。"

    guide "（回放）回放结束后，会自动回到刚才打开额外内容菜单的地方。"

    # 结束回放。renpy.end_replay() 只能用在回放里，普通剧情中调用它没有效果。
    $ renpy.end_replay()

    return

# ── 6. 主剧情 ──────────────────────────────────────────────────

label start:

    scene black

    "欢迎来到第 20 章的示例：画廊、音乐室与剧情回放。"

    # 先在剧情里展示图片，让引擎把它们记成「已见过」，这样画廊才会解锁。
    show gal_1
    guide "这是第一张图，看过之后它才会出现在画廊里。"
    show gal_2
    guide "这是第二张图，它的画廊按钮用的是恒真条件。"
    hide gal_1
    hide gal_2
    show gal_3
    guide "这是第三张图。"
    hide gal_3

    # 播放一小段静音音乐，让引擎把它记成「听过的音频」。
    play music "<silence 2.0>"
    guide "刚才播放的是一段静音音乐（音频占位）。"

    # 打开额外内容菜单。这里用 call screen，界面会阻塞剧情直到返回。
    "下面打开额外内容菜单，里面有画廊 / 音乐室 / 回放三个入口。"
    call screen extras_hub

    # 剧情回放也可以直接在脚本里触发。
    "也可以在脚本里用 $ renpy.call_replay(\"replay_label\") 直接触发回放。"

    $ renpy.call_replay("replay_label")

    "回放结束，已经回到正常的剧情流程。"

    "示例到此结束，感谢阅读。"

    return
