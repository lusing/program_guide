# 14 · FTXUI 元素树：声明式范式与渲染到字符串

> 对应示例：[examples/14_ftxui_dom.cpp](../examples/14_ftxui_dom.cpp)

## 14.1 本部分范式导读：声明式元素树

本教程前两部分见过两种 UI 范式：01–07 的 wxWidgets 是**保留模式**——控件树常驻内存，状态住在控件里；08–13 的 Dear ImGui 是**即时模式**——UI 代码每帧重跑，状态住在你的变量里，但界面仍是你亲手拼出来的执行轨迹。第三部分的 FTXUI 给出第三种答案：**声明式元素树**。

| 维度 | 保留模式（01–07） | 即时模式（08–13） | 声明式（14–19） |
|---|---|---|---|
| UI 是什么 | 常驻控件对象树 | 每帧重跑的代码轨迹 | 每帧重建的不可变 Element 树 |
| 状态住哪 | 控件成员变量 | 你的变量 | 你的变量（组件拿指针共享） |
| 谁管重绘 | 库（事件驱动增量改） | 你（每帧整帧提交） | 库（新旧 Screen diff 后只写差异） |

FTXUI 与 imgui 同属"每帧重来"的阵营，路线却相反：imgui 是**命令式重跑**——你手写 `if (Button(...)) counter++`，UI 结构是执行出来的；FTXUI 是**纯声明**——你用 `vbox({hbox({...})})` 这样的表达式描述一棵不可变树，组件树每帧求值出新的一棵 Element 树，`Render` 进 Screen 后与旧屏 diff，只把变化的像素写进终端，"TUI 里的 React"。树本身无状态、可随意丢弃重建；状态全在你的 `int`/`std::string`/`std::vector` 里，界面只是状态的纯函数投影。

本例刻意不进终端交互循环：五棵小元素树全部**渲染成字符串再打印**。宽度钉死、输出确定，可直接进文档、可用两跑一致性验证——这是本教程 FTXUI 章的标准验证形态（15 章起才进真实终端循环）。

## 14.2 验证形态先行：渲染到字符串

```cpp
// ═══ 14.1 渲染到字符串：宽度钉死，输出才确定 ═══
static std::string RenderToString(Element document, int width = 64) {
    auto screen = Screen::Create(Dimension::Fixed(width), Dimension::Fit(document));
    Render(screen, document);
    return screen.ToString();
}
```

`Element` 是树的根（`shared_ptr` 别名），由 `text`/`vbox`/`border` 等工厂组合而成、建好即不可变。`Screen::Create` 收两个维度：宽度 `Dimension::Fixed(64)` 钉死 64 列，高度 `Dimension::Fit(document)` 按树的自身需求自适应。`Render(screen, document)` 把树栅格化进屏幕缓冲，`ToString()` 吐出带 ANSI 颜色转义的字符串。宽度若不钉死，输出随终端宽度漂移——框线宽、gauge 格数全变，文档引用与两跑比对都保不住（坑位清单第 2 条）。

## 14.3 基本元素与装饰管道：text | border | center

```cpp
// ═══ 14.2 text 与装饰管道 ═══
auto doc = text("你好，FTXUI！\n声明式 TUI：\n界面 = 一棵不可变元素树") | border | center;
std::cout << "-- 1) text/border/center --\n" << RenderToString(doc) << "\n";
```

`text` 接受 UTF-8 字符串，内嵌 `\n` 即多行。装饰本身是函数，`|` 是应用管道：从右往左依次套——先 `center`（在给定空间内整体居中），再 `border` 画框（master 的默认边框已是圆角 `╭╮╰╯`）。输出第 1 段里三行中文整体居中于 64 列屏，右边框整列对齐——FTXUI 按 wcwidth 计算汉字占 2 列，混排不破框。

## 14.4 盒式布局与弹性占位：vbox / hbox / filler

```cpp
// ═══ 14.3 vbox/hbox/filler：九宫格骨架 ═══
auto doc = vbox({
    hbox({text("north-west"), filler(), text("north-east")}),
    filler(),
    hbox({filler(), text("center"), filler()}),
    filler(),
    hbox({text("south-west"), filler(), text("south-east")}),
}) | border;
```

`vbox`/`hbox` 纵排/横排子元素；`filler()` 是弹性占位元素，专职吃掉剩余空间——五个 filler 拼出经典九宫格（输出第 2 段）。弹性还有装饰形态 `| flex`：让元素**有资格**参与分配剩余空间，下一节的 gauge 全靠它铺满。

## 14.5 gauge 进度条与 separator 分隔线

```cpp
// ═══ 14.4 gauge 靠 | flex 吃满剩余宽度 ═══
auto doc = vbox({
    hbox({text("下载:"), gauge(0.42f) | flex, text(" 42%")}),
    separator(),
    hbox({text("上传:"), gauge(0.87f) | flex, text(" 87%")}),
    separatorDouble(),
    text("separator / separatorDouble 分隔线"),
}) | border;
```

`gauge(p)` 画比例 p 的进度条；不接 `| flex` 它就按自身需求（0 列）塌着。输出第 3 段里 gauge 单元格宽 53 列（62 内容列减去标签与百分号文本），42% 取整为 22 格 █、87% 为 46 格——比例精确换算成字符格。`separator()` 单线在框内呈现为 `├──┤`、`separatorDouble()` 双线 `╞══╡`：分隔线自动与左右边框焊接，不是手画的。

