define e = Character("Eileen")

default emotion = "neutral"

label start:
    e "你看着我，想知道我现在的情绪。"
    menu:
        "微笑":
            $ emotion = "happy"
        "沉默":
            $ emotion = "quiet"
        "生气":
            $ emotion = "angry"

    if emotion == "happy":
        e "我现在很开心。"
    elif emotion == "quiet":
        e "我今天不想说太多。"
    else:
        e "我有些生气，你最好注意一点。"
    return
