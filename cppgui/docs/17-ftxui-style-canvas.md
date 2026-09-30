# 17 · FTXUI 样式系统与 Canvas 画布

> 对应示例：[examples/17_ftxui_style_canvas.cpp](../examples/17_ftxui_style_canvas.cpp)

## 17.1 颜色四代：命名色 / 256 色 / RGB / HSV

```cpp
// ═══ 17.1 四种颜色构造 ═══
hbox({
    text(" 命名色 ") | color(Color::Red) | bgcolor(Color::GrayDark),
    text(" 256色 ") | color(Color::Palette256(208)) | bgcolor(Color::Palette256(17)),
    text(" RGB ") | color(Color::RGB(12, 200, 120)),
    text(" HSV ") | color(Color::HSV(200, 80, 90)),  // hue 是 uint8_t：280 会回绕成 24
}),
```

FTXUI 的颜色分四代，按终端能力自动降级（真彩 → 256 色 → 16 色），代码不用变：

| 代际 | 构造 | 输出转义形态（对照本章输出） |
|---|---|---|
| 命名色（16 色） | `Color::Red` | `\x1b[31m` |
| 256 色 | `Color::Palette256(n)` | `\x1b[38;5;208m` |
| 真彩 RGB | `Color::RGB(12, 200, 120)` | `\x1b[38;2;12;200;120m` |
| HSV | `Color::HSV(h, s, v)` | 换算成 RGB 转义输出 |

命名色是 `Color::Red` 这类枚举；256 色用 `Color::Palette256(n)`——**没有 `Color256()` 工厂**，那是老写法（坑位第 1 条）；`Color::RGB(r,g,b)` 真彩直给；`Color::HSV(h,s,v)` 圆柱色彩空间，适合"色相扫一圈"的程序化配色。前景 `color()`、背景 `bgcolor()`，都是装饰管道里的一环。输出第 1 段一行里四代转义齐现，HSV 那格输出的已是换算后的 RGB 转义。

## 17.2 文字装饰与 ANSI 转义

```cpp
// ═══ 17.2 装饰都是真 SGR/OSC 序列 ═══
auto doc = vbox({
    text("bold 粗体") | bold,
    text("dim 变暗") | dim,
    text("inverted 反白") | inverted,
    text("underlined 下划线") | underlined,
    text("strikethrough 删除线") | strikethrough,
    text("blink 闪烁") | blink,
    text("链接") | hyperlink("https://example.com") | color(Color::Blue) | underlined,
});
```

七种装饰全是终端转义，一一对着输出第 2 段数得出来：

| 装饰 | 开启 | 复位 |
|---|---|---|
| bold | `\x1b[1m` | `\x1b[22m` |
| dim | `\x1b[2m` | `\x1b[22m` |
| inverted | `\x1b[7m` | `\x1b[27m` |
| underlined | `\x1b[4m` | `\x1b[24m` |
| strikethrough | `\x1b[9m` | `\x1b[29m` |
| blink | `\x1b[5m` | `\x1b[25m` |
| hyperlink | OSC 8 开链 `\x1b]8;;URL\x1b\\` | 闭链 `\x1b]8;;\x1b\\` |

超链接不是 SGR 而是 **OSC 8** 两段式：开链带 URL、闭链复位——输出里 `链接` 两个字两侧的怪字节就是它（还叠了下划线 + 蓝色的 SGR）。关键教学点：这些转义在 `Screen::ToString()` 里**原样保留**，不进终端时它们就是字符串里的普通字节——这正是本章能把"颜色"写进文档的原理。

## 17.3 Canvas：块分辨率画布

```cpp
// ═══ 17.3 Canvas：每字符格横 2 点、纵 4 点 ═══
auto c = Canvas(50, 12);
// 网格参考线
for (int x = 0; x < 50; x += 10)
    c.DrawPointLine(x, 0, x, 11, Color::GrayLight);
// 正弦曲线（点线）
for (int x = 0; x < 50; ++x)
{
    float y = 5.5f + 4.5f * std::sin(x * 2 * 3.14159f / 49);
    c.DrawPoint(x, (int)y, Color::Red);
}
// 块线（粗）
c.DrawBlockLine(0, 11, 49, 6, Color::Blue);
// 圆（Canvas 没有画圆 API——参数方程手画）
for (float a = 0; a < 6.2832f; a += 0.05f)
    c.DrawPoint(25 + (int)(4 * std::cos(a) * 2), 6 + (int)(4 * std::sin(a)),
                Color::Green);
auto doc = canvas(std::move(c)) | border;
```

