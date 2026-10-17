# 第 10 章 ATL 与 transform

> [← 第 9 章 音频与视频](ch09-audio-and-video.md) ｜ [目录](index.md) ｜ [第 11 章 转场 →](ch11-transitions.md)

## 10.1 ATL 是什么

ATL（Animation and Transformation Language）是 Ren'Py 内嵌的小型动画语言：一串"属性随时间变化"的指令，告诉引擎某个可显示物如何动。它有两个载体：

1. `transform` 语句：定义一个**命名的变换**，供 `show ... at` 反复使用；
2. **内联 ATL 块**：直接写在 `show`、`camera`、screen 部件后面，用一次就丢。

## 10.2 最小示例与逐行解读

```renpy
transform gentle_bob:
    yoffset 0
    block:
        linear 1.5 yoffset -12
        linear 1.5 yoffset 0
    repeat

label start:
    show eileen happy at gentle_bob
    e "我在轻轻漂浮。"
    return
```

- `yoffset 0`（不带 warper 的行）是**瞬时指令**：立即设值，作为动画初值；
- `linear 1.5 yoffset -12` 是**动画指令**：warper（linear）+ 时长（1.5 秒）+ 目标属性——1.5 秒内线性移动到 yoffset=-12；
- `block:` 把多行动画打包成一个整体，让 `repeat` 有明确的循环边界：整块（下→上）反复执行，产生持续的上下漂浮。

## 10.3 warper：运动的"缓动曲线"

warper 决定属性值如何从旧值过渡到新值：

- `linear` 匀速；`pause N` 是特殊 warper——只等待不变化；
- `ease`：S 形缓动（两端慢中间快，最"自然"）；`easein`：先慢后快；`easeout`：先快后慢；
- `ease_back`、`ease_cubic` 等 `ease_*` 家族提供回弹、二次三次曲线等更多手感。

## 10.4 常用变换属性

| 类别 | 属性 |
|---|---|
| 定位 | `xalign yalign xpos ypos xanchor yanchor xoffset yoffset` |
| 缩放 | `zoom xzoom yzoom` |
| 旋转 | `rotate`（配 `transform_anchor`） |
| 呈现 | `alpha`（透明度）`blur`（模糊半径）`crop`（裁剪）`xysize` |
| 高级 | `matrixcolor`（色彩矩阵）与 8.x 的 3D 舞台属性（`perspective`、`zpos`、`rot_*`） |

## 10.5 复合结构：parallel、choice、on、time、function

真实演出常需要"同时做几件事""随机抖动""响应显示/隐藏"。ATL 的复合块提供这些：

```renpy
transform magic_float:
    parallel:
        linear 2.0 xalign 1.0
        linear 2.0 xalign 0.0
        repeat
    parallel:
        linear 1.0 alpha 1.0
        pause 1.0
        linear 1.0 alpha 0.3
        repeat
```

`parallel` 块并列执行：位置左右漂移的同时透明度独立呼吸。多个 parallel 分支互不干扰。

```renpy
transform flutter:
    choice:
        linear 0.8 xoffset 10
    choice:
        linear 0.8 xoffset -10
    repeat
```

`choice` 每次循环**随机**选一条分支执行——树影摇曳、烛火跳动这类"自然的乱"全靠它。

```renpy
transform slide_in:
    on show:
        xoffset -400
        easein 0.6 xoffset 0
    on hide:
        easeout 0.6 xoffset 400
```

`on show` / `on hide` / `on replace` / `on replaced` 定义**事件分支**：图像被 show 时从屏幕外滑入，被 hide 时滑出。人物出场退场的通用包装。

```renpy
transform timed:
    alpha 0.0
    linear 0.5 alpha 1.0
    time 3.0
    linear 0.5 alpha 0.0
```

`time 3.0` 是"闹钟"：动画到达 3 秒时无条件切到后续指令（不管前面的动画实际用了多久），适合精确编排。

`function` 则是终极逃生舱：每帧调用一个 Python 函数，由函数计算并返回下一帧的时间——粒子系统、自定义物理都在这里实现（第 18 章会再遇到它）。

## 10.6 ATL 定义 image：帧动画

`image` 语句体内也可以是 ATL，用于定义**帧动画**（一行一个画面，数字行是 `pause N` 的简写）：

```renpy
image pulse_block:
    Solid("#c04040")
    0.5
    Solid("#e06060")
    0.5
    repeat

label start:
    show pulse_block at truecenter
    "它在呼吸。"
    return
```

ATL 里的字符串行表示"显示这个 displayable"，裸数字 `0.5` 等价 `pause 0.5`。三帧红色明暗交替循环——这就是不用任何图片文件的帧动画。

## 10.7 小结与实践

- 瞬时行设初值，`warper 时长 属性` 行做动画，`block/repeat` 定循环；
- `parallel` 并行、`choice` 随机、`on` 响应事件、`time` 精确编排、`function` 全托管；
- `image` + ATL = 免素材帧动画；
- 示例工程 `08_atl_and_transform` 全部用 Solid/Composite 演示，无图片依赖。

---

> [← 第 9 章 音频与视频](ch09-audio-and-video.md) ｜ [目录](index.md) ｜ [第 11 章 转场 →](ch11-transitions.md)
