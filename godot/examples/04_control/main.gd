extends SceneTree

func _initialize():
    var value := 10
    if value > 5:
        print("value 大于 5")
    elif value == 5:
        print("value 等于 5")
    else:
        print("value 小于 5")

    for i in range(3):
        print("i = ", i)

    var inventory := ["剑", "盾", "药"]
    for item in inventory:
        print("携带：", item)

    var count := 0
    while count < 3:
        print("count = ", count)
        count += 1

    var state := "attack"
    match state:
        "idle":
            print("待机")
        "attack", "skill":
            print("进入攻击流程")
        _:
            print("未知状态")

    for e in range(10):
        if e == 3:
            continue
        if e == 6:
            break
        print("e = ", e)
    quit()
