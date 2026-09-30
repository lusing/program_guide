# Rust GUI 速查表（egui 0.36 / iced 0.14 / Slint 1.18 / GTK4 0.11）

四框架横向速查 + 坑位索引。详细讲解见对应章（N.M = 第 N 章 M 节）。

## 1. 应用骨架（02 / 10 / 17 / 24）

```rust
// egui：App::ui（0.34 起取代 update）
fn main() -> eframe::Result {
    eframe::run_native("app", opts, Box::new(|cc| Ok(Box::new(App::new(cc)))))
}
impl eframe::App for App {
    fn ui(&mut self, ui: &mut egui::Ui, _f: &mut eframe::Frame) { /* 每帧 */ }
}
```

```rust
// iced：函数式 builder（Sandbox 已删）
iced::application(State::new, State::update, State::view)
    .title("app").subscription(State::subscription).run()
```

```rust
// Slint：DSL 编译 + handle
slint::include_modules!();
let app = AppWindow::new()?; app.run()
// build.rs: slint_build::compile("ui/app.slint")
```

```rust
// GTK：Application + activate 信号（真窗口腿）；无头腿 gtk::init() 直构控件
let app = gtk::Application::builder().application_id("org.x.Y").build();
app.connect_activate(|app| { /* 建窗口 */ });
app.run()
```

## 2. 事件与状态（03 / 10-11 / 18 / 25）

| 任务 | egui | iced | Slint | GTK4 |
|---|---|---|---|---|
| 按钮 | `if ui.button("X").clicked() {}` | `button("X").on_press(Msg::X)` | `TouchArea { clicked => {} }` | `btn.connect_clicked(\|_\| {})` |
| 输入 | `ui.text_edit_singleline(&mut s)` | `text_input(ph, &s).on_input(Msg)` | `LineEdit { edited(t) => {} }` | `entry.connect_activate(\|e\| e.text())` |
| 勾选 | `ui.checkbox(&mut b, "标签")` | `checkbox(b).label(..).on_toggle(..)` | TouchArea 自绘或 std CheckBox | `check.connect_toggled(\|c\| c.is_active())` |
| 选中值变化 | Response.changed() | on_change(Fn(T)->Msg) | 属性绑定自动 | `connect_active_notify`（程序赋值靠 notify） |
| 声明式联动 | ——（每帧重算即联动） | ——（update 集中改） | `property <=> other` | `a.bind_property("x", &b, "y").build()` |

## 3. 布局（04 / 12 / 19 / 26）

| 概念 | egui | iced | Slint | GTK4 |
|---|---|---|---|---|
| 垂直/水平 | `ui.vertical/horizontal` | `column![]/row![]` | `VerticalLayout/HorizontalLayout` | `gtk::Box::new(Orientation, spacing)` |
| 弹性 | `Length::Fill(FillPortion)` | `Length::Fill/FillPortion` | `horizontal-stretch: n` | `set_hexpand(true)` |
| 网格 | `egui::Grid` | ——（row/column 拼） | `GridLayout` | `grid.attach(列,行,宽,高)`（宽高即跨行列） |
| 面板/容器 | `egui::Panel::left(..).show(ui, ..)` | `container(c).center(Fill)` | 布局盒嵌套 | 容器控件嵌套（Box/Grid/Overlay/FlowBox） |
| 滚动 | `ScrollArea::vertical()` | `scrollable(..)` | `ListView`（虚拟化） | `ScrolledWindow::set_child(..)` |

## 4. 自绘（05 / 15 / 20 / 27）

```rust
// egui：painter 命令式（弧线手算点列 → Shape::line）
let (rect, resp) = ui.allocate_exact_size(size, Sense::hover());
ui.painter().circle_stroke(center, r, Stroke::new(w, c));
```

```rust
// iced：draw 函数 + Frame
impl canvas::Program<Msg> for P { fn draw(..) -> Vec<Geometry> {
    let mut f = canvas::Frame::new(renderer, size); f.stroke(..); vec![f.into_geometry()] } }
```

```rust
// Slint：Path 吃 SVG 命令字符串（Rust 算字符串）
Path { commands: root.arc-cmd; stroke: #4a9eff; stroke-width: 10px; }
```

