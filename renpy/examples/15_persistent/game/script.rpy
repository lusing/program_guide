# =============================================================
# 第 17 章 示例工程 15：持久化数据（persistent）
# -------------------------------------------------------------
# 本工程演示 persistent 数据：
#   - default persistent.play_count / best_score / endings
#   - 每次「开始游戏」累加 play_count，并据此解锁额外内容
#   - 往 persistent 列表里写入结局 id，并在后续游玩中解锁
#   - renpy.save_persistent() 手动落盘
#
# 关键区别：
#   persistent 数据跨越「重开游戏 / 新游戏 / 换一份存档」一直存在，
#   而 default 变量只属于「当前这一次游玩」，新游戏会重置。
#
# 本工程只有 game/script.rpy 一个文件，不使用任何 gui.* 变量与素材。
# =============================================================

# -------------------------------------------------------------
# 1. persistent 默认值
# -------------------------------------------------------------
# 用 default persistent.xxx = ... 声明持久变量的初始值。
# 这些值只在「首次」没有该值时生效；之后会一直沿用磁盘里的旧值。

default persistent.play_count = 0
default persistent.best_score = 0
default persistent.endings = []      # 一个列表，用来累积已看过的结局

define narrator = Character(None, what_style="say_dialogue")
define e = Character("系统", who_style="say_label", what_style="say_dialogue")

# -------------------------------------------------------------
# 2. 剧情
# -------------------------------------------------------------

label start:

    "第 17 章示例：持久化数据 persistent。"

    # ------ 累加 play_count ------
    # 每进入一次 start（也就是每开一局新游戏），计数 +1。
    # 这个数字会一直保留到下一次启动游戏之后。
    $ persistent.play_count += 1

    e "这是你的第 [persistent.play_count] 次游玩。"

    if persistent.play_count > 1:
        # 只有当不是第一次游玩时才会出现这段对话——这就是「解锁」
        e "看起来你又回来了。老朋友，欢迎。"
        "（这段额外对话只有在 persistent.play_count > 1 时才会显示。）"
    else:
        "（这是你第一次游玩，所以上面那段额外对话没有出现。）"

    # ------ 展示已解锁的结局 ------
    python:
        endings_text = "、".join(persistent.endings) if persistent.endings else "（还没有任何结局）"
    "目前你已解锁的结局：[endings_text]"

    if "good" in persistent.endings:
        e "你已经解锁过「真结局」，这次给你一点小奖励分数。"
        $ persistent.best_score = max(persistent.best_score, 100)
    else:
        "（还没有解锁「真结局」。）"

    # ------ 选择一个结局，写入 persistent 列表 ------
    menu:
        "这次想走哪个结局？"

        "真结局（good）":
            # 往持久列表里写入结局 id；下次游玩就能读到它
            $ persistent.endings.append("good")
            $ persistent.best_score = max(persistent.best_score, 120)
            e "记录已写入 persistent.endings。"

        "普通结局（normal）":
            $ persistent.endings.append("normal")
            e "记录已写入 persistent.endings。"

    "这次结束后，persistent.endings = [persistent.endings]，best_score = [persistent.best_score]。"

    # ------ 手动落盘 ------
    # persistent 数据在退出游戏时会自动写盘；
    # renpy.save_persistent() 用于「立刻」手动写盘（例如你希望马上生效时）。
    $ renpy.save_persistent()
    "已调用 renpy.save_persistent()：persistent 数据立刻写入了磁盘。"

    "重启游戏或开新档后再来，本次的 play_count 与 endings 依然会保留。"

    "本示例到此结束。"
    return
