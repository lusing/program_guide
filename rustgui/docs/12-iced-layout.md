# 12 · iced 布局：Length、Container 与坐标驱动

> 对应示例：[examples/12_iced_layout](../examples/12_iced_layout)

## 12.1 Length 三态：弹性盒的货币

iced 的 row/column 是弹性盒，子项怎么分空间由 `Length` 决定：

| Length | 语义 | 典型用途 |
|---|---|---|
| `Shrink` | 随内容收缩（默认） | 文本、按钮 |
| `Fill` | 吃掉剩余空间（多份 Fill 平分） | 弹性空白、表格列 |
| `FillPortion(n)` | 按 n 份比例吃剩余 | 2:1 分栏 |
| `Fixed(px)` | 定死 | 高度栏、分隔带 |

```rust
// ═══ 12.1 两端对齐：Shrink 文本夹 Fill 空白 ═══
let top_bar = row![
    text("左端"),
    Space::new().width(Length::Fill), // 0.14：Space 构造器无参，尺寸走 builder
    text("右端"),
]
.padding(8)
.width(Length::Fill);
```

`Space` 是"只占位的控件"（0.14 起构造器无参，`Space::new().width(Length::Fill)` 即水平弹簧；也有 `Space::horizontal()/vertical()` 快捷方式）。

## 12.2 Container：对齐与装饰的容器

`Container` 管两件事——**把孩子放在哪**（center/align_left/align_top…）与**给孩子套什么**（padding/border/背景）。对齐方法是"轴向 + 填充量"的组合：

```rust
// ═══ 12.2 居中 vs 左对齐：同一按钮的两种摆法 ═══
let centered = container(button("切换对齐").on_press(Message::SwitchAlignment))
    .center(Length::Fill)              // 两轴居中，容器本身吃满剩余空间
    .height(Length::Fixed(120.0));

let left = container(button("切换对齐").on_press(Message::SwitchAlignment))
    .width(Length::Fill)
    .height(Length::Fixed(120.0))
    .align_left(Length::Shrink);       // 孩子靠左，纵向默认居中
```

`center(Fill)` = `center_x(Fill) + center_y(Fill)`。注意对齐参数给的是**容器自己的 Length**——先决定容器多大，再谈孩子在容器里怎么摆。

## 12.3 scrollable：急切布局与可见性

iced 的 `scrollable` 默认**急切布局**：全部子项都被布局、都在控件树里（对比 egui 表格的虚拟化——视口外根本不进树）。但**在不在树里**与**能不能点**是两回事：

```rust
let rows = scrollable(
    column((0..20).map(|i| {
        button(text(format!("行 {i}"))).on_press(Message::RowSelected(i)).into()
    }))
    .spacing(4),
)
.height(Length::Fixed(220.0));
```

无头测试实测：`click("行 1")`（视口内）成功；`click("行 19")`（滚出视口）报 **`TargetNotVisible`**——iced_test 拒绝点击 `visible_bounds` 为 `None` 的目标。范式对照：

| | egui 表格（06 章） | iced scrollable（本章） |
|---|---|---|
| 视口外的行 | 不进控件树（虚拟化，省布局） | 进树（急切布局），但被裁剪 |
| 无头点击 | 查无此节点 | `TargetNotVisible` |
| 突破方式 | 滚动后再查 | 滚动（改 translation）后再点 |

## 12.4 Point 选择器的真实语义与坐标注入

第三种选择器 `Point`——按几何坐标找控件。实测两条语义：

1. **`find(Point)` 返回最外层命中者**：DFS 从根开始，根 Container 抢先命中——查任意点几乎总是拿到整窗容器；
2. **`click(Point)` 点的是命中目标的中心**：命中根容器 → 实际点击落在**窗口中心**，而不是你给的坐标。

所以"点 pick_list 这种自绘控件"的正确姿势是**锚点推导 + 原始事件注入**：

```rust
// ═══ 12.4 从可查询锚点推导坐标，再按坐标注入点击 ═══
use iced_test::selector::Text as TextTarget;

// 锚点：能被 &str 查到的文本（带 bounds）
let (cx, cy) = match ui.find("切换对齐")? {
    TextTarget::Raw { bounds, .. } | TextTarget::Input { bounds, .. } => {
        (bounds.x + bounds.width / 2.0, bounds.y + bounds.height / 2.0)
    }
};

// 按坐标注入完整点击：光标就位 → 按下 → 释放。
// 事件按坐标做命中测试，会落进该位置最深层控件。
use iced::mouse::{self, Button};
ui.simulate([
    iced::Event::Mouse(mouse::Event::CursorMoved { position: Point::new(cx, cy) }),
    iced::Event::Mouse(mouse::Event::ButtonPressed(Button::Left)),
    iced::Event::Mouse(mouse::Event::ButtonReleased(Button::Left)),
]);
```

调试布局还有个免工具技巧：`Element::explain(color)` 给整个界面画布局边框（`.explain(Color::RED)` 加在 view 返回值上），配合 `format!("{target:?}")` 打印 bounds 排版问题一目了然。

## 12.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_iced_layout
```

实测输出（`build/12_iced_layout.run.out`）：

```text
==== 12 iced 布局与定位 开始 ====
selected_row=Some(1) centered=false
==== 12 iced 布局与定位 结束 ====
```

真窗口里滚一滚列表、拖一拖窗口宽度看 Fill 如何重新分配、点"切换对齐"看按钮在演示区里左右横跳、开一开 pick_list（它的无头驱动难题见坑位）。

## 坑位清单

- **click(Point) 点不到你给的坐标**：高层语义是"点【命中目标】的中心"，而 Point 先命中根容器——等于永远点窗口中心。按坐标驱动必须走 `simulate()` 原始事件（12.4 的三连击模式）。
- **pick_list 无头驱动双重阻塞**：文本自绘不进候选树（11 章）+ Point 高层语义失效（本章）——只能 `simulate` 坐标注入或留人工验证。选型启示：要自动化的表单用按钮组。
- **视口外的控件点不得**：急切布局让它们在树里，但 `visible_bounds: None` 时 iced_test 抛 `TargetNotVisible`。断言"看不见"可以（find 报错即证明），点击不行。
- **Space 构造器 0.14 无参**：`Space::new(w, h)` 已改 `Space::new().width(..).height(..)`。
- **if/else 两分支容器类型不同**：`.center(Fill)` 与 `.align_left(Shrink)` 返回不同 `Container` 配置——先各 `.into()` 成 `Element<'_, Message>` 再汇合，否则 E0283 类型推断失败。

---

上一章：[11 · iced 表单控件与 id 定位](11-iced-widgets.md) ｜ 下一章：[13 · iced 主题与样式系统](13-iced-style.md) ｜ 返回：[README](../README.md)
