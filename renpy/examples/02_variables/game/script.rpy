define e = Character("Eileen")

default trust = 0

label start:
    e "欢迎来到 Ren'Py。"
    $ trust += 1
    e "你的信任值现在是 [trust]。"
    return
