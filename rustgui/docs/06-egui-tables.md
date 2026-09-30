# 06 · egui 表格、曲线图与图像

> 对应示例：[examples/06_egui_tables](../examples/06_egui_tables)

## 6.1 TableBuilder：虚拟化是表格的命

`egui` 本体的 `Grid` 只适合几十行以内；真数据表用 `egui_extras` 的 `TableBuilder`——它的 `body.rows` 是**虚拟化**的：只布局视口内的行，滚动到哪画到哪。

```rust
// ═══ 6.1 200 行的虚拟化表格 ═══
use egui_extras::{Column, TableBuilder};

TableBuilder::new(ui)
    .striped(true)
    .resizable(true)                 // 表头可拖调列宽
    .min_scrolled_height(160.0)
    .column(Column::exact(70.0))     // ID 列定宽
    .column(Column::remainder())     // 值列吃剩余
    .header(24.0, |mut header| {
        header.col(|ui| { ui.strong("ID"); });
        header.col(|ui| { ui.strong("Value"); });
    })
    .body(|body| {
        // 闭包按"视口窗口"回调：只对可见行调用
        body.rows(22.0, N_ROWS, |mut row| {
            let i = row.index();     // 行号由 egui 给，不用自己数
            row.col(|ui| { ui.label(format!("row-{i}")); });
            row.col(|ui| { ui.label(row_value(i).to_string()); });
        });
    });
```

虚拟化不是优化项而是**语义**：无头断言能直接证明——200 行的表，`row-0` 在无障碍树里，`row-199` 不在（它在视口外，根本没被布局）。滚动后 `row-199` 才会出现。这就是"即时模式 + 虚拟化"的组合拳：**树里只有你看得见的**。

## 6.2 egui_plot：迁出主仓库的曲线图

0.32 起 `egui_plot` 从 egui 主仓库**独立出去**，版本号与 egui **错位 +1**——这是真实测出来的版本坑：

| egui | 配套 egui_plot |
|---|---|
| 0.35 | 0.36 |
| **0.36（本教程）** | **0.37** |

写 `egui_plot = "0.36"` 时 Cargo 不会报错（它解析成 0.36 能编译），但你的图里会**同时存在两份 egui**（0.35 + 0.36），`Plot::show(ui, …)` 传入的 Ui 类型对不上才在编译期炸出"expected `egui::ui::Ui`, found `Ui`"这种玄学错误。

```rust
// ═══ 6.2 32 点折线 ═══
let line = egui_plot::Line::new("sin ramp", app.series.clone()); // Vec<[f64; 2]>
egui_plot::Plot::new("series-plot")
    .height(140.0)
    .show(ui, |plot_ui| plot_ui.line(line));
```

`Plot` 自带坐标轴、网格、图例、缩放平移（滚轮/拖拽）、box-select 放大；`Line::new(name, points)` 的 points 接 `Vec<[f64;2]>`、`PlotPoints` 等。柱状/散点/填充区域用 `BarChart`/`Points`/`Polygon`，同一套模式。

## 6.3 图像：程序化纹理，零资源文件

教程要可复现，于是本例的"图片"是**逐像素算出来**的——`ColorImage` + `load_texture`，不引入任何素材文件：

```rust
// ═══ 6.3 64x64 对角渐变：纯代码纹理 ═══
let pixels: Vec<egui::Color32> = (0..n * n)
    .map(|i| {
        let (x, y) = (i % n, i / n);          // pixels 是平铺数组（行优先）
        let v = ((x + y) * 255 / (2 * n - 2)) as u8;
        egui::Color32::from_rgb(v, 64, 255 - v)
    })
    .collect();
let img = egui::ColorImage { size: [n, n], pixels, source_size: egui::Vec2::ZERO };

// 首帧懒加载进 GPU 纹理缓存；handle 存进 app，跨帧复用
let tex = app.texture.get_or_insert_with(|| {
    ui.ctx().load_texture("gradient", img, egui::TextureOptions::LINEAR)
}).clone();

ui.add(egui::Image::from_texture(&tex).fit_to_exact_size(egui::vec2(64.0, 64.0)));
```

真实项目的静态图片走 `egui_extras::install_image_loaders(ctx)` + `ui.add(egui::Image::new("file.png"))`（需要 `image` feature，首次解码是异步的）；动态/生成式图像就走本例的 `load_texture`。要更新内容时对同一 handle 调 `tex.set(new_color_image, options)`。

## 6.4 无头断言：虚拟化的存在性证明

```rust
// ═══ 6.4 树里只有看得见的 ═══
assert!(harness.query_by_label("row-0").is_some(), "首行在视口内");
assert!(harness.query_by_label("row-199").is_none(), "虚拟化：视口外的行未被布局");
let images = harness.get_all_by_role(egui::accesskit::Role::Image).count();
assert!(images >= 1, "程序化纹理生成了图像节点");
```

Plot 的曲线是纯绘制（无节点可查），断言走数据侧：`app.series.len() == 32`。这也顺带示范了无头测试的边界——**布局树能查的直接查，纯像素的内容退回数据断言**。

## 6.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 06_egui_tables
```

实测输出（`build/06_egui_tables.run.out`）：

```text
==== 06 egui 表格与曲线 开始 ====
rows=200 series=32 texture=loaded
row 7 value = 49
==== 06 egui 表格与曲线 结束 ====
```

`row 7 value = 49` 来自确定性公式 `(i * 7) % 100`。真窗口里滚一滚表格（注意滚动条——200 行全在里面）、拖一拖表头分隔条（列宽可调）、在曲线上滚轮缩放。

## 坑位清单

- **egui_plot 版本错位 +1**：egui 0.36 ↔ egui_plot **0.37**。装错不报版本错，而是"两份 egui 共存"的类型不匹配。怀疑时 `cargo tree -i egui` 看是否出现两个版本。
- **ColorImage 的 pixels 是平铺的**：`pixels[y * w + x]`，行优先一维数组；想按二维迭代要自己解下标（0.36 还有 `source_size: Vec2` 字段，位图填 `Vec2::ZERO`）。
- **load_texture 三参数**：0.36 是 `load_texture(name, image, TextureOptions)`——漏了采样选项会 E0061。`LINEAR` 平滑、`NEAREST` 像素风。
- **rows 闭包的 row 要 `mut`**：`|mut row|`——`row.col(&mut self, …)`。编译器提示得很清楚，但闭包捕获习惯容易顺手写成不可变。
- **虚拟化让"全表遍历"测试失效**：断言"每一行都在树里"天然不成立（它们不该在）。全表逻辑用数据侧断言，视口内行为用树查询。

---

上一章：[05 · egui 自绘：Painter 与逐帧动画](05-egui-painter.md) ｜ 下一章：[07 · egui 中文字体与主题样式](07-egui-fonts.md) ｜ 返回：[README](../README.md)
