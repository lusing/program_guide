# 33 · Ratatui 布局：Constraint 与 Flex

> 对应示例：[examples/33_ratatui_layout](../examples/33_ratatui_layout)

## 33.1 约束求解：第五种布局答案

egui 用 Panel 谈判、iced 用 Length、Slint 用布局盒、GTK 用容器控件——
ratatui 的答案是 **cassowary 约束求解**：你声明"我要什么"（一组
`Constraint`），求解器算"摆哪里"。六种约束：

| Constraint | 语义 |
|---|---|
| `Length(n)` | 恰好 n 列/行 |
| `Min(n)` / `Max(n)` | 下限 / 上限（可被压缩/让位） |
| `Percentage(p)` | 区域的百分比 |
| `Ratio(a, b)` | 比例（精度高于 Percentage） |
| `Fill(n)` | 弹性吃剩余空间（按权重均分，0.29+ 新成员） |

```rust
// ═══ 33.1 新式分割：area.layout::<N> 直接解构（数量错编译期炸）═══
let [title, body, status] = area.layout(&Layout::vertical([
    Constraint::Length(3),   // 标题占 3 行
    Constraint::Fill(1),     // 主体弹性
    Constraint::Length(1),   // 状态栏 1 行
]));
```

`Layout::split` 也还在，但返回 `Rc<[Rect]>`——`try_into()` 成数组在 0.30
编不过（老教程的 `.split(area)[0]` 索引写法仍可用，新代码建议
`area.layout::<N>` 的数组解构）。

## 33.2 Flex：多余空间的分配策略

约束说了"块要多大"，**Flex 说剩下的空间怎么摆**。40 列终端里放
`Length(16) + Length(12)`（余 12 列），七种策略的**实测矩阵**：

```text
flex:Legacy=0 Start=0 End=0 Center=0 SpaceBetween=12 SpaceAround=6 SpaceEvenly=4
```

- `Legacy`/`Start`/`End`/`Center`：两块**紧贴**（gap=0），余量全垫尾/尾/头/两头；
- `SpaceBetween`：余量全塞中间（gap=12）；
- `SpaceAround`（0.30 新语义）：`两端各 3 + 中间 6`——**中间是两端的二倍**，
  老教程的"均匀围绕"观感现在要用 SpaceEvenly；
- `SpaceEvenly`：三段均分（4+4+4）。

这个矩阵不是抄文档——是 selftest 对七种 Flex 各渲染一次、扫边框列号算出来的
（33.4），断言进证据行，机器判卷。

## 33.3 popup：Clear + 居中矩形

```rust
// ═══ 33.3 弹层三步：Clear 清底层 → 画边框 → 收缩内边距放内容 ═══
if app.popup {
    let popup = area.centered(Constraint::Percentage(60), Constraint::Percentage(30));
    frame.render_widget(Clear, popup);          // 顺序反了底层会"透"出来
    frame.render_widget(Block::bordered().title("弹出层"), popup);
    let inner = popup.inner(Margin::new(2, 2)); // 2 列/行内边距
    frame.render_widget(Paragraph::new("按 p 关闭弹层"), inner);
}
```

`Rect::centered` 是 0.30 的便捷方法（另有 `centered_horizontally` /
`centered_vertically`）。**取整陷阱**（实测）：高 10 的 30% 是 3 行，
`(10-3)/2 = 3.5` ——centered 会取整到 **4**，弹层左上角在 (8,4) 而不是
(8,3)。断言坐标时拿半行取整当回事。

## 33.4 无头剧本：边框扫描法

Flex 矩阵的断言思路：`Block::bordered` 的边框字符就是**布局的可观测投影**——
扫描一行里的竖线列号，第 1/2 条是左块的左右边框、第 3 条是右块左边框，
间隙 = 第 3 条 − 第 2 条 − 1：

```rust
// ═══ 33.4 布局断言 = 边框列号扫描（与两块具体位置无关）═══
let bars = collect_cols(buf, 5, "│", 40, 3);
let gap = bars[2] - bars[1] - 1;
```

（第一版探针从 x=0 找"第一个 │"当左边框——End/Center 布局下左块不在
x=0，全矩阵测出同一个错值。按**序号**数边框才与位置无关，这是扫描法的
关键。）

## 33.5 运行与输出

```bash
cd G:\code\guide\rustgui
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 33_ratatui_layout
```

实测输出（`build/33_ratatui_layout.run.out`）：

```text
==== 33 ratatui 布局 开始 ====
flex:Legacy=0 Start=0 End=0 Center=0 SpaceBetween=12 SpaceAround=6 SpaceEvenly=4 popup=(8,4)
==== 33 ratatui 布局 结束 ====
```

真终端（`cargo run`）：三窗格 + 左右两块，`f` 轮换七种 Flex 看间隙流动、
`p` 开关弹层、`q` 退出。

## 坑位清单

- **`split` 返回 `Rc<[Rect]>`，数组 `try_into` 编不过**：0.30 的数组解构走 `area.layout::<N>(&layout)`（const 泛型，数量不匹配编译期暴露）；老式 `split(area)[0]` 索引仍可用。
- **`Flex::SpaceAround` 语义 0.30 变了**：中间 spacer 是两端的二倍（实测 3+6+3）；要"均匀围绕"的旧观感用 `SpaceEvenly`。老教程截图全部对不上。
- **`centered` 的半行取整**：(10−3)/2=3.5 → y=4。断言弹层坐标先实测，或避开奇数半行的尺寸组合。
- **`Buffer::cell` 吃 `Position`（u16）不是 usize 元组**；`symbol()` 返回 `&str`，与 `char` 比较要写成与单字符字符串比。
- **边框扫描按序号不按位置**：块的水平位置随 Flex 变，"第 N 条边框"才是稳定坐标系（本章探针的真实翻车）。
- **popup 忘画 `Clear`**：底层内容透出来——Clear 是独立 widget，先 Clear 再画，不是 Block 的属性。

---

上一章：[32 · Ratatui 最小应用](32-ratatui-hello.md) ｜ 下一章：[34 · Ratatui 控件与样式](34-ratatui-widgets.md) ｜ 返回：[README](../README.md)
