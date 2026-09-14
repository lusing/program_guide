label chapter_one:
    e "你醒来时，窗外的雨还在落下。"
    m "你终于来了。我们已经等了很久。"
    menu:
        "继续前进":
            $ route = "forward"
            $ affection += 1
        "停下观察":
            $ route = "observe"
            $ affection += 2

    if route == "forward":
        e "你决定继续前进，脚步比之前更加坚定。"
    else:
        e "你决定先停下观察，目光落在每一处细节上。"
    return
