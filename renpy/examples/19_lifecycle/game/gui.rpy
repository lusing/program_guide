init offset = -2

# 关键只有一行：gui.init() 会顺带调用 layout.defaults()，
# 把内建的 main_menu 布局注册进 layout，主菜单才能被显示。
init python:
    gui.init(1280, 720)