```rust
// GTK：DrawingArea 回调拿 &cairo::Context（GTK 4.16 起，snapshot 画法已断代）
area.set_draw_func(move |_, cr, w, h| draw_ring(cr, w as f64, h as f64, frac));
cr.arc(cx, cy, r, start, start + sweep * frac); let _ = cr.stroke();
```

四家都没有现成 arc-to-API 的糖——点列/A 命令/cairo arc 各自手算是通识；GTK 的独门是
**绘制可纯函数化 + ImageSurface 无头像素断言**（27 章唯一的真·光栅级无头验证）。

## 5. 异步与并发（09 / 14 / 21 / 29）

| | egui | iced | Slint | GTK4 |
|---|---|---|---|---|
| 一次性请求 | 后台线程 + mpsc + `ctx.request_repaint` | `Task::perform(async, Msg)` | `slint::spawn`/线程 + `invoke_from_event_loop` | `gio::spawn_blocking` + async-channel |
| 持续流 | request_repaint 循环 | `Subscription`（`time::every`） | Timer / 后台 invoke | `glib::timeout_add_local(Duration, \|\| ControlFlow)` |
| 唤醒 UI 线程 | `ctx.request_repaint_from` | 消息即重绘 | `invoke_from_event_loop` | `glib::spawn_future_local` 收通道 |

## 6. 无头测试四通道（02 / 10 / 17-18 / 24）

```rust
// egui_kittest
use egui_kittest::kittest::Queryable;
let mut h = Harness::builder().build_eframe(|cc| App::new(cc));
h.get_by_label("Increment").click(); h.run();
assert_eq!(h.state().count, 3);
```

```rust
// iced_test
let mut ui = iced_test::simulator(app.view());
ui.click("Increment")?;                       // &str 全等匹配
for m in ui.into_messages() { app.update(m); }
iced_test::simulator(app.view()).find("value: 1")?;
```

```rust
// slint（init_no_event_loop + ffi 注入 + ElementHandle 查询）
i_slint_backend_testing::init_no_event_loop();
let el = ElementHandle::find_by_element_id(&app, "组件名::元素名").next()?;
el.set_accessible_value("42");               // a11y 输入通道（触发 edited）
send_mouse_click(&app, x, y);                 // 坐标注入（4 行官方同款 shim）
```

```rust
// GTK：#[gtk::test]（官方，串行线程池自动 init）+ 句柄直驱直断
#[gtk::test]
fn t() {
    let c = Counter::new();
    c.button.emit_clicked();                  // 直发信号，同步派发
    while ctx.pending() { ctx.iteration(false); }   // 排空主循环
    assert_eq!(c.label.text(), "count: 3");
}
```

## 7. 断代翻译表（旧教程 → 本教程版本）

| 旧写法（0.31-/0.12-/1.17-/GTK 4.12-） | 新写法 |
|---|---|
| `App::update(&mut self, ctx, frame)` | `App::ui(&mut self, ui, frame)`（02.2） |
| `SidePanel::left("id").show(ctx, ..)` | `egui::Panel::left("id").show(ui, ..)`（04.1） |
| `eframe::run_simple_native(..)` | 已删除，用 run_native（02 坑位） |
| `impl Sandbox for App` | `iced::application(new, update, view)`（10.2） |
| `Command::perform(f, msg)` | `Task::perform(f, msg)`（14.2） |
| `impl button::StyleSheet` | `.style(fn(&Theme, Status) -> Style)`（13.2） |
| `slint::testing::send_mouse_click(&h, x, y)` | i-slint-backend-testing + shim（17.3） |
| `Subscription::tick` | `iced::time::every(d)`（14.3） |
| DrawingArea 的 snapshot 画法（书 4.12 时代） | `set_draw_func(\|_, cr, w, h\| ..)` cairo 回调（27.1） |
| `glib::MainContext::channel()` | async-channel crate（send_blocking/recv().await）（29.2） |
| `ListStore<T>` 泛型字段 | 0.22 起裸 `ListStore`，泛型在 `new::<T>()` 方法上（30 坑位） |

## 8. 坑位总索引（按框架，章号回链）

