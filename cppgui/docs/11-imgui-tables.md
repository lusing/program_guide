# 11 · 表格与曲线：Tables API 实战

> 对应示例：[examples/11_imgui_tables.cpp](../examples/11_imgui_tables.cpp)

## 11.1 数据侧：普通容器，imgui 不知道它的存在

表格的数据源是一个再普通不过的 `std::vector`：

```cpp
// ═══ 11.1 数据：普通结构体数组，排序前后都在你手里 ═══
struct ProcRow
{
    int    pid;
    char   name[24];
    float  cpu;      // %
    int    mem;      // MB
};

static std::vector<ProcRow> g_procs = {
    { 101, "systemd",   0.4f,  12 },
    { 204, "explorer",  2.1f,  88 },
    { 313, "clang.exe", 45.7f, 720 },
    { 409, "mspdbsrv",  0.0f,  36 },
    { 512, "game",      12.3f, 2048 },
};
```

imgui 对 `g_procs` 一无所知——表格 API 每帧只是"来问你要一行一列画什么"。这与 04 章 wx 的 `wxListCtrl`（数据插入控件、控件持有条目）方向相反：**数据永远在你手里，表格是无状态的取景器**。排序、选择因此都落回你自己的 C++ 代码，见 11.4。

## 11.2 列是注册出来的

Tables API（1.80 起取代老式 Columns，10 章 legacy 对照）的心法：**列在表头前"注册"，行在循环里"推进"**。数据、绘制、排序三件事里 imgui 只管中间一件：

```cpp
// ═══ 11.2 BeginTable + TableSetupColumn：注册四列 ═══
ImGuiTableFlags tf = ImGuiTableFlags_Resizable | ImGuiTableFlags_Sortable
                   | ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersOuter;
if (ImGui::BeginTable("procs", 4, tf))
{
    // 列用 UserID 给排序回调传键（'pid'/'cpu'... 单字符常量够用）
    ImGui::TableSetupColumn("PID",   ImGuiTableColumnFlags_DefaultSort, 0, 'pid');
    ImGui::TableSetupColumn("Name",  ImGuiTableColumnFlags_WidthStretch, 0, 'name');
    ImGui::TableSetupColumn("CPU%",  ImGuiTableColumnFlags_WidthFixed, 80.0f, 'cpu');
    ImGui::TableSetupColumn("MemMB", ImGuiTableColumnFlags_WidthFixed, 80.0f, 'mem');
    ImGui::TableHeadersRow();              // 表头行（可点击排序）
    ...
    ImGui::EndTable();
}
```

`BeginTable` 返回 false（如被完全裁剪）也照例无条件 `EndTable()`。列注册的四参依次是：显示名、列标志、初始宽度/权重、UserID。宽度策略对照：

| 列标志 | 语义 | 本表用法 |
|---|---|---|
| `WidthFixed` | 固定像素宽（第三参给像素） | CPU%/MemMB 各 80，可拖 |
| `WidthStretch` | 按权重分剩余宽度 | Name 吃满剩余空间 |
| `DefaultSort` | 初始排序落在此列 | PID 列开机即有序 |

表级标志组合出行为：`Resizable` 允许拖列宽、`Sortable` 让表头可点、`RowBg` 隔行底色（斑马纹）、`BordersOuter` 外框。第四个参数是 **UserID**——一个 `ImGuiID`（无符号整数），这里用 `'pid'` 这样的多字符字面量（编译器把它拼成整数常量，值不重要、唯一即可），排序时原样传回你的比较器，免掉每行做字符串比较。

## 11.3 行循环与行选择、上下文菜单

