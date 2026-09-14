define e = Character("Eileen")

default paused = False

label start:
    e "这是主线故事的开场。"
    call show_pause_menu
    return

label show_pause_menu:
    $ paused = True
    e "暂停菜单已准备好。"
    return
