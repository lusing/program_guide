# ============================================================
# 09_transitions —— 第 11 章「转场」示例工程
# 目标：把 with 语句和几种内置转场跑给你看。
# 说明：本工程只有一个脚本文件，不用任何图片 / 音频素材，
#       所有画面都由引擎内置显示部件（Solid / Composite / Text）拼出来。
# ============================================================


# ------------------------------------------------------------
# 1. 画面素材：只用引擎内置显示部件
# ------------------------------------------------------------
# Solid("#色值") 会填满分配给它的区域，当作整屏背景正合适。
image bg hall = Solid("#1b2a41")
image bg garden = Solid("#243b1f")

# Composite(尺寸, (x, y), 显示部件, ...) 把若干部件按坐标叠在一起，当作“角色”。
image hero = Composite(
    (320, 420),
    (0, 0), Solid("#6c63ff", xysize=(320, 420)),
    (90, 40), Text("HERO", size=44, color="#ffffff"),
)

image guest = Composite(
    (260, 340),
    (0, 0), Solid("#ff6f91", xysize=(260, 340)),
    (52, 30), Text("GUEST", size=34, color="#ffffff"),
)


# ------------------------------------------------------------
# 2. 自定义转场：在 init 阶段用 define 定义一次，脚本里随时复用
# ------------------------------------------------------------
# 2.1 Dissolve(时间)：把旧画面溶解成新画面。
define slow_dissolve = Dissolve(1.5)

# 2.2 Fade(淡出时间, 停留时间, 淡入时间)：先淡到纯色，停留一下，再淡回画面。
define slow_fade = Fade(0.3, 0.2, 0.3)

# 2.3 MoveTransition(delay, enter=...)：让“新出现”的部件从屏幕外滑入。
#     enter 只接收一个“静态位置”transform，这里用引擎内置的 offscreenleft
#     （把部件放到屏幕左侧之外）。注意：MoveTransition 只能配合 with 语句
#     作用在图层上，不能放进 ATL 或 ComposeTransition 里。
define slide_move = MoveTransition(1.0, enter=offscreenleft)


# ------------------------------------------------------------
# 3. 正式演出：逐条演示 with 语句与各种转场
# ------------------------------------------------------------
label start:

    # 3.0 本工程不带音频文件，用静音片段演示一下音频通道（播放 2 秒静音）。
    play music "<silence 2.0>"

    # 3.1 with fade：引擎预定义转场，0.5 秒渐黑 + 0.5 秒渐出。
    #     它比较的是“上一屏画面”和“下面 show / scene 后的新画面”。
    scene bg hall
    with fade

    "（旁白）第 11 章示例：转场。"

    # 3.2 with dissolve：引擎预定义转场，0.5 秒溶解。
    #     with 语句单独写一行时，作用于“上一句之后的全部 show / hide / scene 变化”。
    show hero at left
    with dissolve

    "（旁白）这一屏用了 dissolve 出现。"

    # 3.3 show 自带的 with 子句：写在同一行，等价于
    #     “先 with None，再 show，最后 with 这个转场”。
    #     这里用显式构造出来的 Dissolve(1.5)，让溶解慢下来。
    show guest at right with Dissolve(1.5)

    "（旁白）guest 是用 show ... with Dissolve(1.5) 出现的，转场只影响这一行。"

    # 3.4 先用 with None 取消隐式转场，再连续写两个 show，
    #     最后只 with 一次 —— 于是两次变化被合并成一次 dissolve。
    with None
    show hero at center
    show guest at left
    with dissolve

    "（旁白）with None 先把变化攒起来，最后一次 dissolve 统一过渡。"

    # 3.5 复用第 2 节 define 出来的自定义转场。
    show guest at right
    with slow_dissolve

    "（旁白）slow_dissolve 就等于 Dissolve(1.5)。"

    # 3.6 with slow_fade：这次画面本身没变化，所以效果是“淡黑、停留、再淡回”。
    with slow_fade

    "（旁白）slow_fade 就是 Fade(0.3, 0.2, 0.3)：淡黑 → 停 0.2 秒 → 淡回。"

    # 3.7 with Pause(秒)：只等待，不改变画面，用来给玩家一个节拍。
    with Pause(0.5)

    "（旁白）刚才用了 0.5 秒的停顿。"

    # 3.8 MoveTransition：hero 从左边移动到右边，
    #     同一个 tag 的位置变化会被平滑插值，而不是瞬移。
    show hero at right
    with slide_move

    "（旁白）hero 用 MoveTransition 平滑地滑到了右边。"

    # 3.9 scene 也能带 with 子句：换背景并顺手做一次 fade。
    scene bg garden with fade

    "（旁白）scene 同样支持 with 子句。"

    # 3.10 with None：不做任何转场，立刻生效。
    with None
    show guest at center with None

    "（旁白）with None 表示“不转场、立刻生效”。"

    # 3.11 收尾
    stop music
    "（旁白）演示结束，感谢观看。"

    return
