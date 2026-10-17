# ============================================================
# 10_layeredimage —— 第 12 章「Layered Images」示例工程
# 目标：不用一张美术图，纯靠引擎内置显示部件拼出一个可分层的角色，
#       并演示用属性切换它的服装和表情。
# 说明：本工程只有一个脚本文件，画面全部由
#       Solid / Composite / Transform / Text 拼出来。
# ============================================================


# ------------------------------------------------------------
# 1. 背景：一个纯色底，让角色不至于漂在黑屏上
# ------------------------------------------------------------
image bg studio = Solid("#141821")


# ------------------------------------------------------------
# 2. layeredimage 定义
#    layeredimage 语句本身是“顶层语句”，在 init 阶段执行一次；
#    它内部只认识 always / attribute / group / if / when 这几种子语句。
# ------------------------------------------------------------
layeredimage eileen:

    # 2.1 always：不绑定任何属性的图层，永远显示。
    #     这里用它拼出人物“身体底色”，并用 xysize 固定成 300x460，
    #     这样后面的图层才有统一的尺寸可以对齐。
    always:
        Solid("#f2c9a0", xysize=(300, 460))

    # 2.2 group outfit：同一个 group 里的属性是“互斥”的，
    #     同一时刻只能显示其中一个。
    #     attribute casual default 里的 default 表示：
    #     只要没人显式点 outfit 组的属性，就显示 casual。
    group outfit:
        attribute casual default:
            Composite(
                (300, 460),
                (0, 300), Solid("#4a90d9", xysize=(300, 160)),
                (16, 336), Text("CASUAL", size=30, color="#ffffff"),
            )
        attribute formal:
            Composite(
                (300, 460),
                (0, 300), Solid("#33334d", xysize=(300, 160)),
                (16, 336), Text("FORMAL", size=30, color="#ffffff"),
            )

    # 2.3 group face：表情组，happy 是默认表情。
    #     这里用 Transform(Text(...)) 摆出两张不需要美术资源、
    #     但肉眼能一眼区分的“脸”。
    group face:
        attribute happy default:
            Transform(Text("^.^", size=54, color="#2b2b2b"), xpos=70, ypos=40)
        attribute sad:
            Transform(Text("T_T", size=54, color="#2b2b2b"), xpos=80, ypos=40)

    # 2.4 写在 layeredimage 块里的 transform 属性，
    #     会成为作用于整张图层图的一个 transform。
    #     这里让它贴着画面左下角显示。
    xpos 0.02
    yalign 0.98


# ------------------------------------------------------------
# 3. 在脚本里切换属性
# ------------------------------------------------------------
label start:

    scene bg studio

    # 3.1 不写任何属性：各 group 都使用自己的 default 属性，
    #     于是显示 casual（服装）+ happy（表情）。
    show eileen

    "（旁白）什么都不写时，eileen 显示默认的 casual + happy。"

    # 3.2 指定 outfit 组的另一个属性：formal 替换 casual，
    #     face 组没被提到，所以保持原来的默认表情。
    show eileen formal

    "（旁白）show eileen formal：只换服装，表情不动。"

    # 3.3 指定 face 组的 sad：表情换成 sad，
    #     outfit 组仍是上一步的 formal。
    show eileen sad

    "（旁白）show eileen sad：只换表情，服装还在。"

    # 3.4 减号语法 -formal：把 formal 从属性集合里“移除”，
    #     outfit 组没有指定属性了，于是回到默认的 casual。
    show eileen -formal

    "（旁白）show eileen -formal：减号表示移除，casual 作为默认值回来了。"

    # 3.5 一次写多个属性：属于不同 group 的属性可以同时指定。
    show eileen formal happy

    "（旁白）也可以一次指定多个 group 的属性。"

    hide eileen

    "（旁白）演示结束，感谢观看。"

    return
