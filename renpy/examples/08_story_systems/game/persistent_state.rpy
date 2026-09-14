init python:
    if not hasattr(persistent, "best_score"):
        persistent.best_score = 0

label refresh_best_score:
    $ persistent.best_score = max(persistent.best_score, score)
    "当前最佳分数： [persistent.best_score]"
    return
