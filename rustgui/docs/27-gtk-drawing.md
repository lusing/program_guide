# 27 · GTK 自绘：cairo 进度环

> 对应示例：[examples/27_gtk_drawing](../examples/27_gtk_drawing)

## 27.1 断代现场：draw 回调已是 cairo

四框架的同一只进度环画到第四份（05 egui Painter / 15 iced Canvas / 20 Slint
Path），GTK 的画法在 2025 年经历了一次**回调签名级**的代际更替：GTK 4.16 起
`DrawingArea` 的绘制回调拿的是 **`&cairo::Context`**（gtk4 0.11.5 手动层签名
实证：`FnMut(&DrawingArea, &cairo::Context, i32, i32)`）；而官方书（按 4.12
撰写）和旧例程里的 snapshot 画法在这条路上已编译不过——照书抄代码的第一个
撞墙点。

```rust
// ═══ 27.1 DrawingArea 只是壳，绘制是纯函数 ═══
let area = gtk::DrawingArea::new();
area.set_content_width(180);
area.set_content_height(180);
{
    let frac = frac.clone();
    area.set_draw_func(move |_, cr, w, h| {
        draw_ring(cr, w as f64, h as f64, frac.get())
    });
}
```

## 27.2 纯函数绘制：无头像素级验证的地基

绘制函数**不碰任何 widget**——尺寸由参数传入、状态由参数传入。这一纪律直接
换来四条无头通道里最硬的验证能力：**直接喂一个离屏 `ImageSurface`，画完数像素**：

```rust
// ═══ 27.2 纯函数：270° 缺口环（与 05/15/20 同规格）═══
fn draw_ring(cr: &cairo::Context, w: f64, h: f64, frac: f64) {
    let (cx, cy) = (w / 2.0, h / 2.0);
    let radius = w.min(h) / 2.0 - 10.0;
    let start = 135.0_f64.to_radians();  // 左下起
    let sweep = 270.0_f64.to_radians();  // 顺时针 3/4 圈，缺口朝下

    cr.set_line_width(10.0);
    cr.set_source_rgba(0.85, 0.85, 0.85, 1.0);       // 灰色轨道
    cr.arc(cx, cy, radius, start, start + sweep);
    let _ = cr.stroke();                              // stroke 返回 Result！

    if frac > 0.0 {
        cr.set_source_rgba(0.21, 0.52, 0.92, 1.0);   // 蓝：进行中（1.0 换绿）
        cr.arc(cx, cy, radius, start, start + sweep * frac);
        let _ = cr.stroke();
    }
}
```

像素证据的采集（这也是 cairo 无头测试的通用模板）：

```rust
// ═══ 27.2 离屏画一遍，数"非中性色"像素与圆心 alpha ═══
let mut surface = cairo::ImageSurface::create(cairo::Format::ARgb32, 80, 80)?;
{
    let cr = cairo::Context::new(&surface)?;
    draw_ring(&cr, 80.0, 80.0, frac);
} // ← Context 必须先释放，否则 data() 报 NonExclusive
let stride = surface.stride() as usize;
let data = surface.data()?;   // ARGB32 预乘，小端字节序 B,G,R,A
```

实测像素证据（见 27.5）：0% 无前景、25%/50%/100% 前景像素数**严格单调增**、
圆心四档全透明（空心环几何）。这比 kittest 的无障碍树断言硬一个量级——
它验证的是**真实光栅化输出**。

## 27.3 文字归布局层

中心百分比不放 cairo 里画（`select_font_face` 一路会引进字体度量，像素断言
随之脆化），用 `Overlay` 叠一个 Label：绘制层管图形、布局层管文字——两层的
失效传播也不同（`queue_draw()` 只重画画布，Label 走普通属性刷新）：

```rust
// ═══ 27.3 Overlay：Label 叠在 DrawingArea 正中 ═══
label.set_halign(gtk::Align::Center);
label.set_valign(gtk::Align::Center);
let overlay = gtk::Overlay::new();
overlay.set_child(Some(&area));
overlay.add_overlay(&label);
```

## 27.4 动画与按钮

`glib::timeout_add_local(Duration, || ControlFlow)` 是 GTK 的逐帧驱动（对照
05 章 `request_repaint`、20 章 `animate`）——**只在真窗口开**，selftest 装
定时器等于亲手打破两跑一致性。按钮接线与 25 章同构，`queue_draw()` 是
"帧失效"的 GTK 说法：

```rust
// ═══ 27.4 状态一变：两处投影同步刷新 ═══
fn apply(frac: &Rc<Cell<f64>>, label: &gtk::Label, area: &gtk::DrawingArea, delta: f64) {
    let clamped = (frac.get() + delta).clamp(0.0, 1.0);
    frac.set(clamped);
    label.set_text(&format!("{}%", (clamped * 100.0).round() as i32));
    area.queue_draw();   // 预约重画；无头环境里是空操作（不渲染）
}
```

嵌套闭包的坑在本章真实踩到：外层 `connect_clicked` 是 Fn 闭包，内层定时器
闭包要 `move`——直接写会把外层捕获**偷走**（E0507）。外层再 clone 一层是
手写正解，`glib::clone!` 宏是它的语法糖（29 章启用）。

## 27.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 27_gtk_drawing
```

实测输出（`build/27_gtk_drawing.run.out`）：

```text
==== 27 gtk 自绘进度环 开始 ====
px 0/25/50/100 = 0/456/828/1539 center-a=0 frac=1.00 label=100%
==== 27 gtk 自绘进度环 结束 ====
```

像素数解读：0% 时零前景（灰轨道不算"非中性"）；25%→50%→100% 前景 456→828→1539
严格翻倍级增长；圆心 alpha 四档全 0。真窗口（`cargo run`）：蓝弧灰轨、缺口
朝下、中心 `30%`、`-10%`/`+10%`/`自动` 三按钮——截图逐项核对一致。

## 坑位清单

- **draw 回调拿 cairo 不是 Snapshot（断代实锤）**：GTK 4.16 起 `set_draw_func` 的回调是 `FnMut(&DrawingArea, &cairo::Context, i32, i32)`；官方书/旧例程的 snapshot 画法在这条路上已失效。Snapshot 路线没死——它活在自定义 Widget 子类化里（29 章）。
- **`surface.data()` 报 `NonExclusive`**：cairo Context 还活着时表面被"占用"，读不了像素。画完把 Context 作用域关掉（或显式 `drop(cr)`）再 `data()`。顺序上还要先取 `stride()` 再借出 data（可变借用独占）。
- **ARGB32 是预乘 alpha、小端字节序 B,G,R,A**：断言颜色要按这个布局取字节；"前景色"检测用"非中性"（蓝/绿相对红通道拉开差距）比写死单色更稳——本例初版只查"蓝主导"，100% 的完成绿直接漏检（a100=0）。
- **`cr.stroke()` 在 cairo-rs 0.22 返回 `Result`**：渲染路径别 `unwrap`（绘制期 panic 最难定位），`let _ =` 吞掉状态错误即可。
- **定时器不进 selftest**：`timeout_add_local` 装上就有时序，两跑逐字节一致直接破防。动画只服务真窗口。
- **嵌套 move 闭包偷捕获（E0507）**：内层 `move` 会把外层 Fn 闭包的捕获移走；外层先 clone、内层再 move。样板多到烦时就该换 `glib::clone!`。

---

上一章：[26 · GTK 布局与 CSS](26-gtk-layout-css.md) ｜ 下一章：[28 · GTK 模型与 ListView](28-gtk-models.md) ｜ 返回：[README](../README.md)
