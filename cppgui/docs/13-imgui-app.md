# 13 · 综合实战：迷你系统监视器

> 对应示例：[examples/13_imgui_app.cpp](../examples/13_imgui_app.cpp)

## 13.1 应用总览与每帧数据流

本章把 08–12 的技术全部回收成一个迷你系统监视器。四个窗口的位置全部来自 `SetNextWindowPos + ImGuiCond_FirstUseEver`（10 章手法，master 无 docking，见 11 章注记）：

| 窗口 | 首次位置/尺寸 | 内容 | 回收自 |
|---|---|---|---|
| 监控 | (20,20) 430x250 | 帧率 + 双曲线 | 11 章 PlotLines |
| 进程 | (20,290) 430x260 | 可排序表格 + 行选择 | 11 章 Tables |
| 设置 | (470,20) 300x250 | 主题/字号 | 09 章 Combo/Slider |
| 日志 | (470,290) 300x260 | 滚动日志自动追底 | 10 章 ChildWindow |

外加 12 章的微软雅黑中文字体（`onInit` 载入，表头"名称"、主题"深色/浅色/经典"都是中文）。架构仍是那句话——**每帧重跑的 Ui 回调 + 全部外置的静态变量**：

```cpp
// ═══ 13.1 每帧产生模拟数据（随机游走 + 正弦）═══
float cpu = std::max(0.0f, std::min(1.0f,
    g_cpu[(g_histIdx + kHist - 1) % kHist] * 0.9f
    + 0.08f * sinf(frame * 0.05f) + 0.05f * ((frame % 7) - 3) * 0.05f));
float mem = 0.5f + 0.15f * sinf(frame * 0.013f);
g_cpu[g_histIdx % kHist] = cpu; g_mem[g_histIdx % kHist] = mem; ++g_histIdx;

if (frame % 20 == 7)
    PushLog("采样: cpu=" + std::to_string((int)(cpu * 100)) + "%");
```

数据源是假的（随机游走叠加正弦），但**数据流是真的**：采样 → 写环形缓冲 → 推日志，全在每帧 UI 代码里完成——即时模式下"取数、加工、显示"没有边界，一个函数从头做到尾。真实工程把采样换成 `GetSystemTimes`/进程枚举即可，UI 一行不用改。

## 13.2 双 PlotLines 环形缓冲

```cpp
// ═══ 13.2 ring buffer 三件套：数组 + 长度 + 写指针 ═══
static const int kHist = 120;
static float g_cpu[kHist] = {};
static float g_mem[kHist] = {};
static int   g_histIdx = 0;

// 面板里两块曲线（label 用 ## 前缀：不显示，只为 ID 不同）
ImGui::Text("帧率 %.1f FPS (%.2f ms)", io.Framerate, 1000.0f / std::max(1.0f, io.Framerate));
ImGui::PlotLines("##cpu", g_cpu, kHist, g_histIdx % kHist, "CPU", 0.0f, 1.0f, ImVec2(-1, 70));
ImGui::PlotLines("##mem", g_mem, kHist, g_histIdx % kHist, "内存", 0.0f, 1.0f, ImVec2(-1, 70));
```

11 章配方的 120 点加强版：写指针 `g_histIdx % kHist` 传给 offset，imgui 自动把最新样本排在曲线右端。注意两个 label 都是 `"##cpu"`/`"##mem"` 开头——**标签兼作图例文字与控件 ID**，两块曲线不想显示重复图例就用 `##` 前缀顶掉（09 章 ID 消歧的反向应用：不为显示、只为 ID）。帧率 `io.Framerate` 是 imgui 自带的滑动平均帧率，顺手显示即可。

## 13.3 可排序进程表

```cpp
// ═══ 13.3 表格 + 排序 + 行选择（11 章整套回收）═══
if (ImGuiTableSortSpecs* s = ImGui::TableGetSortSpecs())
{
    if (s->SpecsDirty)
    {
        const auto& sp = s->Specs[0];
        std::stable_sort(g_procs.begin(), g_procs.end(), [&](const Proc& a, const Proc& b) {
            int r = sp.ColumnUserID == 'p' ? a.pid - b.pid
                  : sp.ColumnUserID == 'c' ? (a.cpu < b.cpu ? -1 : a.cpu > b.cpu ? 1 : 0)
                  : std::strcmp(a.name, b.name);
            return sp.SortDirection == ImGuiSortDirection_Ascending ? r < 0 : r > 0;
        });
        s->SpecsDirty = 0;
    }
}
for (auto& p : g_procs)
{
    ImGui::TableNextRow();
    ImGui::TableSetColumnIndex(0);
    ImGui::Text("%d", p.pid);
    ImGui::TableSetColumnIndex(1);
    if (ImGui::Selectable(p.name, g_selectedPid == p.pid, ImGuiSelectableFlags_SpanAllColumns))
    {
        g_selectedPid = p.pid;
        PushLog(std::string("选中进程 ") + p.name);
    }
    ImGui::TableSetColumnIndex(2);
    ImGui::Text("%.1f", p.cpu);
}
```

与 11 章的差异全在"集成"：选中行往日志窗推一条记录（跨窗口联动不需要任何信号槽——两个窗口的代码同帧执行，共享一个 `g_logs` 就够了）；表头列名用中文（"名称"），因为 12 章的字体已经就位。这里也最能看清即时模式的红利：**"选中进程时曲线面板闪一下"这类跨面板交互，只是两个 if 的先后关系**，没有事件路由。

## 13.4 设置面板：主题、字号、帧率