**egui**
| 坑 | 章 |
|---|---|
| 旧 API 全灭三连（update/SidePanel/run_simple） | 02 |
| type_text 须先 focus + run；run 后节点失效重查；get_* 唯一匹配 panic | 03 |
| 面板顺序即嵌套；CentralPanel 最后；Grid 忘 end_row | 04 |
| 无 arc API；run() 撞 max_steps=4；时间驱动动画测不了 | 05 |
| egui_plot 版本错位 +1（0.36↔0.37）；ColorImage source_size；虚拟化断言边界 | 06 |
| kittest 见中文 panic；Arc<FontData>；github master ≠ crates.io | 07 |
| 空标签撞 accessibility check；WidgetType≠Role；persistence 无头不生效 | 08 |
| get_all_by_label 逆文档序（相对查询正解）；闭包借用拆标志位 | 09 |

**iced**
| 坑 | 章 |
|---|---|
| Sandbox 已删；&str 全等匹配；Error 无 PartialEq | 10 |
| radio/pick_list 标签点不到；on_input 是函数；回车落点随焦点 | 11 |
| click(Point) 点目标中心（根容器）；TargetNotVisible；Space 无参构造 | 12 |
| Theme 无 name()；闭包签名看控件有无 Status | 13 |
| time::every 需 tokio/smol feature；run 非捕获 fn；simulator 不跑 Task | 14 |
| canvas/tokio feature 门；Cache 忘 clear；canvas 定宽高 | 15 |
| on_press 收值 on_toggle 收闭包；Fn 闭包 clone 纪律；selftest 存档先删 | 16 |

**Slint**
| 坑 | 章 |
|---|---|
| slint::testing 已移除；internal feature 打包 bug；init 每进程一次 | 17 |
| 元素 id 带组件前缀；with_debug_info 前提；LineEdit 别绑回 text | 18 |
| length 必带单位；match_type_name 要具体类型 | 19 |
| changed 无头不刷新；动画中途值别断言；Path viewbox 显式；DSL 无三角函数 | 20 |
| invoke_from_event_loop 无头走不通；嵌套接口双桥；DFS 序是假设 | 21 |
| % 是单位（Math.mod）；set_row_data 放回；selftest 别忘接回调 | 22 |
| percent/length 不混三目；生成类型无 serde；模型聚合 Rust 算 | 23 |

**GTK4**
| 坑 | 章 |
|---|---|
| gtk::init 跨线程 panic（#[gtk::test] 正解）；无 gtk::main_iteration；MSVC 要 --msvc-syntax | 24 |
| Entry 文本在 EditableExt；is_active vs active；set_active 只保证 notify；transform_to 显式标注 | 25 |
| Revealer 动画破坏两跑一致（transition None）；CSS 解析错只走 stderr；provider 是自由函数 | 26 |
| draw 回调 cairo 化（断代）；data() 的 NonExclusive；ARGB32 预乘 BGR A；嵌套 move 偷捕获 | 27 |
| factory bind 无窗不触发（隐形窗口技巧）；Option 泛型两代并存；locale collate 只断言排列 | 28 |
| template 路径相对源文件；XML id≠字段名运行时 abort；@implements Accessible E0425；无 MainContext::channel | 29 |
| GSettings Windows 不落盘；connect_notify 要 Send+Sync（local 版）；item() 临时值 E0716 | 30 |

## 9. 版本事实速记

- egui 0.36.2：MSRV 1.95；wgpu 默认渲染器；github master 领先已发布版（Role/corner_radius 改名未发布）
- iced 0.14.0：rust-version 1.88；默认 features 含 wgpu+tiny-skia；iced_test 是 0.14 新增
- Slint 1.18.1：三许可（GPL/royalty-free/商业）；默认 femtovg+software 渲染（不碰 wgpu）
- gtk4 0.11.5（配 GTK 4.22/gvsbuild 2026.8.0）：绑定随 GTK 小版本走（v4_2…v4_24 feature 门，
  本教程零 feature）；gtk-rs master 是 0.12.0-alpha 未发布；依赖树仅 +26 包（无 GPU）；
  GTK 本体 LGPL（Windows 动态链接可闭源）
- 本 workspace：756 依赖包，wgpu 双版本（eframe→30、iced→27），edition 2024
