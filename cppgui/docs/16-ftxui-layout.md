# 16 · FTXUI 布局进阶：约束、弹性与网格

> 对应示例：[examples/16_ftxui_layout.cpp](../examples/16_ftxui_layout.cpp)

## 16.1 size()：尺寸约束三维组

14 章的 vbox/hbox 解决"怎么排"，本章解决"排多大"。第一件工具是 `size(方向, 约束, 数值)`：

```cpp
// ═══ 16.1 size：方向 × 约束 × 数值 ═══
hbox({
    text("w10") | size(WIDTH, EQUAL, 10) | border,
    text("w20") | size(WIDTH, EQUAL, 20) | border,
    text("上限6") | size(WIDTH, LESS_THAN, 6) | border,
}),
hbox({
    text("高 3") | size(HEIGHT, EQUAL, 3) | border,
    text("高 5") | size(HEIGHT, EQUAL, 5) | border,
}),
```

约束有三种：`EQUAL` 恰好、`LESS_THAN` 上限、`GREATER_THAN` 下限。输出第 1 段：w10/w20 分别钉住 10/20 列内容宽（边框另加 2 列），"上限6"内容 5 列 < 6，原样通过。第 2 段更有意思：`EQUAL` 只是**自身需求**，hbox 的交叉轴会把矮的拉到与高者齐——"高 3"的框最终也是 7 行（5 内容行 + 上下边框）。**master 的 Constraint 只有这三种，`PERCENT` 已删**（坑位第 1 条），按比例布局改用 `flex` 权重。

## 16.2 FlexboxConfig：CSS 式布局器

```cpp
// ═══ 16.2 flexbox：gap 与 justify_content 都在 config 里 ═══
FlexboxConfig config;
config.gap_x = 1;                  // 元素横向间隙 1 列
config.gap_y = 0;
config.justify_content = FlexboxConfig::JustifyContent::SpaceBetween;
auto doc = flexbox({
    text("A") | border,
    text("B") | border,
    text("C") | border,
}, config);
```

`flexbox` 是完整的 CSS flex 实现：`gap_x`/`gap_y` 控制元素间距（单位是终端列/行），`justify_content` 定主轴分布（`SpaceBetween` 两端对齐均分空隙），另有 `align_items` 管交叉轴、`wrap` 管换行。字段名照搬 CSS 全名 `justify_content`，不是直觉缩写（坑位第 2 条）。输出第 2 段（40 列渲染宽）三个单字符框均匀分立两端与中间，间隙正是 1 列 gap 的叠加。

## 16.3 Gridbox：二维网格

```cpp
// ═══ 16.3 gridbox：外层是行的向量，行内自动 hbox ═══
auto cell = [](const char* t) { return text(t) | border | size(WIDTH, EQUAL, 8); };
auto doc = gridbox({
    { cell("r1c1"), cell("r1c2"), cell("r1c3") },
    { cell("r2c1"), cell("r2c2"), text("跨行内容") | border },
}) | size(WIDTH, EQUAL, 36);
```

`gridbox` 的参数是"行的向量"——每行一个元素向量，行内自动按 hbox 组织，行列交叉处自动对齐：输出 18–23 行里两行三列的框缘全部对齐成矩形阵列，第 3 列两个 8 列宽的格（`EQUAL 8` 的 cell 与 4 个汉字的"跨行内容"）恰好等宽。没有 colspan/rowspan——"跨"的效果靠行列的宽度高度协商自然出现。

## 16.4 hflow / vflow：内容自动折行

```cpp
// ═══ 16.4 hflow：宽度不够就换行 ═══
auto tag = [](int i) { return text(" 标签" + std::to_string(i)) | border; };
Elements tags;
for (int i = 1; i <= 6; ++i) tags.push_back(tag(i));
auto doc = hflow(std::move(tags));
```

`hflow` 横向排布、放不下自动折行（`vflow` 纵向同理）。40 列渲染宽下，6 个 8 列宽的标签框只装得下 5 个，第 6 个整体折到第二行（输出 25–27 行）——标签云、工具栏的自适应换行就用它。与 flexbox 的 wrap 相比，hflow 面向"同质小元素流"，配置更省。

## 16.5 dbox 叠放与 window 窗框

```cpp
// ═══ 16.5 dbox：多层叠放（背景层 + 前景层）═══
auto bg = [] {
    Elements e;
    for (int i = 0; i < 5; ++i) e.push_back(text("████████████████████████"));
    return vbox(std::move(e)) | color(Color::Blue);
}();
auto fg = vbox({
    text(""),
    text("  前景层叠在背景上  ") | bgcolor(Color::GrayDark) | color(Color::White),
});
auto doc = dbox({ bg, fg });

// ═══ 16.6 window：标题嵌在顶边框上 ═══
auto doc = window(text("会话"),
    vbox({ text("alice: 你好"), text("bob: 在吗"), text("alice: …") }));
```

`dbox` 把多个元素叠进同一矩形：后画的盖先画的，前景层的空格不遮下层（输出 29–33 行：蓝色 █ 背景上盖一行灰底白字）。这是模态阴影、状态角标、画中画的底层原语——18 章的 `Modal` 本质就是 dbox 叠放加事件改道。注意叠放层的颜色就是真 ANSI 转义：输出第 5 段里蓝前景 `\x1b[34m` 与亮黑背景 `\x1b[100m` 原样可见（17 章展开颜色系统）。`window(title, body)` 则是 TUI 的"窗口"隐喻：标题文本直接嵌在顶边框线上（`╭会话────`），比 border 多一层标题语义。

