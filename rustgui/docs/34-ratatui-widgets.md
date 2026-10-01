# 34 · Ratatui 控件与样式

> 对应示例：[examples/34_ratatui_widgets](../examples/34_ratatui_widgets)

## 34.1 控件速览与"有状态"分野

常用控件一屏（本例全用了）：`Paragraph`（文本/wrap/scroll/对齐）、`List` +
`ListState`（选中态）、`Tabs`、`Gauge`/`LineGauge`、`Block`（边框/标题）、
`Table`（Row + 宽度约束）、`Sparkline`/`BarChart`/`Chart`/`Canvas`（35 章
专题）。文本侧是三层积木：`Span`（带样式片段）→ `Line` → `Text`，
且 `String`/`&str` 本身也 impl Widget。

**关键分野：Widget 与 StatefulWidget 是两个 trait**。List 的选中行不在
List 里——在 `ListState` 里，渲染走 `render_stateful_widget`：

```rust
// ═══ 34.1 有状态控件：状态住 ListState，渲染走 render_stateful_widget ═══
let rows: Vec<ListItem> = items.iter().map(|it| ListItem::new(row_line(it))).collect();
frame.render_stateful_widget(
    List::new(rows)
        .block(Block::bordered().title("清单"))
        .highlight_symbol("> ")
        .highlight_style(Style::new().fg(theme.accent).bold()),
    area,
    &mut app.state,   // 忘了这步就永远没有选中态
);
```

## 34.2 样式：三层 patch 与主题

`Style` 是可合成的补丁（fg/bg/add_modifier/sub_modifier），链式方法在
Style 本体（`.fg().bold().crossed_out().dim()`，不必非引 Stylize trait）。
合成语义是**叠加**：widget 级 `style` 垫底、item 级覆盖、span 级最细。
主题的做法（demo2 同款）：一个结构体集中定义颜色，全局引用：

```rust
// ═══ 34.2 完成态行：划线 + 变暗 + 主题绿（37 章待办的预演）═══
struct Theme { accent: Color, done: Color }
fn row_line(theme: &Theme, (text, done): &(String, bool)) -> Line<'static> {
    if *done {
        Line::from(Span::styled(text.clone(),
            Style::new().fg(theme.done).crossed_out().dim()))
    } else {
        Line::from(text.clone())
    }
}
```

## 34.3 无头断言的两面

**样式进断言**不需要截图——两条路：

1. **cell 级抽查**：`buffer().cell(Position).style()` 拿到完整 Style，
   断言 fg 与 modifier 位（CROSSED_OUT/DIM/BOLD）——本例的完成行、
   Tabs 高亮都这么验；
2. **扫描法**（位置无关的样式断言）：扫一行里所有 fg==主题色的 cell，
   拿到的字符序列应恰是选中标签本身——Tabs 的 padding/divider 位置
   随版本变，"染了谁"比"染在 x 几"稳。

```rust
// ═══ 34.3 扫描法：主题色染到的应恰是 "B" 本身 ═══
for x in 0..width {
    if buf.cell((x, 0)).style().fg == Some(theme.accent) {
        symbols.push_str(buf.cell((x, 0)).symbol());
    }
}
assert_eq!(symbols, "B");
```

文本面照旧整行断言：`Paragraph::scroll((1, 0))` 滚一行后
`assert_buffer_lines(["第二行…", …])`——**scroll 参数是 (y, x) 先纵后横**。

## 34.4 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 34_ratatui_widgets
```

实测输出（`build/34_ratatui_widgets.run.out`）：

```text
==== 34 ratatui 控件与样式 开始 ====
list-j=>row1 style-done=ok gauge=33% scroll=(1,0) tabs=hl+bold
==== 34 ratatui 控件与样式 结束 ====
```

证据行对账：j 后高亮符到 row1、完成行样式三要素（crossed_out/dim/绿）、
Gauge 33%（3 项 1 完成）、scroll 滚出首行、Tabs 高亮加粗——全部在
buffer 上机器判定。真终端：j/k 移动、空格勾选看划线变色、Tab 换页、
Gauge 实时跟完成度。

## 坑位清单

- **`ListState::new()` 不存在**：0.30 用 `ListState::default()` + `select(Some(i))`；`selected()` 返回 `Option<usize>`，增删后要自己 clamp。
- **忘 `render_stateful_widget`**：普通 `render_widget` 渲染 List 没有选中态——StatefulWidget 是独立 trait，编译器不提醒（两个都能编译）。
- **`Paragraph::scroll((y, x))`**：先纵后横！写成 (x, y) 是最常见的静默错误（不报错，滚错方向）。
- **布局要给够行数**：TestBackend 高度不够时 `Fill` 段被压成 0——List 整块消失、断言的行号全部漂移（本例实测 6 行压没了 List，12 行才够）。**控件坐标断言前先心算布局**。
- **Tabs 的 padding/divider 占位**：标签 x 坐标 = padding + 标签宽 + divider 宽的累加，按位置断言脆——用 34.3 的扫描法。
- **证据行字符串别嵌 `|` 等正则/格式敏感符**：check_docs 对账与 shell 转义都会少踩坑（本例把 `>` 与 `|` 排版成可读纯文本）。

---

上一章：[33 · Ratatui 布局](33-ratatui-layout.md) ｜ 下一章：[35 · Ratatui 图表与画布](35-ratatui-charts.md) ｜ 返回：[README](../README.md)
