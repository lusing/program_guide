# 10 · 窗口系统：Begin/End、标志与子窗口

> 对应示例：[examples/10_imgui_windows.cpp](../examples/10_imgui_windows.cpp)

## 10.1 Begin/End 对与它的返回值

imgui 里"窗口"是 `Begin/End` 包出的一段每帧代码，不是对象。`Begin` 的返回值语义是**本帧窗口是否展开**（非 collapsed、且未被完全裁出屏幕）：

```cpp
// ═══ 10.1 Begin 返回 false 也要无条件 End ═══
ImGui::Begin("layout-cursor", &g_showA, ImGuiWindowFlags_NoCollapse);
// ... 窗口内容 ...
ImGui::End();
```

折叠时 `Begin` 返回 false，跳过内容可以省 CPU，但 **`End()` 必须无条件调用**——`Begin/End` 是一对结构化包裹（内部维护窗口栈），漏了 End 帧结构就散了。第二个参数 `&g_showA` 是可选的"关闭按钮"：窗口右上角出现 ×，点击后 imgui 把这个 bool 置 false——关窗的"状态"还是你的变量，惯用法是下一帧用 `if (g_showA) { Begin(...); ...; End(); }` 整体跳过这段窗口代码（本例教学演示保持常开）。窗口的**显隐由此定义**：本帧调了 Begin 就存在，没调就消失——没有 Show/Hide，也没有控件树挂载。渲染次序同样朴素：**后 Begin 的窗口画在上层**，13 章四面板的覆盖关系就是书写顺序。

第三个参数是窗口标志，本章 10.4 展开。

## 10.2 布局推进光标：主窗口走读

```cpp
// ═══ 10.2 SameLine/Spacing/Indent：排版光标的全部手段 ═══
ImGui::Text("normal flow");
ImGui::SameLine();                       // 折回行首右侧
ImGui::Text("after SameLine");
ImGui::Spacing(); ImGui::Spacing();      // 垂直留白
ImGui::Indent(20.0f);                    // 右缩进
ImGui::Text("indented by 20");
ImGui::Unindent(20.0f);

// ═══ 10.3 老式 Columns（表格见 11 章）═══
ImGui::Columns(3, "cols", true);
for (int r = 0; r < 2; ++r)
    for (int c = 0; c < 3; ++c)
    {
        ImGui::Text("cell %d-%d", r, c);
        ImGui::NextColumn();
    }
ImGui::Columns(1);                       // 结束列模式
```

从 wx 过来的最大心态转变在这里：**没有布局管理器**。03 章的 sizer、07 章的容器嵌套都不存在——控件函数推进一个光标，`SameLine/Spacing/Indent/Unindent/Separator` 就是全部排版手段，想要"两控件重叠"这种自由排版只能去 12 章的 DrawList。`Columns` 是 legacy 列布局（无表头无排序），现代代码请直接用 11 章的 Tables API，此处仅作对照保留。

## 10.3 SetNextWindowPos/Size 与 ImGuiCond

```cpp
// ═══ 10.4 FirstUseEver：只在窗口第一次出现时定位 ═══
ImGui::SetNextWindowPos(ImVec2(30, 30), ImGuiCond_FirstUseEver);
ImGui::SetNextWindowSize(ImVec2(420, 430), ImGuiCond_FirstUseEver);
ImGui::Begin("layout-cursor", &g_showA, ImGuiWindowFlags_NoCollapse);

// ═══ 10.5 Always：每帧生效——"钉住"演示 ═══
ImGui::SetNextWindowPos(ImVec2(g_posx, g_posy), ImGuiCond_Always);   // Always=每帧
ImGui::SetNextWindowSize(ImVec2(220, 110), ImGuiCond_Always);
ImGui::Begin("pinned", nullptr, ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoCollapse
                                   | ImGuiWindowFlags_NoSavedSettings);
ImGui::SliderFloat("x", &g_posx, 0, 600);
ImGui::SliderFloat("y", &g_posy, 0, 400);
ImGui::Text("NoResize+NoCollapse+NoSavedSettings");
ImGui::End();
```

`SetNextWindowPos/Size` 只对**紧跟的那一次 Begin** 生效，配套的 `ImGuiCond` 决定生效频次：`FirstUseEver` 只在窗口首次出现时定位（之后归用户和 ini 管），`Always` 每帧覆盖（本例 "pinned" 窗口的位置被滑条每帧改写，演示"程序控位"），`Appearing` 则在每次从隐藏恢复时生效。自测输出的 `pinned pos=40,60` 正是 g_posx/g_posy 的初值——selftest 无人拖动，Always 每帧钉回原地。

## 10.4 窗口标志对照与 ini 持久化

```cpp
// ═══ 10.6 三个常用标志的形态差异 ═══
ImGui::Begin("flags-demo", &g_showB, ImGuiWindowFlags_AlwaysAutoResize);
ImGui::Text("AlwaysAutoResize: 窗口随内容自适应");
ImGui::BulletText("try drag/collapse me");
ImGui::End();
```

| 标志 | 效果 | 典型用途 |
|---|---|---|
| `NoResize` | 去掉右下角拖拽柄 | 固定尺寸面板 |
| `NoCollapse` | 去掉折叠双箭头 | 主面板不许折叠成标题条 |
| `AlwaysAutoResize` | 每帧按内容自适应尺寸 | 小工具/气泡式面板 |
| `NoSavedSettings` | 不写入 imgui.ini | 一次性/演示窗口 |

