extends SceneTree

signal score_changed

func _initialize():
    connect("score_changed", _on_score_changed)
    emit_signal("score_changed", 120)
    print("信号发出后，回调已执行。")
    quit()

func _on_score_changed(value):
    print("新分数：", value)
