extends SceneTree

func _initialize():
    print("倒计时开始")
    for i in range(3, 0, -1):
        print(i, "……")
        await create_timer(0.5).timeout
    print("发射！")

    var timer := create_timer(0.3)
    print("先做点别的，稍后再等这个计时器……")
    await timer.timeout
    print("0.3 秒计时器到期")

    quit()
