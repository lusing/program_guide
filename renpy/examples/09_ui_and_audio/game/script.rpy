define e = Character("Eileen")

default chapter = 1

default mood = "calm"

screen status_bar():
    zorder 100
    frame:
        xalign 0.02
        yalign 0.02
        vbox:
            text "章节：[chapter]"
            text "心情：[mood]"

label start:
    show screen status_bar
    scene black
    play music "audio/bgm/ambient.ogg" loop
    e "夜色降临，风声穿过窗台。"
    $ chapter = 2
    $ mood = "tense"
    e "场景切换成功，音乐与情绪也一起变了。"
    stop music
    return
