# 第 12 章 Layered Images 立绘系统

> [← 第 11 章 转场](ch11-transitions.md) ｜ [目录](index.md) ｜ [第 13 章 Screen 语言基础 →](ch13-screen-basics.md)

## 12.1 问题：立绘是零件的组合

一个角色的立绘往往由身体、表情、服装、配饰等图层组合。如果每张组合图都单独出图，文件数量是各零件数的乘积。`layeredimage` 让你只出零件图，在引擎里描述**组合规则**，Ren'Py 自动合成，并与 `say` 属性、`show` 无缝联动。

## 12.2 基本语法

```renpy
layeredimage eileen:
    always:
        "eileen_base"

    group outfit auto:
        attribute school default
        attribute casual

    group face:
        attribute neutral default
        attribute happy
        attribute angry
```

- `always:` 块里的图层**始终显示**（身体底图）；
- `group outfit`：组内属性**互斥**（一次只能穿一套衣服）。`auto` 让引擎自动寻找命名为 `eileen_outfit_school`、`eileen_outfit_casual` 的图像收进组里（tag_组名_属性 命名法）；不用 auto 时直接 `attribute` 一行行写；
- `default` 标记组内默认选中项；
- 每个 attribute 对应一个显示物：写了名字就找同名图像文件，也支持块内直接写 displayable/ATL（见 12.5）。

## 12.3 if 条件图层与 multiple

```renpy
layeredimage eileen:
    always:
        "eileen_base"
    group face:
        attribute neutral default
        attribute happy
        attribute angry

    attribute blush if happy
```

`attribute blush if happy`：只有当 `happy` 属性激活时才叠加腮红图层——"表情自带联动装饰"不用重复画。另外，组内默认互斥，想允许叠加的属性用 `multiple` 关键字声明（如饰品组允许多件同戴）。

## 12.4 与对话属性联动：立绘自动切换

```renpy
define e = Character("艾琳", image="eileen")

label start:
    show eileen
    e happy "说这句话时自动切换成 happy。"
    e angry "下一句自动换成 angry。"
    e "不带属性时维持当前样子。"
    return
```

`Character(image="eileen")` 把角色和 layeredimage 绑定：之后**每句 say 的属性直接驱动立绘组合**——`e happy` 等价 `show eileen happy`，`e @ happy` 临时切换，`e -angry` 摘掉属性。scene `eileen` 也能整体清除。这让"说话即表演"成为一行属性的事。

## 12.5 免素材演示：attribute 直接挂 displayable

学习阶段没有立绘素材时，attribute 块内直接写 displayable（Solid/Composite/Text 都行）：

```renpy
layeredimage demo_char:
    always:
        Composite((300, 600),
            (0, 0), Solid("#7ec8e3", xysize=(300, 600)))
    group shirt:
        attribute blue default:
            Solid("#3355aa", xysize=(220, 260))
        attribute red:
            Solid("#aa3333", xysize=(220, 260))
    group mood:
        attribute calm default:
            Text("︿", size=60, color="#ffffff")
        attribute glad:
            Text("＾▽＾", size=60, color="#ffffff")

label start:
    show demo_char at truecenter
    d "换件衣服。" (what_size=24)
    show demo_char red glad
    d "红衣+笑脸。"
    return
```

`Composite((宽, 高), (x, y), 子显示物, ...)` 是"绝对定位拼贴器"：在 300×600 的画布上按坐标叠放色块与文字，模拟出可换装、可变表情的角色。组合规则（互斥、默认、条件）与真实素材工程完全一致。

## 12.6 小结与实践

- `layeredimage` = always 底图 + 互斥 group + attribute 零件；`auto` 按命名自动收图；
- `attribute X if Y` 做条件联动图层；`multiple` 允许叠戴；
- `Character(image=...)` + say 属性 = 台词驱动演出；
- 示例工程 `10_layeredimage` 用 12.5 的免素材写法实现完整换装演示。

---

> [← 第 11 章 转场](ch11-transitions.md) ｜ [目录](index.md) ｜ [第 13 章 Screen 语言基础 →](ch13-screen-basics.md)
