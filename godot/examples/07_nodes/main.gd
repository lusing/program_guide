extends SceneTree

func _initialize():
    var player := Node2D.new()
    player.name = "Player"
    root.add_child(player)

    var hp_label := Label.new()
    hp_label.name = "HPLabel"
    player.add_child(hp_label)

    var sprite := Sprite2D.new()
    sprite.name = "Sprite"
    player.add_child(sprite)

    print("player 的父节点：", player.get_parent().name)
    print("player 子节点数：", player.get_child_count())
    print("hp_label 排第：", hp_label.get_index())
    print("按路径取节点：", root.get_node("Player/Sprite").name)
    print("player 是否已 ready：", player.is_node_ready())

    await process_frame
    print("player 路径：", player.get_path())
    print("hp_label 路径：", hp_label.get_path())

    _print_tree(root, 0)
    quit()

func _print_tree(node: Node, depth: int) -> void:
    print("  ".repeat(depth), node.name, " (", node.get_class(), ")")
    for child in node.get_children():
        _print_tree(child, depth + 1)