`Canvas(w, h)` 是点阵坐标的画布：每个终端字符格再分**横向 2 点、纵向 4 点**（Braille 盲文 8 点 / 四分块字符承载体），所以 `Canvas(50, 12)` 渲染出来是 25 列 × 3 行的字符区（输出第 3 段边框内的三行）。坐标系 **y 向下**（y 增大往屏幕下方），画正弦时 `[0,1]` 区间的 `5.5 ± 4.5` 正落在 1–10 的点行内。三支画笔各有分工：

- `DrawPoint(x, y, color)`——单点，落进哪个字符格由点阵坐标整除决定；
- `DrawPointLine(x1, y1, x2, y2, color)`——细线，沿途点用盲文字符拼装，多条线穿过同一格时点阵叠加成一个字符；
- `DrawBlockLine(...)`——粗线，用 ▀▄█ 类四分块字符，视觉重量大，适合坐标轴与地面线。

**没有画圆 API**——绿色圆是参数方程逐点手画的，x 半径乘 2 补偿每字符横 2 点、纵 4 点的密度差（坑位第 3 条）。

## 17.4 LinearGradient：builder 式渐变

```cpp
// ═══ 17.4 渐变是 builder：.Angle().Stop() 链 ═══
text(" 渐变文字 ") | center | size(WIDTH, EQUAL, 30)
    | bgcolor(LinearGradient().Angle(90)
                  .Stop(Color::DeepPink1).Stop(Color::DeepSkyBlue1)),
```

master 的 `LinearGradient` 是 builder 式构造：`.Angle(度)` 定方向（90 度即自上而下）、`.Stop(色)` 挂色标（两端各一，中间自动插值）。配 `bgcolor` 整块铺渐变背景；前景色同样可用 `color(LinearGradient()...)`。输出第 4 段的 30 列渐变带里能逐列看到变化的真彩背景转义 `\x1b[48;2;R;G;Bm`——从 DeepPink1 过渡到 DeepSkyBlue1，红分量逐列降、蓝分量逐列升，中间行经紫区，"渐变文字"四个字嵌在其上。这是 16 章 dbox 之外另一种"整块上色"的手段，做启动页、进度横幅、标题条都合适（坑位第 4 条：老的构造写法已换）。

## 17.5 动画：thread 周期 PostEvent 重绘

动画 = 改状态 + 促使重绘，二者在 FTXUI 里分属两条线。交互模式的标准通路（官方 `examples/component/canvas_animated.cpp`）：后台线程改相位变量 → `PostEvent` 唤醒主循环 → 组件树整帧重建 → Canvas 按新相位重画，如此往复。15 章的 `PostEvent(Event::Custom)` 是同一机制的定制事件版；18 章的 `Post(Task{Closure{...}})` 则是把"改状态"也装进闭包投回主循环线程。

动画三要素拆开看更清楚：**相位**是普通变量（角度、偏移量），状态外置；**推进**靠后台线程 `sleep_for` 控帧率——教学演示 500ms 一拍就够，平滑动画按 16–33ms 一拍；**重绘**靠 `PostEvent` 唤醒——FTXUI 没有内置定时器组件，"每帧"完全由你的事件流定义。这也解释了为什么 Canvas 的绘制代码不带时间参数：它每帧从头画，相位在画外。

**渲染到字符串管线验证不了动画**——每帧内容不同，时序数据进 stdout 会让两跑一致性必炸。所以本例 selftest 只打一行占位（输出第 5 段），动画留在交互模式演示；"时序内容不进输出"这条铁律的完整代价见 19 章坑位第 2 条。

## 17.6 运行与输出

构建与单例验证：

```bash
cd cppgui
pwsh build.ps1 -Example 17_ftxui_style_canvas
```

selftest 实测输出（`build/docs-ref/17_ftxui_style_canvas.out`；剥行尾 CR，转义字节原样保留）：

