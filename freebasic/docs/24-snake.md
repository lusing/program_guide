# 24 · 实战：贪吃蛇

> 对应示例：`examples/24_snake/`（单文件工程；默认演示模式，`--play` 进交互模式）

## 24.1 目标与结构

把 22 章串成一个能玩的程序：**GFX 动画 + 确定性演示 AI + 双模式 + 最高分文件 + 自测断言**。

```text
24_snake/
└── 24_snake.bas      ~240 行单文件，六个清晰段落：
    ├── 常量/枚举     网格尺寸、目标食物数、帧上限、种子
    ├── Game UDT      蛇身环形缓冲 + 全部状态
    ├── 逻辑层        placeFood / onBody / gStep / demoThink —— 不碰 gfx 不碰键盘
    ├── 渲染层        drawFrame（离屏缓冲双缓冲）
    ├── 外设层        MultiKey 读键、Open Cons 输出
    └── 主循环        模式分派 → think → step → draw → sleep
```

**分层原则**与 dlang/cpp20 家族的 minigrep 相同：逻辑层零 IO，才能被断言与回放测死；渲染层只读状态不决策。

## 24.2 蛇身：环形缓冲

```freebasic
Type Game
    bodyX(0 To GW * GH - 1) As Integer   ' 环形数组
    bodyY(0 To GW * GH - 1) As Integer
    headIdx As Integer                    ' 头下标（尾 = headIdx - length + 1，模长回绕）
    length_ As Integer
    ...
End Type
```

移动 = `headIdx = (headIdx + 1) Mod 容量` 后写新头——**不搬移任何元素**（对比数组头插尾删的 O(n)）。吃到食物 `length_ += 1`，尾巴自然"多留一格"。这是 06 章数组 + 09 章指针思维的综合应用。

## 24.3 逻辑层：可断言的游戏规则

```freebasic
Sub gStep(ByRef g As Game)          ' 边界环绕 + 撞己判死 + 吃食成长
    Select Case g.dir_
    Case D_UP    : ny = (ny + GH - 1) Mod GH
    ...
    If onBody(g, nx, ny) Then g.alive = False : Return
    ...
End Sub
```

`placeFood` 只依赖 `Rnd`——**种子固定 ⇒ 食物序列固定 ⇒ 整局固定**（17 章）。边界选择环绕（吃豆人式）：游戏性更宽容，也让演示 AI 更稳。

## 24.4 演示 AI：包边距离贪心

```freebasic
Function wrapDelta(d As Integer, n As Integer) As Integer   ' 环面最短位移
    If d > n \ 2 Then d -= n
    If d < -(n \ 2) Then d += n
End Function

Sub demoThink(ByRef g As Game)
    ' 候选序：主轴贪心 → 备选轴 → 维持原向；跳过会撞体/掉头的候选
End Sub
```

不是智能，但**可验证**：种子 7 下 AI 恰好 58 帧吃满 8 个食物（两次运行逐字节一致）——这个结果被写进断言，回归测试就位。

## 24.5 渲染：离屏双缓冲

```freebasic
Dim back As Any Ptr = ImageCreate(GW * CELL, GH * CELL)   ' 18 章

Sub drawFrame(g, back)
    Line back, ..., bf        ' 网格底
    Line back, ..., bf        ' 食物
    For 每节蛇身 : Line back, ..., bf
    Put (0, 0), back, PSet    ' 一整帧一次上屏——无闪烁
End Sub
```

直接往屏幕画会有可见的逐个矩形闪烁；离屏画完整帧再 `Put` 是标准解。蛇身颜色从头到尾按节号渐暗——纯美术一行公式。

## 24.6 输入与模式

```freebasic
If MultiKey(SC_LEFT) AndAlso g.dir_ <> D_RIGHT Then g.dir_ = D_LEFT   ' SC_* 须 Using FB
```

- `MultiKey` 是**按下状态查询**（非事件），每帧轮询——连续转向天然支持。
- 反向禁止：`dir_ <> 反方向` 一行搞定（长度 > 1 时蛇不能掉头）。
- `--play` 参数经 `__FB_ARGV__` 识别（21 章）。

## 24.7 最高分往返

```freebasic
Function highscoreRoundtrip(score As Integer) As Boolean
    ' 写文件（16 章 Open 返回码检查）→ 读回 → ValInt 比对 → Kill 清理
End Function
```

真实游戏该持久保存；验证场景演示"写→读→校验→清理"完整闭环，仓库不留垃圾。

## 24.8 验证现场

- 演示模式 2.2 秒跑完 58 帧：8 个食物全部吃下、确定性断言过、最高分往返过、`[OK]` 收尾退出码 0；
- 两个验证层（`-g -exx` / 发布）输出**逐字节一致**——图形程序的确定性回归测试长这样；
- 交互模式同一二进制 `--play`，人工可玩性不打折。

## 24.9 坑位清单（1.10.1 实测）

1. **`fbgfx.bi` 的 `SC_*`/`BUTTON_*` 常量包在 `namespace FB` 里**——要么 `Using FB`，要么 `FB.SC_LEFT`。
2. gfx 程序的验证输出必须走 `Open Cons`（18 章纪律，贪吃蛇全程遵守）。
3. `Sleep 15` 的帧率在验证层足够；交互层用 `Sleep 60` 更可控——同一 Iif 分派。
4. 演示断言依赖种子 7 的具体局面：改种子/网格/初始长度 = 改断言数字（确定性测试的代价与契约）。
5. Linux 运行同 18 章要求：X11 显示（WSL2 需 WSLg；headless CI 用 `xvfb-run`）——WSLg 实测 58 帧演示与像素断言全过。
