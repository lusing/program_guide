# =============================================================================
# 第 8 章配套示例：ATL 与 transform
# -----------------------------------------------------------------------------
# ATL 是 Animation and Transformation Language（动画与变换语言）的缩写。
# 本文件是一个“可运行的最小剧本”：画面只使用 Ren'Py 内置的可绘制对象
# （Solid / Text / Composite），不依赖任何图片或音频素材，方便逐行阅读。
# 请对照书中的小节，从上到下依次阅读每一段注释。
# =============================================================================


# -----------------------------------------------------------------------------
# 1. 被动画的对象：用内置可绘制对象代替美术资源
#    image 语句写在顶层（第 0 列），图像名会进入全局图像命名空间，
#    之后可以用 show / scene / at 等语句引用。
# -----------------------------------------------------------------------------
image box = Solid("#cc3333", xysize=(80, 80))
image marker = Solid("#33cc33", xysize=(40, 40))

# Composite(size, (x, y), child, ...)：把多个可绘制对象拼成一张图。
# 这里把一个红色方块和一段文字拼在一起，用来演示“更像图片”的对象。
image banner = Composite(
    (170, 80),
    (0, 0), Solid("#cc3333", xysize=(80, 80)),
    (92, 26), Text("ATL", color="#ffffff"),
)


# -----------------------------------------------------------------------------
# 2. 参数化 transform：可复用、可带参数
#    - 定义在顶层（第 0 列），任何 show / scene 都能通过 at 子句套用它；
#    - 参数写法类似 Python 函数，带默认值，调用时可以覆盖；
#    - 与“内联 ATL”不同，它可以被整个游戏反复复用。
#    ATL 语句自上而下依次执行，除非被 repeat / block 等改写流程。
# -----------------------------------------------------------------------------
transform drift(x=0, y=0, t=1.0):
    # xpos / ypos：以像素为单位，相对所在区域的左上角定位。
    xpos 0 ypos 0
    # linear：线性插值器（warper），在 t 秒内把属性平滑插值到目标值。
    linear t xpos x ypos y
    # ease：先慢、中间快、末尾慢的插值器，再把位置送回原点。
    ease t xpos 0 ypos 0
    # pause：单纯等待，不改变任何属性（“pause” 关键字可以省略）。
    pause 0.5
    # repeat：让所在 block 从头再来一遍；放在最后即为无限循环。
    repeat


# -----------------------------------------------------------------------------
# 3. 更多属性 + parallel：让多段动画同时进行
#    parallel: 的每个分支都独立并行；注意不要让两个分支修改同一属性，
#    否则结果不可预测。这里每个分支只负责一组属性。
# -----------------------------------------------------------------------------
transform showcase(t=1.0):
    # 起始状态：左上角、不透明、原始大小、不旋转。
    xalign 0.0 yalign 0.0
    alpha 1.0 zoom 1.0 rotate 0

    parallel:
        # 分支 A：只改水平位置，左右来回移动。
        linear t xalign 1.0
        linear t xalign 0.0

    parallel:
        # 分支 B：只改垂直位置，上下来回移动。
        linear t yalign 1.0
        linear t yalign 0.0

    parallel:
        # 分支 C：只改透明度，淡出再淡入。
        linear t alpha 0.2
        linear t alpha 1.0

    parallel:
        # 分支 D：缩放与旋转（两个不同的属性，可以放在同一个分支里）。
        zoom 1.0
        linear t zoom 1.6
        linear t zoom 1.0
        rotate 0
        linear t rotate 360


# -----------------------------------------------------------------------------
# 4. block: 把一组语句打包；配合 repeat <次数> 限定循环次数
#    repeat 必须位于所在 block 的最后一行。
# -----------------------------------------------------------------------------
transform blink(times=3):
    zoom 1.0
    block:
        linear 0.3 zoom 1.5
        linear 0.3 zoom 1.0
        repeat times   # 只重复 times 次；循环结束后继续执行 block 之后的语句
    # block 执行完后，可以用别的语句收尾。
    zoom 1.0
    pause 0.2
    repeat


# -----------------------------------------------------------------------------
# 5. on show / on hide：事件处理器
#    on 语句按事件名分支；它本身不会自然结束，由新的 show / hide 事件驱动。
# -----------------------------------------------------------------------------
transform appear:
    on show:
        # 被 show 时：从全透明淡入到不透明。
        alpha 0.0
        linear 0.6 alpha 1.0
    on hide:
        # 被 hide 时：从当前状态淡出到全透明。
        linear 0.6 alpha 0.0


# -----------------------------------------------------------------------------
# 6. 运行各个演示
#    transform 与“内联 ATL 块”的区别：
#      · transform 定义在顶层，可复用、可带参数（见 2、3、4、5）；
#      · 内联 ATL 块写在某一条 show 语句的缩进块里，只属于那一条语句，
#        无法带参数，也无法在别处复用（见 6.3）。
# -----------------------------------------------------------------------------
label start:

    scene black
    play music "<silence 2.0>"

    # 6.1 可复用的参数化 transform：用 at 子句套用
    "【1/5】先看 drift：它是一个带参数的顶层 transform。"
    show box at drift(200, 100, 2.0)
    "box 用 drift(200, 100, 2.0) 从原点移动到 (200,100)，再回到原点，然后循环。"

    # 6.2 同一份 transform，换一组参数即可复用
    hide box
    show marker at drift(600, 300, 1.5)
    "【2/5】换成 marker，只改调用参数就能复用同一份动画：drift(600, 300, 1.5)。"

    # 6.3 内联 ATL 块：写在 show 语句缩进块里的一次性动画
    #     注意：这里不能写成 at drift(...) 那样复用，动画只属于这一条 show 语句。
    scene black
    show marker:
        # 下面这段 ATL 内联块只作用于这一条 show 语句，别处无法复用。
        xalign 0.0 yalign 0.5
        linear 1.0 xalign 1.0
        linear 1.0 xalign 0.0
        repeat
    "【3/5】内联 ATL：动画直接写在 show 的缩进块里，一次性、不可复用。"

    # 6.4 多属性 + parallel：多段动画同时运行
    hide marker
    show banner at showcase(1.0)
    "【4/5】showcase：xalign / yalign / alpha / zoom / rotate 由 parallel 分支同时驱动。"

    # 6.5 block + repeat N：有限次循环
    hide banner
    show marker at blink(3)
    "【5/5】blink：block 把两条插值语句打包，repeat 3 让这个 block 只重复 3 次。"

    # 6.6 on show / on hide：由事件触发的淡入淡出
    hide marker
    show box at appear
    "再演示 on show / on hide：box 被 show 时执行 on show 分支，于是淡入。"
    hide box
    "刚刚 hide box 触发了 on hide 分支，box 因此淡出消失。"

    play music "<silence 2.0>"
    scene black
    "示例结束。请打开 game/script.rpy，对照书中第 8 章的小节逐个阅读这些 transform。"
    return
