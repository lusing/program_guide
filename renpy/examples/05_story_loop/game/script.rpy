define e = Character("Eileen")

default chapter = 1

label start:
    e "第 [chapter] 章开始。"
    menu:
        "继续故事":
            $ chapter += 1
            jump start
        "结束故事":
            e "故事到此结束。"
            return
