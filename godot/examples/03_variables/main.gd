extends SceneTree

const MAX_HP := 100

func _initialize():
    var score := 100
    var player_name := "Alice"
    var is_ready := true
    var hp_ratio := 0.75

    var level: int = 3
    level += 1

    print("player_name = ", player_name)
    print("score = ", score)
    print("is_ready = ", is_ready)
    print("hp_ratio = ", hp_ratio)
    print("level = ", level)
    print("MAX_HP = ", MAX_HP)

    # 两种字符串填充方式：% 格式化 与 String.format()（GDScript 4.7 无 {expr} 插值）
    print("玩家 {who} 的分数是 {pts}".format({"who": player_name, "pts": score}))
    print("%s 升到 %d 级" % [player_name, level])
    quit()
