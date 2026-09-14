define e = Character("Eileen")

label start:
    e "你可以继续前进，或者停下观察。"
    menu:
        "继续前进":
            jump adventure
        "停下观察":
            jump careful

label adventure:
    e "你决定继续前进。"
    return

label careful:
    e "你选择谨慎观察。"
    return
