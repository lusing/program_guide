# 05 · egui 自绘：Painter、进度环与逐帧动画

> 对应示例：[examples/05_egui_painter](../examples/05_egui_painter)

## 5.1 自绘三步：要矩形、画、拿 Response

egui 里所有"非控件"的绘制都走同一条路——`Painter`。它不是独立画布，就挂在当前 `Ui` 上，坐标系是这个 Ui 的逻辑坐标：

```rust
// ═══ 5.1 自绘的标准姿势 ═══
let (rect, response) = ui.allocate_exact_size(egui::vec2(160.0, 160.0), egui::Sense::hover());
Self::paint_ring(ui, rect, app.progress);
// response 照常可用：hovered()/contains_pointer() —— 自绘图也能参与交互
```

三步各司其职：`allocate_exact_size` 在布局流里**占住一块矩形**（返回矩形 + Response）；`ui.painter()` 在矩形里作画；Response 让这块区域有身份、可交互、可无障碍查询。跳过 allocate 直接拿 `ui.available_rect_before_wrap()` 画也可以，但那样你的画就没有布局身份了。

## 5.2 弧线要自己算：官方 spinner 的技法

0.36 的 epaint **没有现成的 arc API**。看官方 `Spinner` 的实现——弧线就是"角度区间离散成点列，再连线"：

```rust
// ═══ 5.2 270° 进度环：sin/cos 点列 + Shape::line ═══
fn paint_ring(ui: &mut egui::Ui, rect: egui::Rect, progress: f32) {
    let painter = ui.painter();
    let center = rect.center();
    let radius = rect.size().min_elem() * 0.5 - 8.0;
    let width = 10.0_f32;

    // 底环：整圆描边
    painter.circle_stroke(center, radius, egui::Stroke::new(width, egui::Color32::from_gray(60)));

    // 进度弧：手算点列（与官方 spinner 同款）
    let start = 135.0_f32.to_radians();               // 缺口对称朝下
    let end = start + 270.0_f32.to_radians() * progress.clamp(0.0, 1.0);
    let points: Vec<egui::Pos2> = (0..=48)
        .map(|i| {
            let angle = start + (end - start) * (i as f32 / 48.0);
            center + radius * egui::vec2(angle.cos(), angle.sin())
        })
        .collect();
    painter.add(egui::Shape::line(points, egui::Stroke::new(width, egui::Color32::from_rgb(74, 158, 255))));

    // 中心文字：painter 也能排版（FontId + Align2 锚点）
    painter.text(center, egui::Align2::CENTER_CENTER,
        format!("{:.0}%", progress * 100.0),
        egui::FontId::proportional(22.0), ui.visuals().strong_text_color());
}
```

常用 Painter 工具速查：`circle`/`circle_filled`/`circle_stroke`、`rect`/`rect_filled`/`rect_stroke`、`line_segment`、`text`，以及万能的 `painter.add(shape)`（`Shape::line` 折线、`Shape::dashed_line` 虚线等都在这层）。复杂图形（直方图、雷达图、连线图）全部由这些基元拼出来。

## 5.3 动画驱动力：每帧步进 + request_repaint

egui 默认**按需重绘**——没人动就不重画。动画的本质是"我声明下一帧还要画"：

```rust
// ═══ 5.3 运行中每帧 +0.05，并预约下一帧 ═══
if app.running {
    app.frames += 1;
    app.progress = (app.progress + 0.05).min(1.0);
    if app.progress >= 1.0 {
        app.running = false;      // 跑满自动停
    }
    ui.ctx().request_repaint();   // "我还要下一帧"
}
```

三种子驱动力按场景选：

| 手段 | 适用 | 特点 |
|---|---|---|
| `ctx.request_repaint()` + 每帧步进 | 本例的进度环、游戏化 UI | 步长完全由你定，**确定性最强** |
| `ctx.animate_value_with_time(id, target, 秒)` | 控件的状态过渡（颜色/位置淡变） | 缓动插值，egui 自动请求重绘 |
| 每帧无条件重绘（什么都不做就是它） | 调试覆盖层 | 最费电，产品代码别用 |

本章选第一种不是偶然：**帧步进让动画在无头测试里完全确定**——每帧 +0.05，跑到稳定恰好 20 帧，两次运行逐字节一致。若用真实时间驱动（`input.time` 乘速度），selftest 输出就不可复现了。

## 5.4 无头验证：max_steps 与 run_steps

持续 `request_repaint()` 的 UI **永不"稳定"**——kittest 的 `run()` 默认最多跑 4 步就 panic（`ExceededMaxStepsError`，错误信息会告诉你它其实几步能稳）。两条出路：

```rust
// ═══ 5.4 知道何时停的动画：调大 max_steps 让 run() 跑到自停 ═══
let mut harness = egui_kittest::Harness::builder()
    .with_max_steps(64)
    .build_eframe(|_cc| RingApp::new());
harness.get_by_label("Run").click();
let steps = harness.run(); // 环跑满 -> running=false -> 不再请求重绘 -> 稳定

// 永不停的动画（如 spinner）：改用固定步数
// harness.run_steps(40); // 跑 40 帧，不等待稳定
```

本例的环会自己停（跑满自动 `running=false`），所以 `run()` 配 `with_max_steps(64)` 是正解；纯循环动画就用 `run_steps(n)`。

## 5.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 05_egui_painter
```

实测输出（`build/05_egui_painter.run.out`）：

```text
==== 05 egui 自绘进度环 开始 ====
settled in 22 steps (20 animation frames + 收尾帧)
progress=100% frames=20
==== 05 egui 自绘进度环 结束 ====
```

`settled in 22 steps`：点击本身耗一步、20 个动画帧、收尾稳定帧——这些数字每次运行都一致，这就是"帧步进动画"的可测性。真窗口里点 Run 看环转起来；把 `0.05` 改成 `0.01` 再跑 `build.ps1`，帧数断言会变红——这就是本仓库"改代码 → 重跑 → 看哪条测试红"的学法。

## 坑位清单

- **没有 arc API**：0.36 epaint 不提供画弧函数，别照着 0.31 教程找 `Shape::arc`。点列 + `Shape::line` 是官方唯一姿势（见 `widgets/spinner.rs` 源码）。
- **run() 撞 max_steps=4**：动画 UI 一律 `with_max_steps(N)` 或 `run_steps(N)`。报错信息附带"实际几步能稳定"的诊断，照着调即可。
- **时间驱动的动画测不了**：`ui.input(|i| i.time)` 驱动的一切（官方 spinner 就是）输出不可复现，教程/自检代码用帧步进。真产品里用时间驱动没问题。
- **allocate 时给 Sense**：`Sense::hover()`（可悬停）还是 `Sense::click()`（可点击）按需给；`Sense::NO` 会让这块区域对输入完全透明。
- **painter 坐标是所在 Ui 的局部逻辑坐标**：多层面板嵌套时 `rect` 都已被换算到当前 Ui，直接用即可；自己算 `screen_pos` 反而容易错。

---

上一章：[04 · egui 布局：统一 Panel 体系与两遍布局](04-egui-layout.md) ｜ 下一章：[06 · egui 表格、曲线图与图像](06-egui-tables.md) ｜ 返回：[README](../README.md)
