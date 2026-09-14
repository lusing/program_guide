default player_name = "玩家"
default affection = 0
default route = "none"

label start:
    call chapter_one
    jump epilogue

label epilogue:
    if route == "forward":
        e "你选择了前进，命运的门被推开了。"
    elif route == "observe":
        e "你选择了观察，眼中的世界变得更清晰。"
    else:
        e "你还没有决定走向哪里。"
    return