```cpp
// ═══ 11.3 TableNextRow + TableSetColumnIndex 推进行/列 ═══
for (int row = 0; row < (int)g_procs.size(); ++row)
{
    ImGui::TableNextRow();
    const ProcRow& p = g_procs[row];
    ImGui::TableSetColumnIndex(0);
    ImGui::Text("%d", p.pid);
    ImGui::TableSetColumnIndex(1);
    // 行选择：Selectable spanAllColumns + 右键上下文菜单
    if (ImGui::Selectable(p.name, g_selectedRow == row,
                          ImGuiSelectableFlags_SpanAllColumns))
        g_selectedRow = row;
    if (ImGui::BeginPopupContextItem())     // 右键该项
    {
        if (ImGui::MenuItem("kill")) { /* 教学示意 */ }
        ImGui::EndPopup();
    }
    ImGui::TableSetColumnIndex(2);
    ImGui::Text("%.1f", p.cpu);
    if (p.cpu > 30.0f) ImGui::SameLine(), ImGui::TextColored(ImVec4(1, 0.4f, 0.4f, 1), "!");
    ImGui::TableSetColumnIndex(3);
    ImGui::Text("%d", p.mem);
}
```

每行 `TableNextRow()` 起头，`TableSetColumnIndex(n)` 跳列（也可以用 `TableNextColumn()` 顺序走）。行选择的配方是：第 1 列放 `Selectable`，`SpanAllColumns` 把热区横跨整行（点行内任意处都能选中），选中态照样是外置变量 `g_selectedRow == row`。右键菜单 `BeginPopupContextItem()` 挂在**最后一个 item** 上——必须紧跟 Selectable 同帧调用，隔一个控件就挂错了对象。CPU 超 30% 的行用 `TextColored` 标个红感叹号（conditional 的 `SameLine` 后接彩色 Text，不改布局只加提示）。

## 11.4 排序：imgui 给意图，你排数据

```cpp
// ═══ 11.4 TableGetSortSpecs → 自己 stable_sort → 清 SpecsDirty ═══
static ImGuiTableSortSpecs* g_sortSpecs = nullptr;

static void SortProcs()
{
    if (!g_sortSpecs || !g_sortSpecs->SpecsDirty) return;
    const auto& s = g_sortSpecs->Specs[0];
    std::stable_sort(g_procs.begin(), g_procs.end(), [&](const ProcRow& a, const ProcRow& b) {
        int r = 0;
        switch (s.ColumnUserID)
        {
        case 'pid':  r = a.pid - b.pid; break;
        case 'name': r = std::strcmp(a.name, b.name); break;
        case 'cpu':  r = (a.cpu < b.cpu) ? -1 : (a.cpu > b.cpu) ? 1 : 0; break;
        case 'mem':  r = a.mem - b.mem; break;
        }
        return s.SortDirection == ImGuiSortDirection_Ascending ? r < 0 : r > 0;
    });
    g_sortSpecs->SpecsDirty = 0;              // 告诉 imgui：数据已按此排好
}

// 每帧在 TableHeadersRow 之后取一次意图：
g_sortSpecs = ImGui::TableGetSortSpecs();   // 排序意图
SortProcs();
```

`Sortable` 只保证表头可点、箭头会画；`TableGetSortSpecs()` 返回的是用户当前的排序**意图**（哪列、升/降、是否变了），数据在你自己的 `std::vector<ProcRow>` 里，**排序你自己做**——imgui 全程不碰你的数据。比较器先算 `r`（a 与 b 的大小关系），再按 `SortDirection` 决定取小于还是大于；`std::stable_sort` 保同键行次序稳定。排完把 `SpecsDirty` 清零，imgui 就知道"展示与数据已一致"，箭头状态不再重置。

## 11.5 PlotLines/PlotHistogram：滑动窗迷你图

```cpp
// ═══ 11.5 每帧推一个点，画滑动窗 ═══
float v = 0.4f + 0.3f * sinf(frame * 0.07f) + 0.1f * sinf(frame * 0.31f);
g_history[g_histIdx % 90] = v; ++g_histIdx;
ImGui::PlotLines("cpu history", g_history, 90, g_histIdx % 90,
                 nullptr, 0.0f, 1.0f, ImVec2(-1, 70));
ImGui::PlotHistogram("mem dist", g_history, 90, 0, nullptr, 0.0f, 1.0f, ImVec2(-1, 50));
```

