define e = Character("Eileen")

default route = "normal"

label start:
    menu:
        "选择勇敢路线":
            $ route = "brave"
        "选择谨慎路线":
            $ route = "careful"
    e "你选择了 [route] 路线。"
    return
