# 第 4 章 图像与舞台

> [← 第 3 章 第一个游戏：对话与角色](ch03-first-game.md) ｜ [目录](index.md) ｜ [第 5 章 标签与控制流 →](ch05-labels-and-flow.md)

（配套示例：`examples/02_images_and_stage`）

## 4.1 图像名：tag 与 attribute

Ren'Py 中每张图有一个**图像名（image name）**，由空格分隔的若干单词组成：第一个词是 **tag（标签）**，其余词是 **attribute（属性）**。例如图像名 `sylvie green smile` 的 tag 是 `sylvie`，属性是 `green`、`smile`。tag 是舞台上"这个位子上是谁"的身份证，属性描述这个角色/背景的具体状态（服装、表情、时段）。

图像名必须以字母开头，只能包含字母、数字、下划线——因为它们会被当作 Python 标识符使用。

## 4.2 自动图像定义与 image 语句

把图片文件放进 `game/images/`（含子目录），Ren'Py **自动**把文件名（去扩展名、全部小写、忽略子目录）注册为图像名：`bg meadow.jpg` → `bg meadow`；`Sylvie Green Surprised.png` → `sylvie green surprised`。角色图支持 PNG/WEBP/AVIF，背景还支持 JPG。

需要把**非文件**的东西注册为图像（纯色、拼接图、动画），或者给文件起一个与文件名不同的名字时，用 `image` 语句。它写在任何 label 之外的顶层（在 init 阶段、默认优先级 500 执行）：

```renpy
image logo = "renpy logo.png"
image eileen happy = "eileen_happy_blue_dress.png"
image black = Solid("#000")
image tile tiled = Tile("tile.png")
image eileen happy question = VBox(
    "question.png",
    "eileen_happy_blue_dress.png",
)
image jun stretched = At("jun.png", xzoom 2)
```

- 右侧可以是**任何 displayable**（引擎的显示物对象）：字符串表示图片文件，`Solid("#000")` 是纯黑矩形，`Tile` 平铺一张图，`VBox`/`Composite` 等可以把多个显示物拼合，`At` 给显示物套 transform（第 10 章）。
- `image` 语句还可以直接带 **ATL 块**定义动画图像（10.3）。

本仓库所有示例都不携带图片素材，背景与"立绘"全部用 `Solid`、`Composite`、`Frame` 等程序化显示物代替——例如示例 02 中：

```renpy
image bg white = Solid("#f0f0f0")
image bg black = Solid("#101010")
image eileen = Solid("#c8ffc8", xysize=(220, 460))
```

这样定义后，`show eileen` 的行为与显示一张真实立绘完全一致。读者在自己的项目里把右侧换成 `"images/eileen.png"` 即可。

## 4.3 show / scene / hide：舞台三剑客

- **`scene`**：清空 `master` 层上的所有图像，然后（可选地）显示一张背景。开始新场景时用它。
- **`show`**：在当前舞台上叠加一张图（角色、道具、前景特效）。
- **`hide`**：按 tag 隐藏一张图。

```renpy
label start:

    scene bg meadow

    "After a short while, we reach the meadows just outside the neighborhood where we both live."

    m "Hey... Umm..."

    show sylvie green smile

    "She turns to me and smiles. She looks so welcoming that I feel my nervousness melt away."

    m "Will you be my artist for a visual novel?"

    show sylvie green surprised

    "Silence."
```

注意第三处 `show sylvie green surprised`：舞台上已有 tag 为 `sylvie` 的图，再 show 同 tag 图像会**替换**旧图。这就是表情切换的标准做法——只写新属性，`show sylvie surprised` 也可以（引擎记住该 tag 的现有属性，未提及的沿用）。

`hide` 的官方示例：

```renpy
label leaving:

    s "I'll get right on it!"

    hide sylvie

    "..."

    m "That wasn't what I meant!"
```

`hide sylvie` 按 tag 隐藏，不用写属性。官方文档特别提醒 `hide` 用得很少：换表情用 `show`，换场景直接 `scene`，只有"人离开但场景保留"才需要 `hide`。

## 4.4 show 的完整子句

`show`（以及 `scene`/`hide`）支持一整套修饰子句，官方合成示例：

```renpy
show eileen happy at flip as eileen2 behind eileen3 onlayer master zorder 1 with dissolve
```

- `at flip`：对图像应用名为 `flip` 的 transform（位置/动画，第 10 章）。
- `as eileen2`：给这次显示指定**另一个 tag**。同一张图可以在舞台出现两份（如分身、回忆场景）。
- `behind eileen3`：把新图插到 tag 为 `eileen3` 的图像**后面**（遮挡关系）。
- `onlayer master`：指定显示在哪个层（层见 4.6）。
- `zorder 1`：同层内的显示次序，数值大的在上。
- `with dissolve`：显示的同时播放转场（第 11 章）。
- `expression` 子句（`show expression "eileen happy"`）：右侧不再是一个图像名，而是一个**运行时求值**的表达式，可配合 `as` 指定 tag，用于程序化生图的场合。

属性还可以带符号操作：`show eileen -happy`（移除属性）、`show eileen +happy`（添加属性）。不匹配任何已定义图像名的属性不会被立刻报错——它们成为"运行时属性"，供 layeredimage（第 12 章）等动态显示物按条件选层。

## 4.5 位置：at 与预定义位置

图像默认水平居中、底边贴屏幕底。`at` 子句指定位置：

```renpy
show sylvie green smile at right
```

引擎预定义四个位置：`left`（靠左）、`right`（靠右）、`center`（水平居中，即默认）、`truecenter`（水平垂直双居中）。`at` 后面可以接多个 transform（依次应用），也可以写**内联 ATL 块**：

```renpy
show eileen happy:
    xalign 0.8 yalign 1.0
```

（这种写法与 `at` 一个匿名 transform 等价；ATL 的完整语法在第 10 章。）

## 4.6 层（layers）与 camera

Ren'Py 的舞台是分层的。`config.layers` 按从底到顶的顺序列出所有层，引擎内部至少使用 `"master"`（场景图像）、`"transient"`（临时界面）、`"screens"`（screen 界面）、`"overlay"`（覆盖层）四层，官方要求它们必须始终在列表里。你可以在 `init python` 中扩展这个列表插入自己的层（如 `underlay`、`effects`），再用 `show ... onlayer effects` 把图放到指定层。

对**整层**应用变换（滤镜、旋转、3D 相机）用 `camera` 语句：

```renpy
# The flip transform needs to be defined once, at the start of the game.
transform flip:
    xzoom -1 yzoom -1
```

```renpy
camera at flip
```

或直接内联：

```renpy
camera:
    xalign 0.5 yalign 0.5 rotate 180
```

与之相近的旧写法 `show layer master` 有三点差异（官方文档）：`camera` 的变换会**传播**给后来加入该层的图像而 `show layer` 会重置；`show layer` 的变换在下一个 `scene` 时被清除而 `camera` 持续存在；`camera` 默认作用于 master 层而 `show layer` 必须写层名。取消整层变换用无参数的 `camera`。

## 4.7 小结与实践

- 背景放 `game/images/bg/`，立绘放 `game/images/`，文件名即图像名；
- 同 tag `show` 即替换——表情切换零成本；
- 转场（`with`）与位置（`at`）是演出的一半灵魂，配合第 10、11 章食用；
- `camera` 是 8.x 整层演出（含 3D 舞台）的入口。

---

> [← 第 3 章 第一个游戏：对话与角色](ch03-first-game.md) ｜ [目录](index.md) ｜ [第 5 章 标签与控制流 →](ch05-labels-and-flow.md)