```text
==== 17 FTXUI 样式与画布 开始 ====
-- 1) 颜色四代 --
[31m[100m 命名色 [38;5;208m[48;5;17m 256色 [38;2;12;200;120m[49m RGB [38;2;80;61;90m[49m HSV [39m[49m                                       
────────────────────────────────────────────────────────────────
真彩在老终端自动降级到 256 色或 16 色                           
-- 2) 装饰（ANSI 转义在字符串里可见）--
[1mbold 粗体                     [22m
[2mdim 变暗                      [22m
[7minverted 反白                 [27m
[4munderlined 下划线             [24m
[9mstrikethrough 删除线          [29m
[5mblink 闪烁                    [25m
]8;;https://example.com\[4m[34m[49m链接                          ]8;;\[24m[39m[49m
-- 3) canvas --
╭────────────────────────────────────────────────────╮
│[37m[49m⡇[39m[49m    [37m[49m⡇[39m[49m    [37m[49m⣇[39m[49m⣀⣀⣀⣀[37m[49m⡧[39m[49m⠒⠒⠒⠒[37m[49m⡗[39m[49m⠢⢄⡀                            │
│[37m[49m⡧[39m[49m⢄⡀  [37m[49m⡇[39m[49m   ⡞[37m[49m⣇[39m[49m⠤⠒⠉ [37m[49m⡏[39m[49m⡦ [34m[49m▄▄▄▄▄▄▄[39m[49m                           │
│[34m[49m▄▄▄▄▄▄▀▀▀⠈⠓⠒⠒⠒⠒⠋▀▀[39m[49m  [37m[49m⡇[39m[49m                               │
╰────────────────────────────────────────────────────╯
-- 4) LinearGradient --
[39m[48;2;0;174;254m [39m[48;2;55;172;251m [39m[48;2;75;169;248m [39m[48;2;90;166;245m [39m[48;2;103;163;242m [39m[48;2;114;160;239m [39m[48;2;124;157;236m [39m[48;2;133;154;232m [39m[48;2;142;151;229m [39m[48;2;149;147;225m [39m[48;2;157;144;222m [39m[48;2;164;140;218m渐[39m[48;2;177;133;211m变[39m[48;2;188;125;203m文[39m[48;2;200;117;195m字[39m[48;2;210;107;187m [39m[48;2;215;102;182m [39m[48;2;220;97;178m [39m[48;2;224;91;173m [39m[48;2;229;85;168m [39m[48;2;233;78;163m [39m[48;2;238;71;158m [39m[48;2;242;62;152m [39m[48;2;246;51;147m [39m[48;2;250;37;141m [39m[48;2;254;0;134m [39m[49m    
-- 5) canvas 动画：交互模式演示（thread + PostEvent 每帧重绘）--
==== 17 FTXUI 样式与画布 结束 ====
```

四段有效输出正好是四代样式的实证：第 1 段一行里并排四种颜色构造的转义形态；第 2 段七行装饰各自的开/复位转义，末行链接的 OSC 8 包着 `\x1b[4m\x1b[34m`（下划线 + 蓝）；第 3 段 canvas——红色正弦以盲文点拼出平滑曲线（`⡇⢄⡀` 等 8 点字符），蓝色 `DrawBlockLine` 是 `▄▄▄` 四分块粗线，灰色竖参考线在 x=0/10/20/30/40 处；第 4 段渐变逐列 SGR。颜色转义与点阵字符互相穿插——那就是"带样式的像素"。

## 坑位清单

- **256 色没有 `Color256()` 工厂**：正确写法是 `Color::Palette256(n)`——Color 里的嵌套枚举，可隐式转 Color；老教程的 `Color256(208)` 编不过（源码 17_ftxui_style_canvas.cpp【坑】注释；提交 2472096）。
- **`Color::HSV` 的 hue 是 uint8_t**：按 0–359 度直觉传 280 会回绕成 24（280 % 256），色相跑偏且无警告；要么压进 0–255，要么直接换 RGB（源码行内注释）。
- **Canvas 没有画圆 API**：画笔只有 SetPixel/DrawPoint/DrawPointLine/DrawBlockLine 等图元，圆、贝塞尔都得参数方程逐点手画（源码注释；提交 2472096）。
- **LinearGradient 改成了 builder**：`.Angle(90).Stop(c1).Stop(c2)` 链式构造；旧的参数聚合写法已不适用（提交 2472096 实测收录）。
- **样式转义在 ToString() 里原样保留**：SGR 是 `\x1b[..m`、超链接是 OSC 8 两段式；逐字节引用输出块时这些字节、点阵字符与尾随空格一个都不能动（.out 字节级核查）。

---

上一章：[16 · FTXUI 布局进阶：约束、弹性与网格](16-ftxui-layout.md) ｜ 下一章：[18 · FTXUI 组合子代数与自定义组件](18-ftxui-composition.md) ｜ 返回：[README](../README.md)
