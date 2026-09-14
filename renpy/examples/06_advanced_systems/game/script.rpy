define e = Character("Eileen")

default health = 75

default chapter_name = "第一章"

default route = "normal"

init python:
    if not hasattr(persistent, "best_score"):
        persistent.best_score = 0

screen status():
    zorder 100
    frame:
        xalign 0.02
        yalign 0.02
        vbox:
            text "生命值: [health]"
            text "章节: [chapter_name]"
            text "最高分: [persistent.best_score]"

label start:
    show screen status
    e "欢迎来到 Ren'Py 进阶篇。"
    e "这一段展示了状态、HUD 和持久化数据。"
    $ health = 90
    $ chapter_name = "第二章"
    $ persistent.best_score = max(persistent.best_score, health)
    e "你的生命值提升到了 [health]。"
    menu:
        "继续故事":
            $ route = "continue"
            jump continue_story
        "保存并结束":
            $ route = "save_and_end"
            $ renpy.save_persistent()
            jump end

label continue_story:
    e "你选择了继续剧情，状态已保留。"
    e "当前路线：[route]"
    jump end

label end:
    hide screen status
    e "进阶示例结束。"
    return
