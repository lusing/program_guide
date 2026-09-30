# 26 · GTK 布局与 CSS

> 对应示例：[examples/26_gtk_layout_css](../examples/26_gtk_layout_css)

## 26.1 布局四件套

前一章用 Builder XML 搭了界面，本章回到代码层把布局容器过一遍——GTK 的
布局不是属性魔法，是**容器控件**的组合（对照 04 章 egui Panel、12 章 iced
Length、19 章 Slint 的 VerticalLayout 家族）：

| 容器 | 一句话 | 关键调用 |
|---|---|---|
| `Box` | 线性盒（纵向/横向） | `append`/`prepend` + `spacing` |
| `Grid` | 网格，**宽高即跨列跨行** | `attach(列, 行, 宽, 高)` |
| `FlowBox` | 流式换行 + 可选单选/多选 | `insert` + `set_selection_mode` |
| `Revealer` | 显隐过渡容器 | `set_reveal_child` + `set_transition_type` |

Grid 的 attach 五参是本家的特色——跨列不用嵌套，直接把"宽"写成 2：

```rust
// ═══ 26.1 Grid：跨两列不需要嵌套容器 ═══
grid.attach(&gtk::Label::new(Some("第 0 行 · 左")), 0, 0, 1, 1); // 列 0 行 0
grid.attach(&gtk::Label::new(Some("第 0 行 · 右")), 1, 0, 1, 1); // 列 1 行 0
grid.attach(&cross, 0, 1, 2, 1);                                 // 列 0 行 1，宽 2
```

布局是**元数据**，可以反查——`grid.query_child(&cross)` 返回 `(列, 行, 宽, 高)`，
无头断言布局结构就靠它（布局对不对是逻辑事实，不必开窗口）。

## 26.2 CSS：GTK 的样式层

GTK 用一份 CSS 方言做样式（支持的子集：color/background/padding/border-radius/
opacity/transition/text-decoration…，没有 flex/grid——布局还是容器的事）。
两步挂上：`CssProvider` 装载规则 → 挂到 display（全局）：

```rust
// ═══ 26.2 全局样式表：加载 + 挂 display ═══
fn apply_css() {
    let provider = gtk::CssProvider::new();
    provider.load_from_data(CSS);          // 解析错误走 stderr 日志，不 panic
    if let Some(display) = gtk::gdk::Display::default() {
        gtk::style_context_add_provider_for_display(
            &display,
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION, // 优先级常量在 gtk::
        );
    }
}
```

控件级的开关是**样式类**（style class）——这是 GTK 样式系统的核心抽象：CSS
选择器选类，类的挂摘是运行时状态：

```rust
// ═══ 26.2 样式类即状态位 ═══
label.add_css_class("chip");     // <CSS> .chip { border-radius: 14px; ... }
let on = label.has_css_class("chip");
label.remove_css_class("chip");
```

本例的三条规则覆盖三种典型用途：`.accent` 控件主题色、`.chip` 圆角胶囊
（FlowBox 城市芯片）、`.strike` 划线半透明（30 章待办"完成态"的预演）。

## 26.3 无头断言的边界：类是逻辑、样式是渲染

```rust
// ═══ 26.3 无头可断言的三件事：结构/选中/类 ═══
let (col, row, w, h) = l.grid.query_child(&l.cross);      // 布局元数据
l.flow.select_child(&l.chips[1]);
assert_eq!(l.flow.selected_children().len(), 1);           // 选中态
assert!(l.accent_btn.has_css_class("accent"));             // 样式类
```

诚实边界（07 章"进树 ≠ 有字形"的 GTK 版）：**"类挂上了"是逻辑事实，"CSS 把
它渲成什么样"无头看不见**——本通道不渲染像素。而且 CSS 解析错误也只走 stderr
日志（`Gtk-CSS-WARNING`），不会让程序失败——写错 CSS 的自测要靠真窗口截图
（`build/gui-shots/26_gtk_layout_css.png`：重点按钮蓝底白字、芯片圆角、
"这条会被 CSS 划掉"带删除线，三条规则全部真实渲染）。

Revealer 是无头确定性的陷阱：过渡动画期间 `is_child_revealed()` 的终值要等
动画走完。本例无头腿把过渡类型设成 `None`（动画终值即时可达），真窗口用
`SlideDown`——同一份构造函数靠一个 `headless` 参数分流。

## 26.4 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 26_gtk_layout_css
```

实测输出（`build/26_gtk_layout_css.run.out`）：

```text
==== 26 gtk 布局与 CSS 开始 ====
grid=(0,1,2,1) selected=上海 revealed=true accent=true
==== 26 gtk 布局与 CSS 结束 ====
```

`grid=(0,1,2,1)` 即 `query_child` 反查的跨两列元数据；`selected=上海` 是
FlowBox 程序选中的芯片文字（从 `selected_children()[0]` 的 child 里 downcast
Label 读出）。

## 坑位清单

- **Revealer 的动画破坏两跑一致性**：无头测试里 `set_transition_type(None)`，动画终值才逐字节稳定；真窗口再用 SlideDown。`reveals_child()`（目标态）与 `is_child_revealed()`（动画终态）是两个属性，断言用后者。
- **CSS 解析错误只走 stderr 不报错**：规则写错（比如不认识的属性）程序照常跑，样式静默不生效——`Gtk-CSS-WARNING` 才是线索。真窗口截图是视觉兜底。
- **`style_context_add_provider_for_display` 不在控件方法里**：它是 `gtk::` 下的自由函数（手动绑定层），优先级常量 `STYLE_PROVIDER_PRIORITY_APPLICATION` 也在 `gtk::` 根命名空间。
- **display 级 vs 控件级 provider 的作用域**：挂 display 全局生效；`StyleContext::add_provider` 挂单控件。全局挂 `button { ... }` 选择器会命中所有按钮——演示代码用自定义类名。
- **FlowBox 的 child 包了一层**：`selected_children()` 返回 `FlowBoxChild`，要再 `.child()` downcast 到你的 Label 才读得到文字。

---

上一章：[25 · GTK 控件、信号与 Builder](25-gtk-widgets-signals.md) ｜ 下一章：[27 · GTK 自绘：cairo 进度环](27-gtk-drawing.md) ｜ 返回：[README](../README.md)
