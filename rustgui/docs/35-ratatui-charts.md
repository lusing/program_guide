# 35 · Ratatui 图表与画布

> 对应示例：[examples/35_ratatui_charts](../examples/35_ratatui_charts)

## 35.1 字符即像素的极致

TUI 画图的原料是字符 cell，ratatui 把这件事做到了极致——**braille 盲文点阵
一格装 2×4 个子像素**，是终端里最接近"抗锯齿"的画法。四件套：

- `Chart`：数据坐标系。`Dataset`（`.marker(Marker::Braille)` +
  `.graph_type(GraphType::Line/Scatter/Bar)` + `.data(&[(f64,f64)])`）+
  `Axis::default().bounds([a,b]).labels([...])`；
- `BarChart`：分类柱状图（`Bar::default().label("一").value(6)`，
  0.30 的 label 直接收 `&str`，不再 `.into()`）；
- `Sparkline`：一行趋势条（字符集 `▁▂▃▄▅▆▇█`）；
- `Canvas`：自绘画布——世界坐标 → 网格映射 + `ctx.draw(&Points/&Line)` +
  `ctx.print`。

```rust
// ═══ 35.1 Chart：显式锁 bounds 是断言图的前提 ═══
let data = sin_data();                       // 固定数据源（先绑定！）
let datasets = vec![Dataset::default()
    .name("sin").marker(Marker::Braille).graph_type(GraphType::Line)
    .style(Style::new().fg(Color::Blue)).data(&data)];
Chart::new(datasets)
    .x_axis(Axis::default().bounds([0.0, 10.0]).labels(["0", "5", "10"]))
    .y_axis(Axis::default().bounds([-1.0, 1.0]).labels(["-1", "0", "1"]))
```

## 35.2 Canvas：世界坐标与 y 翻转

```rust
// ═══ 35.2 画布：points/line 直画，print 要 y 取负 ═══
Canvas::default()
    .marker(Marker::Braille)
    .x_bounds([-10.0, 10.0]).y_bounds([-5.0, 5.0])
    .paint(|ctx| {
        ctx.draw(&Points { coords: &[(0.0, 0.0), (5.0, 3.0)], color: Color::Red });
        ctx.draw(&Line { x1: -8.0, y1: -4.0, x2: 8.0, y2: 4.0, color: Color::Blue });
        ctx.print(0.0, 0.0, "原点");   // y 轴向上、行号向下——官方例用 -y 补
    })
```

canvas 的 `Line` 字段是 **x1/y1/x2/y2**（起点/终点）——不是几何惯用的
x0/y0/x1/y1，抄错报 unknown field。

## 35.3 无头断言：三层证据

图形"像素"是字符，所以图形断言就是**字符统计**（本章实测三板斧）：

1. **文本面**：轴标签行整行扫（含 "0"、"5"）；
2. **特征字符**：braille 段（U+2800–28FF）出现在图表区；柱底行
   `█/▇/▆` 计数（实测 15 = 三根 5 宽柱全在）；
3. **print 文字**：Canvas 里 `ctx.print` 的"原点"两字全屏收集后命中。

```text
实测输出：chart-axis=0/5 braille=ok bars-solid=15 canvas=原点
```

数据侧纪律：**一律固定数据源**（预计算 sin 表、写死的脉冲数组）——
不联网、不随机、不看表，两跑逐字节一致天然成立。

## 35.4 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 35_ratatui_charts
```

实测输出（`build/35_ratatui_charts.run.out`）：

```text
==== 35 ratatui 图表画布 开始 ====
chart-axis=0/5 braille=ok bars-solid=15 canvas=原点
==== 35 ratatui 图表画布 结束 ====
```

真终端（`cargo run`）：braille 平滑的 sin 曲线、三根中文标签柱、青色
脉冲条、q 退出。对照 06 章（egui_plot）/15 章（iced canvas）：同样的
"坐标映射 + 图元绘制"，第三种画布上的第四种形态。

## 坑位清单

- **Axis 不锁 bounds 必炸断言**：默认按数据范围自动定标，浮点边界微差让 braille 换格——断言图一律显式 `.bounds([...])`。
- **`.data(&sin_data())` 临时值 E0716**：`&Vec<(f64,f64)>` 借临时——先 `let data = ...` 绑定再传引用。
- **canvas::Line 字段是 x1/y1/x2/y2**：不是 x0/y0/x1/y1；`ctx.print` 的 y 轴向上（官方例 `ctx.print(x, -y, ..)` 的负号是翻转补丁）。
- **柱体/标签的行坐标要 dump 实测**：BarChart 内容区里柱体、值标签、名称标签各占行——布局给的行数不同位置全漂（本章实测：50x24 下柱体在 y12–15、值标签 y16、名称 y17）。**先 dump 再断言，别推算**。
- **`Sparkline::data` 直收数组**：`.data([..])` 不加 &（clippy needless_borrow）。
- **图表断言别贪心**：轴标签 + 特征字符计数 + print 文字三板斧足够；整屏 100 列期望行维护不动。

---

上一章：[34 · Ratatui 控件与样式](34-ratatui-widgets.md) ｜ 下一章：[36 · Ratatui 异步事件流](36-ratatui-async.md) ｜ 返回：[README](../README.md)
