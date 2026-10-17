# 第 11 章 转场

## 11.1 with 语句与预定义转场

`with` 语句触发一次"旧画面 → 新画面"的过渡：

```renpy
label start:
    show bg forest with dissolve
    scene bg sea with fade
    hide eileen with moveoutleft
    return
```

引擎预定义了一批常用转场，`with` 直接点名使用：

| 转场 | 效果 |
|---|---|
| `dissolve` | 交叉溶解（最常用） |
| `fade` | 先黑再淡入 |
| `pixellate` | 像素化过渡 |
| `vpunch` / `hpunch` | 垂直/水平震屏（打击感） |
| `wipeleft/right/up/down` | 定向擦除 |
| `slideleft/right/up/down` | 旧画面滑出、新画面滑入 |
| `moveinleft` 等 / `moveoutleft` 等 | 单个物件滑入/滑出 |
| `zoomin` / `zoomout` | 缩放过渡 |

## 11.2 绑定规则：with 属于"它前面的变化"

`with` 作用于**它之前所有未呈现的显示变化**：

```renpy
label start:
    show eileen happy
    show bg school
    with dissolve
    return
```

两条 `show` 一起在这次 dissolve 中呈现。想各自带过渡，就各自写 `with`（`show eileen happy with dissolve` 另起一次过渡）。

`with None` 是重要工具——"到此为止的变化瞬间生效、不播过渡"：

```renpy
label start:
    scene bg street
    with None
    show eileen
    with dissolve
    return
```

背景瞬切（不过渡），只有人物溶解出现。`with None` 常用来"切开"不想要的关联过渡。

## 11.3 转场类：定制你自己的过渡

预定义转场都是转场类的实例。用 `define` 造自己的转场常量：

```renpy
define slow_dissolve = Dissolve(2.0)
define blackout = Fade(0.5, 1.0, 0.5)
define wipe_right = CropMove(0.5, "wiperight")

label start:
    scene bg room with slow_dissolve
    "两秒的慢溶解。"
    scene black with blackout
    "半秒淡出、停一秒、半秒淡入。"
    return
```

- `Dissolve(秒)`：交叉溶解，参数是时长；
- `Fade(淡出秒, 黑屏停留秒, 淡入秒)`：三段式淡入淡出，黑屏停留可营造"时间流逝"；
- `CropMove(秒, 模式)`：裁剪移动类（擦除、百叶窗、滑动矩阵等模式）；
- `ImageDissolve(蒙版图, 秒)`：用灰度图当溶解蒙版——波纹、百叶窗、马赛克溶解都基于它；
- `AlphaDissolve(控制图, 秒)`：用一张图的 alpha 通道控制过渡（配合动画可以做发光扫描）；
- `MoveTransition(秒)`：处理**位置移动**——预定义的 `move` 就是它，让图像在两次 show 之间平滑移动而非跳变；
- `MultipleTransition([...])`：把多段转场串成一列，中间可插入静止帧。

## 11.4 字典转场：一层一个效果

转场默认作用于所有受影响的层。传**字典**可以按层定制：

```renpy
define layered_change = {"master": Dissolve(0.5)}

label start:
    show bg room with layered_change
    return
```

字典键是层名（`config.layers` 里的名字），值是该层的转场；未列出的层瞬时完成。先在 `init python` 里加入自定义层（如 `"sprites"`），就能实现"背景 0.5 秒溶解、立绘 1.5 秒慢溶解"的分层节奏。

## 11.5 转场与交互

`with` 会阻塞到过渡播完（其间的点击默认可跳过过渡）。转场期间玩家看到的是"旧画面叠新画面"的合成帧，因此**转场前画面必须已经合法**——这也是 `with None` 存在的另一个理由：先把画面布置好，再决定怎么演。

## 11.6 小结与实践

- 预定义转场覆盖九成需求；`Dissolve/Fade/CropMove` 三大件自定义；
- `with` 绑定前面的变化，`with None` 切断关联；
- 字典转场做分层节奏；`ImageDissolve` 是花式溶解的钥匙；
- 示例工程 `09_transitions` 用色块演示每种转场的实际观感。

---

上一章：[10 ATL 与 transform](ch10-atl-and-transform.md) · 下一章：[12 Layered Images 立绘系统](ch12-layered-images.md)
