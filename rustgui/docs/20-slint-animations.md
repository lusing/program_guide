# 20 · Slint 状态动画与声明式自绘

> 对应示例：[examples/20_slint_animations](../examples/20_slint_animations)

## 20.1 animate：属性的附属品

Slint 的动画不是时间线对象，是**属性声明的修饰**——给哪个属性配 `animate`，它的变化就自动插值：

```slint
// ═══ 20.1 条件绑定 + animate = 完整的过渡动画 ═══
in-out property <length> knob-x: root.on ? 120px : 20px;  // 目标由条件绑定给出
animate knob-x { duration: 250ms; easing: ease-in-out; }   // 变化过程自动插值

// 缓动函数：linear / ease / ease-in / ease-out / ease-in-out /
//          cubic-bezier(x1, y1, x2, y2) / bounce / spring
```

## 20.2 states：给"一组属性值"命名

条件多了，散装的 `?:` 会失控。`states` 把同一情境下的属性值打包：

```slint
// ═══ 20.2 灯的两种状态 ═══
lamp := Rectangle {
    height: 56px;
    states [
        lit  when root.on:  { background: #2e7d32; }
        dark when !root.on: { background: #444; }
    ]
    animate background { duration: 200ms; easing: ease-in-out; }
    // 状态切换时颜色平滑过渡——states 与 animate 天然配合
}
```

`in { ... }` / `out { ... }` 块还能分别声明进入/离开状态时触发的回调与属性（`in { root.requested(); }`），组合出小型状态机。三家的"状态"对读：egui 状态全在你结构体里（无内建动画状态）、iced 状态即 State 枚举（动画靠 canvas/控件）、Slint 把状态机内建进 DSL。

## 20.3 第三只进度环：声明式 Path

09（egui Painter）/15（iced Canvas）/20（Slint Path）三只环，三种自绘哲学。Slint 的 Path 吃 **SVG 风格命令字符串**：

```slint
// ═══ 20.3 命令字符串绑到属性：变了就重绘 ═══
Path {
    width: 180px; height: 180px;
    viewbox-width: 180; viewbox-height: 180;
    commands: root.arc-commands;   // "M x y A r r 0 large 1 ex ey"
    stroke: #4a9eff;
    stroke-width: 10px;
    fill: transparent;
}
```

弧命令由 Rust 算——.slint 表达式没有 sin/cos，**数值计算天然属于宿主语言**：

```rust
// ═══ 20.4 270° 弧的 SVG A 命令（同步核心，纯函数可单测）═══
fn arc_commands(progress: f32) -> String {
    let (cx, cy, r) = (90.0, 90.0, 70.0);
    let start = 135.0_f32.to_radians();
    let sweep = 270.0_f32 * progress.clamp(0.0, 1.0);
    let (sx, sy) = (cx + r * start.cos(), cy + r * start.sin());
    let end = start + sweep;
    let (ex, ey) = (cx + r * end.cos(), cy + r * end.sin());
    let large = u8::from(sweep > 180.0);
    format!("M {sx:.2} {sy:.2} A {r} {r} 0 {large} 1 {ex:.2} {ey:.2}")
}
```

### changed：反应式链跨语言边界

```slint
in property <float> progress: 0;
in-out property <string> arc-commands;
callback update-arc();
changed progress => { root.update-arc(); }   // 属性变更回调（1.5+）
```

Rust 侧挂 `on_update_arc`：progress 变 → changed 触发 → Rust 算弧 → 写回 arc-commands → Path 绑定重绘。**整条链只有第一步是事件，后面全是绑定**——这就是"声明式为主、计算留给宿主"的分工。

## 20.4 动画的确定性：mock 时间

测试 backend 的动画**不跟真实时间走**——`mock_elapsed_time` 推多少走多少：

```rust
// ═══ 20.5 推进 260ms > 动画时长 250ms：终值断言确定 ═══
let x_before = app.get_knob_x();       // 20
app.set_on(true);
i_slint_backend_testing::mock_elapsed_time(std::time::Duration::from_millis(260));
assert!((app.get_knob_x() - 120.0).abs() < 0.5); // 必然到位
```

一个重要的实测语义：**animate 作用在属性本身**——动画中途读属性拿到的是插值中的值（egui 的 animate_bool 同理、iced 的动画在 canvas/控件内部）。所以"中途值"断言是时序敏感的（别测），"推完时长后的终值"断言是确定的（放心测）。

## 20.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 20_slint_animations
```

实测输出（`build/20_slint_animations.run.out`）：

```text
==== 20 slint 动画与 Path 开始 ====
knob-x: 20.0 -> 120.0 (mock +260ms 后到位)
arc(0.5) = M 40.51 139.49 A 70 70 0 0 1 139.49 139.49
==== 20 slint 动画与 Path 结束 ====
```

`arc(0.5)`：135° 起点扫过 135°——纯函数输出即证据。真窗口里点"翻转开关"看滑块缓动滑移、颜色渐变（250ms/200ms），改 `progress` 属性看弧长变化。

## 坑位清单

- **changed 回调在无头环境不刷新**：`changed x =>` 依赖事件循环推进，`init_no_event_loop` 下 Rust 侧 `set_x` 后回调**不会**跑——测试里直接 `invoke_update_arc()` 成对设置（真窗口路径不受影响）。
- **动画中途值别断言**：animate 作用于属性，中途读值依时序而定；测"推进 mock 时长后的终值"。
- **stroke-width 等 length 属性必须带单位**：`stroke-width: 10` 编译错，`10px` 才对（19 章同款坑的动画版）。
- **Path 的 viewbox 要显式给**：不给 `viewbox-width/height` 时命令坐标按原始像素算，与 width/height 缩放纠缠——180×180 的环就 180 的 viewbox。
- **.slint 没有 sin/cos**：几何计算放 Rust（同步核心 + changed/回调搬运），别在 DSL 里硬凑三角函数。

---

上一章：[19 · Slint 布局系统](19-slint-layout.md) ｜ 下一章：[21 · Slint 组件复用与 Rust 深度集成](21-slint-components.md) ｜ 返回：[README](../README.md)
