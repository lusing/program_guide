extends SceneTree

signal score_changed(new_score: int)
signal item_picked(item: String, count: int)

func _initialize():
    score_changed.connect(_on_score_changed)
    item_picked.connect(func(item: String, count: int):
        print("拾取 %s x%d" % [item, count]))

    score_changed.emit(120)
    item_picked.emit("金币", 3)

    print("是否仍连接：", score_changed.is_connected(_on_score_changed))
    score_changed.disconnect(_on_score_changed)
    print("断开后再 emit，_on_score_changed 不会再执行：")
    score_changed.emit(999)
    quit()

func _on_score_changed(value: int) -> void:
    print("新分数：", value)
