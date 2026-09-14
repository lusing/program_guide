extends SceneTree

var elapsed := 0.0

func _initialize():
    print("开始循环模拟...")
    while elapsed < 2.0:
        print("elapsed = ", elapsed)
        elapsed += 0.5
    print("循环结束，已完成输入与帧循环的基础模拟。")
    quit()