## 14.6 graph：把函数画成终端曲线

```cpp
// ═══ 14.5 GraphFunction 返回每列填充高度 ═══
auto sine = [](int width, int height) {
    std::vector<int> output(width);
    for (int i = 0; i < width; ++i)
        output[i] = static_cast<int>((std::sin(i * 2 * 3.14159f / width) * 0.5f + 0.5f) * (height - 1));
    return output;
};
auto doc = vbox({
    text("graph(sine)："),
    graph(sine) | size(HEIGHT, EQUAL, 7),
}) | border;
```

`GraphFunction` 的签名是 `std::vector<int>(int width, int height)`：返回的不是坐标点集，而是**每列的填充高度**（从底往上数够几行）——正弦先抬到 [0,1] 区间再乘高度，输出第 4 段自上而下七行各填 11/19/26/32/38/46/62 格，最后一行整行填满（曲线最低处也 ≥ 0）。`size(HEIGHT, EQUAL, 7)` 把画幅钉成 7 行。

第 5 段"综合面板"把这些元素再嵌一层：左边 `[F1] 帮助` 信息块与右边磁盘/内存仪表块靠 `filler()` 左右拉开；右侧 `size(WIDTH, EQUAL, 30)` 钉宽，块内两个 gauge 无装饰、按分配到的剩余宽度伸展——一棵树的嵌套组合就是全部版面工作。

## 14.7 运行与输出

FTXUI 示例同为**控制台子系统**，selftest 证据直接写 stdout；本例是纯输出型，`--selftest` 与正常运行同一通路。构建与单例验证：

```bash
cd cppgui
pwsh build.ps1 -Example 14_ftxui_dom
```

selftest 实测输出（`build/docs-ref/14_ftxui_dom.out`，UTF-8；剥行尾 CR 后原样引用，框线未重画）：

```text
==== 14 FTXUI DOM 基础 开始 ====
-- 1) text/border/center --
                   ╭───────────────────────╮                    
                   │你好，FTXUI！          │                    
                   │声明式 TUI：           │                    
                   │界面 = 一棵不可变元素树│                    
                   ╰───────────────────────╯                    
-- 2) vbox/hbox/filler --
╭──────────────────────────────────────────────────────────────╮
│north-west                                          north-east│
│                            center                            │
│south-west                                          south-east│
╰──────────────────────────────────────────────────────────────╯
-- 3) gauge/separator --
╭──────────────────────────────────────────────────────────────╮
│下载:██████████████████████                                42%│
├──────────────────────────────────────────────────────────────┤
│上传:██████████████████████████████████████████████        87%│
╞══════════════════════════════════════════════════════════════╡
│separator / separatorDouble 分隔线                            │
╰──────────────────────────────────────────────────────────────╯
-- 4) graph --
╭──────────────────────────────────────────────────────────────╮
│graph(sine)：                                                 │
│          ███████████                                         │
│      ███████████████████                                     │
│   ██████████████████████████                                 │
│████████████████████████████████                              │
│███████████████████████████████████                        ███│
│███████████████████████████████████████                ███████│
│██████████████████████████████████████████████████████████████│
╰──────────────────────────────────────────────────────────────╯
-- 5) 综合面板 --
╭──────────╮                      ╭────────────────────────────╮
│[F1] 帮助 │                      │磁盘                        │
│[F2] 保存 │                      │████████                    │
│[F10] 退出│                      │内存                        │
│          │                      │█████████████████           │
╰──────────╯                      ╰────────────────────────────╯
==== 14 FTXUI DOM 基础 结束 ====
```

五段输出与 14.3–14.6 的五棵树一一对应。两个细节值得指认：其一，所有右边框整列对齐——汉字按 wcwidth 占 2 列，Screen 栅格化时按显示宽度补空，混排才不破框；其二，各段右侧的尾随空格是 Screen 按 64 列整宽栅格化的产物，属于输出的一部分，逐字节引用时不能裁。

## 坑位清单

- **GraphFunction 的形状是 `vector<int>(int width, int height)`**：返回量是"每列从底往上填充几行"，不是坐标对列表。按"画点集"理解会把曲线上下镜像甚至挤出画布（首例批次实测记录，git 420977f）。
- **渲染到字符串必须钉宽度**：`Screen::Create(Dimension::Fixed(64), Dimension::Fit(document))`——宽度交给终端协商则同一棵树在不同终端里框线宽度、gauge 格数全漂，文档与两跑一致性都无从谈起（源码 14_ftxui_dom.cpp 头注释）。
- **`Screen::ToString()` 自带 CRLF，Windows 管道再叠一层成 `\r\r\n`**：.out 文件里每条渲染行行尾两个 CR，引用与比对都须剥行尾 CR（build.ps1 两跑判定同样 `-replace '\r',''`）；行内字节与尾随空格是内容，必须原样保留（.out 字节级核查）。

---

上一章：[13 · 综合实战：迷你系统监视器](13-imgui-app.md) ｜ 下一章：[15 · FTXUI 组件体系与事件循环](15-ftxui-components.md) ｜ 返回：[README](../README.md)
