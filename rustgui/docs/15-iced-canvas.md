# 15 · iced Canvas：自绘进度环

> 对应示例：[examples/15_iced_canvas](../examples/15_iced_canvas)

## 15.1 Canvas：把"画什么"写成函数

egui 的 Painter 是每帧的命令式画笔；iced 的 Canvas 则把绘制封装成 **`canvas::Program`**——一个带内部状态类型的绘制单元：

```rust
// ═══ 15.1 进度环的绘制程序 ═══
struct Ring { progress: f32 }

impl<Message> canvas::Program<Message> for Ring {
    type State = ();  // 内部可变状态（动画进度等）；本环不需要

    fn draw(&self, _state: &(), renderer: &iced::Renderer, _theme: &Theme,
            bounds: Rectangle, _cursor: iced::mouse::Cursor)
        -> Vec<canvas::Geometry> {
        // 拿 bounds 算几何，Frame 上作画，into_geometry 交回
    }
}

// 挂进 view：canvas 是 feature 门控件（Cargo.toml 开 "canvas"）
let ring = canvas(Ring { progress: self.progress })
    .width(iced::Length::Fixed(180.0))
    .height(iced::Length::Fixed(180.0));
```

`draw` 收到框架算好的 `bounds`、当前主题、光标位置，返回一组 `Geometry`。它只在需要时被调用（消息到达/重绘请求），不是每帧无条件执行——这是与 egui"每帧重画"的根本差别。

## 15.2 Frame：命令式画布，Path：几何描述

```rust
// ═══ 15.2 底环 + 进度弧 + 中心文字 ═══
let center = bounds.center();
let radius = bounds.width.min(bounds.height) / 2.0 - 10.0;

let base = canvas::Path::circle(center, radius);   // 整圆底环

// 进度弧：0.14 的 canvas 同样没有现成 arc API——
// 手算 sin/cos 点列 + Path 折线（与 egui 05 章同一思路）
let start = 135.0_f32.to_radians();
let sweep = 270.0_f32.to_radians() * self.progress.clamp(0.0, 1.0);
let mut points = Vec::with_capacity(49);
for i in 0..=48 {
    let angle = start + sweep * (i as f32 / 48.0);
    points.push(center + iced::Vector::new(angle.cos(), angle.sin()) * radius);
}
let arc = canvas::Path::new(|p| {
    p.move_to(points[0]);
    for pt in &points[1..] { p.line_to(*pt); }
});

let mut frame = canvas::Frame::new(renderer, bounds.size());
frame.stroke(&base, canvas::Stroke::default().with_width(10.0)
    .with_color(Color::from_rgb(0.25, 0.25, 0.25)));
frame.stroke(&arc, canvas::Stroke::default().with_width(10.0)
    .with_color(Color::from_rgb(0.29, 0.62, 1.0)));
frame.fill_text(canvas::Text {        // 画布上也能排文字
    content: format!("{:.0}%", self.progress * 100.0),
    position: center, color: Color::WHITE, size: 22.0.into(),
    ..Default::default()
});
vec![frame.into_geometry()]
```

工具速查：`Path::circle/rectangle/line/ellipse`、`Path::new(builder)`（move_to/line_to/arc/quad…）；`frame.fill/stroke/fill_text/with_save/translate/rotate/scale/with_clip`；`Stroke::default().with_width().with_color().with_line_dash()`。交互侧：`Program::update`（收事件返回 `Action`——可发布消息/请求重绘，动画靠它）与 `mouse_interaction`。

## 15.3 Cache：别每条消息都重画

真实项目把几何缓存在 `canvas::Cache` 里，状态变化时 `cache.clear()`：

```rust
// ═══ 15.3 缓存模式（生产姿势）═══
struct Ring { progress: f32, cache: canvas::Cache }

fn draw(&self, renderer, bounds, ..) -> Vec<canvas::Geometry> {
    vec![self.cache.draw(renderer, bounds.size(), |frame| {
        // 只有 cache 为空时才真正执行
    })]
}
// update 里：self.cache.clear();  // progress 变了才清
```

本例环小、直接画足够；列表页/图表页不清缓存能省大量 CPU。egui 的对应物是"painter 直接画、靠整体重绘兜底"——两种取舍，各有脾气。

## 15.4 无头测试：canvas 无像素，状态机全可测

simulator 只跑 view+update，**`draw` 不被执行**——环长什么样无头验证不了，但消息环全部可测：

```rust
// ═══ 15.4 按钮三连 + 屏幕文本证据 + 自动播放消息路径 ═══
ui.click("+10%")?; ui.click("+10%")?; ui.click("-10%")?;
for m in ui.into_messages() { let _ = app.update(m); }
assert!((app.progress - 0.4).abs() < 1e-6);

{ let mut ui = simulator(app.view()); ui.find("40%")?; }  // 屏幕百分比随之重算

let _ = app.update(Message::Auto);          // 自动播放 = time::every 订阅
for _ in 0..4 { let _ = app.update(Message::Add(0.05)); } // 消息单元测试
assert!((app.progress - 0.6).abs() < 1e-6);
```

这是三框架自绘可测性的中位形态：egui 连绘制产物都能断言（kittest 渲染 pass），iced 断言到"驱动绘制的状态与屏幕文本"，Slint（20 章）的 Path 是声明式的、连"怎么画"都在 .slint 里可推理。

## 15.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 15_iced_canvas
```

实测输出（`build/15_iced_canvas.run.out`）：

```text
==== 15 iced Canvas 进度环 开始 ====
progress=60% auto=true
==== 15 iced Canvas 进度环 结束 ====
```

真窗口里点 ±10% 看环走，点"自动"看 50ms 心跳（14 章的订阅在这里上班）平滑转满一圈。

## 坑位清单

- **canvas 是 feature 门**：`iced = { features = ["canvas"] }`，默认不开。编译错"cannot find canvas in widget"先查 Cargo.toml，不是代码问题。
- **没有 arc API（又是）**：egui 05、iced 15、slint 20 三家的弧全要自己离散点列——这是矢量 GUI 的通用现实，官方 spinner/时钟示例同款手法。
- **draw 里别持借用**：`draw(&self, ..)` 只有 `&self`——想改动画进度走 `Program::update` 发消息/请求重绘，别在 draw 里 mutate。
- **Cache 忘了 clear**：进度变了环不动——状态变更处必须 `cache.clear()`，这是缓存模式的手动义务。
- **simulator 坐标默认 1024x768**：canvas 的 `width/height(Fixed)` 一定要给，否则 Shrink 的 canvas 在弹性盒里塌缩成 0，测试里 bounds 为空（真窗口里则表现为"画布不见了"）。

---

上一章：[14 · iced 订阅与异步 Task](14-iced-subscription.md) ｜ 下一章：[16 · iced 综合实战：待办管理器](16-iced-app.md) ｜ 返回：[README](../README.md)