## 16.6 ResizableSplit：交互式分割条

```cpp
// ═══ 16.7 ResizableSplitLeft：鼠标拖动的分割条 ═══
int left_size = 20;
auto left = Renderer([&] { return text("左面板") | border | ftxui::color(Color::Cyan); });
auto right = Renderer([&] { return text("右面板（拖中间的 | 调整）") | border; });
auto split = ResizableSplitLeft(left, right, &left_size);
auto app = CatchEvent(split, [&](Event e) {
    if (e == Event::Character('q') || e == Event::Escape) { screen.Exit(); return true; }
    return false;
});
screen.Loop(app);
```

`ResizableSplitLeft(左, 右, &尺寸)` 在两块之间放一条可拖动的 `│` 分割条，左块宽度又是"你的变量 + 指针"。它是**交互组件**：静态渲染只能看到初始 20 列的一帧，拖动必须靠鼠标事件循环——渲染到字符串管线验证不了它，因此 selftest 段打印占位行跳过实跑，交互验证走 `App::FitComponent()` 的真实循环（坑位第 3 条）。

## 16.7 运行与输出

构建与单例验证：

```bash
cd cppgui
pwsh build.ps1 -Example 16_ftxui_layout
```

selftest 实测输出（`build/docs-ref/16_ftxui_layout.out`；剥行尾 CR 后原样引用）：

```text
==== 16 FTXUI 布局进阶 开始 ====
-- 1) size 约束 --
╭──────────╮╭────────────────────╮╭─────╮                       
│w10       ││w20                 ││上限6│                       
╰──────────╯╰────────────────────╯╰─────╯                       
╭────╮╭────╮                                                    
│高 3││高 5│                                                    
│    ││    │                                                    
│    ││    │                                                    
│    ││    │                                                    
│    ││    │                                                    
╰────╯╰────╯                                                    
-- 2) flexbox SpaceBetween --
╭─╮               ╭─╮                ╭─╮
│A│               │B│                │C│
╰─╯               ╰─╯                ╰─╯
-- 3) gridbox --
╭──────╮╭──────╮╭────────╮                                      
│r1c1  ││r1c2  ││r1c3    │                                      
╰──────╯╰──────╯╰────────╯                                      
╭──────╮╭──────╮╭────────╮                                      
│r2c1  ││r2c2  ││跨行内容│                                      
╰──────╯╰──────╯╰────────╯                                      
-- 4) hflow（宽 40 内自动折行）--
╭──────╮╭──────╮╭──────╮╭──────╮╭──────╮
│ 标签1││ 标签2││ 标签3││ 标签4││ 标签5│
╰──────╯╰──────╯╰──────╯╰──────╯╰──────╯
-- 5) dbox 叠放 --
[34m[49m████████████████████████      [39m[49m
[97m[100m  前景层叠在背景上  ████      [39m[49m
[34m[49m████████████████████████      [39m[49m
[34m[49m████████████████████████      [39m[49m
[34m[49m████████████████████████      [39m[49m
-- 6) window --
╭会话────────────────────────╮
│alice: 你好                 │
│bob: 在吗                   │
│alice: …                    │
╰────────────────────────────╯
-- 7) ResizableSplit：交互组件，selftest 跳过实跑 --
==== 16 FTXUI 布局进阶 结束 ====
```

前六段对应 16.1–16.5 的六棵静态树，第 7 段是交互组件的占位说明。注意各段行尾的尾随空格宽窄不一——第 1、3 段按 64 列栅格化补白，第 2、4 段是 40 列、第 5、6 段是 30 列，正是各次 `RenderToString(doc, n)` 传入的宽度；第 5 段（dbox）的颜色转义字节夹在 █ 字符之间，逐字节引用时不可增删。

## 坑位清单

- **Constraint 没有 PERCENT**：master 删掉了百分比约束，`size(WIDTH, PERCENT, 50)` 直接编不过——按比例改用 `| flex` 权重或先 Fixed 再交给容器分配（源码 16_ftxui_layout.cpp【坑】注释；提交 2472096 实测收录）。
- **FlexboxConfig 的字段名是 justify_content**：CSS 全名照搬（同族还有 align_items、gap_x/gap_y），写成 justify/align 编不过（提交 2472096 实测收录）。
- **ResizableSplit 进不了渲染到字符串管线**：它是鼠标交互组件，静态帧只能证明初始分割，拖动语义必须真实事件循环；selftest 只能跳过实跑打占位行（源码 selftest 分支注释；本章输出第 7 段）。
- **EQUAL 约束挡不住交叉轴拉伸**：`size(HEIGHT, EQUAL, 3)` 是自身需求，放在 hbox 里仍会被拉到与最高的兄弟齐高（本章输出第 1 段"高 3"框实际 7 行）——想要"绝不拉伸"得换 dbox/window 等不参与协商的容器。

---

上一章：[15 · FTXUI 组件体系与事件循环](15-ftxui-components.md) ｜ 下一章：[17 · FTXUI 样式系统与 Canvas 画布](17-ftxui-style-canvas.md) ｜ 返回：[README](../README.md)