标志可按位或组合（"pinned" 窗口一次叠了三个）。`NoSavedSettings` 背后是 imgui 的自动持久化：默认把每个窗口的位置/尺寸/折叠态写进**工作目录的 imgui.ini**——纯文本格式，每个窗口一小段 `Pos=/Size=/Collapsed=` 记录，下次启动自动还原（真实应用的"界面记忆"白送）。`io.IniFilename` 可改路径，置 `nullptr` 即全关。这对真实应用是福利，对教程是麻烦——示例窗口位置跨进程残留会让"首次定位"演示失真，所以本例凡是不想留状态的窗口都戴上了 `NoSavedSettings`；08 章两个骨架示例同理会在构建目录留下 imgui.ini，属预期行为而非垃圾文件。

## 10.5 ChildWindow：窗口内的独立滚动区

```cpp
// ═══ 10.7 BeginChild：嵌套滚动区，宽度 -1 撑满 ═══
if (ImGui::BeginChild("scrollbox", ImVec2(-1, 120), ImGuiChildFlags_Borders))
{
    for (int i = 0; i < 30; ++i)
        if (ImGui::Selectable(std::to_string(i).c_str(), g_childScrollItem == i))
            g_childScrollItem = i;
}
ImGui::EndChild();                       // 与 BeginChild 严格配对
ImGui::Text("selected: %d", g_childScrollItem);
```

ChildWindow（子窗口）是**窗口内的独立滚动区域**：有自己的滚动条、自己的 ID 域（`BeginChild("scrollbox")` 里的 Selectable 不会与外部同名控件撞 ID，相当于免费送了一层 PushID）。尺寸 `ImVec2(-1, 120)`：宽 -1 撑满父窗口可用宽，高固定 120；`ImGuiChildFlags_Borders` 给它描一圈边框，让"这是一个盒子"在视觉上成立。返回值语义与 Begin 同族——false 也得 `EndChild()`。30 项 `Selectable` 装进 120 像素高的小盒子，选中项的 bool 由 `g_childScrollItem == i` 每帧算出（又是"状态外置"：选中态存在你的 int 里）。13 章的日志窗口就是 ChildWindow 的实战（`ImVec2(-1, -1)` 宽高双撑满）。

## 10.6 TabBar：窗口内分页

```cpp
// ═══ 10.8 标签页三件套：TabBar 包 TabItem ═══
if (ImGui::BeginTabBar("main"))
{
    if (ImGui::BeginTabItem("one"))
    {
        ImGui::Text("first tab content");
        ImGui::EndTabItem();
    }
    if (ImGui::BeginTabItem("two"))
    {
        ImGui::Text("second tab content");
        ImGui::EndTabItem();
    }
    ImGui::EndTabBar();
}
```

三层层级：`BeginTabBar/EndTabBar` 管标签条，`BeginTabItem/EndTabItem` 管每个页——注意非选中页的 `BeginTabItem` 返回 false，其 `EndTabItem` 写在 if 里面（只包选中页的内容，这与 Begin 的"End 无条件"不同，因为 TabItem 的 if 包的就是"本页内容"这一整体）。顺带一提全局字号：`io.FontGlobalScale` 可每帧缩放全部文字（不动窗口几何），13 章会用它做"字号"滑条。

## 10.7 运行与输出

```bash
cd cppgui
pwsh build.ps1 -Example 10_imgui_windows
```

实测输出（`build/docs-ref/10_imgui_windows.out`）：

```text
==== 10 ImGui 窗口系统 开始 ====
40 frames; child selected=0; pinned pos=40,60
==== 10 ImGui 窗口系统 结束 ====
```

`child selected=0`：selftest 40 帧无人点击，但 Selectable 的选中判据是 `g_childScrollItem == i`，初值 0 让第 0 项天然处于选中态——这是"选中态存在变量里"的直接展示；`pinned pos=40,60` 是 `Always` 条件每帧钉住的结果。

## 坑位清单

- **Begin 返回 false 也要 End**：折叠/完全裁出屏幕时 Begin 返回 false，内容可以跳过，但 `End()` 必须无条件执行。同族规则：`BeginChild/EndChild`、`BeginTabBar/EndTabBar`、`BeginTable/EndTable`（11 章）全部严格配对——if 包"内容"，永远不包"收尾函数"。
- **ImGuiCond_Always 会和拖窗口打架**：`SetNextWindowPos(..., Always)` 每帧覆盖位置，用户永远拖不动这个窗口。常规布局用 `FirstUseEver`（首次定位后交给用户），Always 只用于"程序控位"的特殊窗口（如本例演示钉住的 pinned）。
- **imgui.ini 默认写进 cwd**：窗口位置/尺寸自动持久化到工作目录，跑一次示例目录里多一个 ini 文件、窗口位置跨进程残留。不想要的窗口加 `NoSavedSettings`；整个程序想关掉就置 `io.IniFilename = nullptr`。
- **NoSavedSettings 与 FirstUseEver 是一对**：关了持久化又想固定初始位置，靠 `SetNextWindowPos + ImGuiCond_FirstUseEver` 在每次进程启动时重新定位——只靠 ini 的话，删掉 ini 后窗口会堆到屏幕左上角默认位。
- **ChildWindow 不是"子控件容器"**：它是嵌套滚动区，有自己的滚动条与 ID 域；`BeginChild` 的返回值同样"false 也 EndChild"。宽度 -1 = 撑满父窗可用宽（imgui 尺寸参数的通用约定），不是"自适应内容"。
- **没有布局管理器这件事是认真的**：wx 的 sizer/绝对定位思维在此全废——控件函数推进光标，`SameLine/Spacing/Indent/Separator` 是全部排版手段。两个控件要重叠、要任意定位，只有 12 章 DrawList 一条路。

---

上一章：[09 · 控件全集与 ID 机制](09-imgui-widgets.md) ｜ 下一章：[11 · 表格与曲线](11-imgui-tables.md) ｜ 返回：[README](../README.md)