```cpp
// ═══ 13.4 主题三态 + 全局字号 ═══
const char* themes[] = { "深色", "浅色", "经典" };
if (ImGui::Combo("主题", &g_theme, themes, 3)) ApplyTheme();
if (ImGui::SliderFloat("字号", &g_fontScale, 0.8f, 1.6f))
{ /* 拖动中每帧都进这里：即时模式下没有"提交"事件 */ }
io.FontGlobalScale = g_fontScale;              // 全局字号缩放（每帧生效）
```

`ApplyTheme()` 在 Combo 返回 true 的那一帧调一次 `StyleColorsDark/Light/Classic`，下一帧全屏换色：

```cpp
// ═══ 13.5 主题 = 三个官方预设色 ═══
static void ApplyTheme()
{
    switch (g_theme)
    {
    case 0: ImGui::StyleColorsDark(); break;
    case 1: ImGui::StyleColorsLight(); break;
    case 2: ImGui::StyleColorsClassic(); break;
    }
}
```

字号滑条拖动期间**每帧返回 true**——注释里专门标注了这个语义；`io.FontGlobalScale` 的赋值放在 if 之外每帧执行，滑到哪帧字号就跟到哪帧（它是全局缩放系数，不动窗口几何，中文跟随无碍）。面板里还实时显示 `io.Framerate` 与当前 cpu/mem 读数——都是"每帧读变量"的即视即得。

## 13.5 日志窗自动追底

```cpp
// ═══ 13.6 贴底判断 + SetScrollHereY：日志跟随的标准配方 ═══
ImGui::Begin("日志", nullptr, ImGuiWindowFlags_NoCollapse);
if (ImGui::BeginChild("log", ImVec2(-1, -1), ImGuiChildFlags_Borders))
{
    for (auto& l : g_logs)
        ImGui::TextUnformatted(l.c_str());
    if (ImGui::GetScrollY() >= ImGui::GetScrollMaxY() - 4)
        ImGui::SetScrollHereY(1.0f);            // 贴底时新内容自动跟随
}
ImGui::EndChild();
ImGui::End();
```

10 章 ChildWindow 的实战：`ImVec2(-1, -1)` 宽高都撑满。自动滚底的正确姿势是**先判贴底再跟随**：用户本来就在最底（`GetScrollY() >= GetScrollMaxY() - 4`，4 像素容差）才 `SetScrollHereY(1.0f)`（把滚动位置定到"刚画完的这里"，1.0f = 底对齐）；用户往上翻历史时不打扰。日志用 `TextUnformatted`（整串直出，不做格式化解析，长日志的性能正道）。存储侧是最朴素的 `std::deque<std::string> g_logs`，`PushLog` 就是 `push_back`——教学示意不设上限，真实监视器该滚动截断（容器在你手里，加个 `if (g_logs.size() > N) g_logs.pop_front();` 即可）。

## 13.6 无头测试思路与运行输出

GUI 程序怎么进 CI？imgui 官方留了门：**example_null 后端**——不建窗口、不碰 GPU，把 UI 跑在无渲染环境（渲染目标改为字符串/内存），适合把 UI 逻辑做成纯函数做单元测试（本地源码 `docs/EXAMPLES.md`）。本教程 14 章的 FTXUI 示例就演示了同思路的"渲染到字符串"。本例的 selftest 则是朴素版：跑满 50 帧（`cfg.maxFrames = 50`）验证无人值守下数据流不空转、退出干净。

```bash
cd cppgui
pwsh build.ps1 -Example 13_imgui_app
```

实测输出（`build/docs-ref/13_imgui_app.out`）：

```text
==== 13 ImGui 监视器应用 开始 ====
frames=50; theme=0; logs=4; last cpu=65%
==== 13 ImGui 监视器应用 结束 ====
```

`logs=4`：50 帧里 `frame % 20 == 7` 命中三帧（7、27、47，各推一条采样日志）加一条字体加载日志（`[font] 微软雅黑 16px 加载成功`），日志管线活着；`last cpu=65%` 是随机游走第 50 帧的落点（取自 `(g_histIdx-1+kHist)%kHist`）；`theme=0` 无人碰设置。第二部分到此收官：六个示例，一套"每帧重跑 + 状态外置"的范式，从骨架到综合应用。

## 坑位清单

- **自动滚底别无条件 SetScrollHereY**：先判贴底（`GetScrollY() >= GetScrollMaxY() - 4`，留几像素容差）再 `SetScrollHereY(1.0f)`；无条件追底会抢走用户往上翻历史的滚动位置——日志窗的经典差评点。
- **滑条副作用每帧触发**：拖"字号"期间 `SliderFloat` 每帧 true，if 里放重活会连续执行几十帧。本例的 `io.FontGlobalScale = g_fontScale` 是幂等赋值、每帧执行天然安全——把副作用设计成幂等是即时模式的必修课。
- **FontGlobalScale 要每帧赋**：它不是"设置一次管终身"的属性——每帧 UI 代码就是唯一真相之源；只在变化帧赋值的话，别处改了它你这帧就会写回旧值。
- **环形缓冲的差一错误**：读写都用 `g_histIdx % kHist`，取"最新样本"要用 `(g_histIdx - 1 + kHist) % kHist`（onExit 的 `last cpu` 就是这么取的）——少减一个 1，曲线与读数就错位一格。
- **PlotLines 想不显示图例用 `##` 前缀**：label 既当图例又当 ID；两块曲线同 label 会撞 ID（09 章），加前缀文本又能让图例消失，一箭双雕。

---

上一章：[12 · DrawList 自绘与字体图集：中文渲染](12-imgui-drawlist-fonts.md) ｜ 下一章：[14 · FTXUI 元素树：声明式范式与渲染到字符串](14-ftxui-dom.md) ｜ 返回：[README](../README.md)