Plot 系列是内置迷你图：**传指针 + 长度 + 偏移**，imgui 自己找 min/max 画曲线——数据不必拷贝进控件，又是"状态外置"。`g_history` 是 90 点环形缓冲，写指针 `g_histIdx % 90` 同时作为 offset 传入：imgui 把 offset 处当成最新样本、从旧到新环绕重排，曲线便连续滚动（`PlotHistogram` 不传 offset，演示的是同一缓冲的直方图视角）。13 章监视器的双曲线就是这套配方的加强版。

## 11.6 docking 与多视口注记

示例窗口底部的 `TextWrapped` 注记原文是："multi-viewport & docking: NOT in master (1.93, no ViewportsEnable in imgui.h) - docking branch only."

本教程本地 imgui 是 1.93.0 WIP master：**没有 docking（窗口停靠合并），也没有多视口（把 imgui 窗口拖成操作系统原生窗口）**——`imgui.h` 中实测无 `ViewportsEnable` 配置位（0 处命中）。这两项特性在官方 **docking 分支**，见本地源码 `docs/FAQ.md` 的 "docking branch" 一节；那是另一套二进制，本教程固定 master 不引入。所以本教程的"多窗口布局"（如 13 章四个面板）靠 `SetNextWindowPos + ImGuiCond_FirstUseEver` 手工摆位，都是 master 能力内的做法。

## 11.7 运行与输出

```bash
cd cppgui
pwsh build.ps1 -Example 11_imgui_tables
```

实测输出（`build/docs-ref/11_imgui_tables.out`）：

```text
==== 11 ImGui 表格与曲线 开始 ====
40 frames; rows=5; selected=-1; sort col dirty=0; last sample=0.474165
==== 11 ImGui 表格与曲线 结束 ====
```

`rows=5`：五条进程数据全程未被 imgui 动过；`selected=-1`：无人点行；`sort col dirty=0`：没有用户排序意图时 SortSpecs 干净、一次排序都没发生；`last sample=0.474165`：第 40 帧的正弦合成值——曲线数据源就是普通数组。

## 坑位清单

- **imgui 不替你排序**：`TableGetSortSpecs()` 给的是"用户点了哪列、什么方向"的意图，`SpecsDirty` 标志意图有变；数据在你的容器里，得自己按 `Specs[0]` 重排。以为开了 `Sortable` 表就自己有序，是最常见的初见错觉。
- **SpecsDirty 记得清零**：排完数据手动 `g_sortSpecs->SpecsDirty = 0`，告诉 imgui "数据已按此排好"。忘清则每帧重排一遍 stable_sort，数据量大时 CPU 白烧。
- **用 stable_sort 而不是 sort**：`std::sort` 对同键行的相对次序无承诺，用户反复点表头切换方向时行会"洗牌"，看起来像 bug；stable_sort 保序。
- **列宽策略要显式选**：注册列时不给宽度标志，默认按内容收缩；固定表格的惯例是关键列 `WidthFixed`（像素）、弹性列 `WidthStretch`（按权重吃剩余宽度）搭配，否则拉大窗口时表格不跟手。
- **BeginPopupContextItem 挂"最后一个 item"**：行内上下文菜单必须紧跟 `Selectable` 同帧调用才挂在该行上；中间隔一个 `Text` 就挂到别的对象去了。弹出体用 `MenuItem` 填充，`EndPopup` 照例无条件。
- **PlotLines 的 offset 就是环形缓冲写指针**：数组 + 长度 + offset 三件套，imgui 按"offset 处最新"环绕取数；忘传 offset（默认 0）曲线会在数组头部突兀跳变，看起来像数据毛刺。

---

上一章：[10 · 窗口系统](10-imgui-windows.md) ｜ 下一章：[12 · DrawList 自绘与字体](12-imgui-drawlist-fonts.md) ｜ 返回：[README](../README.md)
