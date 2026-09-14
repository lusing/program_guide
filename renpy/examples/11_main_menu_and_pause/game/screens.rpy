screen main_menu():
    tag menu
    modal True
    frame:
        xalign 0.5
        yalign 0.5
        vbox:
            spacing 20
            textbutton "开始游戏" action Start()
            textbutton "读取存档" action ShowMenu("load")
            textbutton "设置" action ShowMenu("preferences")
            textbutton "退出" action Quit(confirm=True)

screen pause_menu():
    tag menu
    modal True
    frame:
        xalign 0.5
        yalign 0.5
        vbox:
            spacing 20
            textbutton "继续" action Hide("pause_menu")
            textbutton "存档" action ShowMenu("save")
            textbutton "退出" action MainMenu()

screen preferences():
    tag menu
    frame:
        xalign 0.5
        yalign 0.5
        vbox:
            spacing 20
            text "音量"
            bar value Preference("music volume")
            text "文本速度"
            bar value Preference("text speed")
