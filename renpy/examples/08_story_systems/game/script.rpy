default score = 0
default route = "neutral"
default ending = "none"
default chapter = 1

label start:
    call intro_scene
    call choice_scene
    call determine_ending
    return

label intro_scene:
    "雨声越来越近。"
    "你站在门前，手中只有一枚旧钥匙。"
    return

label choice_scene:
    menu:
        "勇敢地推门":
            $ route = "brave"
            $ score += 4
        "先观察一会儿":
            $ route = "careful"
            $ score += 2
        "转身离开":
            $ route = "escape"
            $ score += 1

    if route == "brave":
        "你推开门，里面传来轻微的铃声。"
    elif route == "careful":
        "你停下脚步，仔细倾听，门后的气息似乎在呼唤你。"
    else:
        "你沉默地退后，门在背后缓缓合上。"
    return

label determine_ending:
    if route == "brave" and score >= 4:
        $ ending = "happy_end"
        "你走向光明，故事以温暖的结局收束。"
    elif route == "careful" and score >= 2:
        $ ending = "mystery_end"
        "你保留了观察和谨慎，得到了一个隐秘结局。"
    else:
        $ ending = "bad_end"
        "你离开了门前，故事像潮水一样退去。"
    return
