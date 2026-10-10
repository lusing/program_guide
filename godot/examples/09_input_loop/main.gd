extends SceneTree

const PlayerScript := preload("res://player.gd")

func _initialize():
    var player: Node2D = PlayerScript.new()
    player.name = "Player"
    root.add_child(player)

    print("起点：", player.position)
    Input.action_press("ui_right")
    print("模拟按住右键 1 秒……")
    await create_timer(1.0).timeout
    print("按住后位置：", player.position)

    Input.action_release("ui_right")
    await create_timer(0.5).timeout
    print("松开后位置：", player.position)
    print("期间共处理帧数：", Engine.get_process_frames())
    quit()
