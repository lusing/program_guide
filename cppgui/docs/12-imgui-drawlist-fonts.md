# 12 · DrawList 自绘与字体图集：中文渲染

> 对应示例：[examples/12_imgui_drawlist_fonts.cpp](../examples/12_imgui_drawlist_fonts.cpp)

## 12.1 ImDrawList：一切的底座

imgui 屏幕上的一切——文字、按钮的圆角矩形、曲线——最终都是 `ImDrawList` 的顶点与索引。平时它躲在控件后面，你也可以直接拿它画：

```cpp
// ═══ 12.1 GetWindowDrawList + 屏幕绝对坐标 ═══
ImVec2 p = ImGui::GetCursorScreenPos();     // 排版光标（屏幕坐标）
ImDrawList* dl = ImGui::GetWindowDrawList();
const ImVec2 c = ImVec2(p.x + 100, p.y + 90);   // 圆心
```

`GetWindowDrawList()` 取当前窗口的绘制列表，本帧内往里加的原语与控件内容同层渲染。最要紧的一件事：**DrawList 的坐标系是屏幕绝对坐标**（显示器原点参照），不是窗口局部坐标——所以基准点用 `GetCursorScreenPos()` 取排版光标的位置，再往上加偏移；窗口被拖动时基准点每帧重取，自绘内容便跟着窗口走。画完之后记得 `ImGui::Dummy(ImVec2(0, 210))` 给这块画布**让出排版空间**——DrawList 不推进光标，不占位的话后续控件会叠上来。

## 12.2 原语走读与动画

```cpp
// ═══ 12.2 常用原语：圆/线/三角/贝塞尔/文字 ═══
dl->AddCircleFilled(c, 60.0f, IM_COL32(90, 120, 200, 255), 32);
dl->AddCircle(c, 60.0f, IM_COL32(255, 255, 255, 255), 48, 2.0f);
dl->AddLine(ImVec2(c.x - 60, c.y + 60), ImVec2(c.x + 180, c.y - 40),
            IM_COL32(255, 160, 60, 255), 3.0f);
dl->AddTriangleFilled(
    ImVec2(c.x + 150, c.y + 30), ImVec2(c.x + 200, c.y + 80),
    ImVec2(c.x + 120, c.y + 70), IM_COL32(200, 80, 200, 200));
dl->AddBezierQuadratic(
    ImVec2(c.x - 40, c.y + 100), ImVec2(c.x + 60, c.y + 150),
    ImVec2(c.x + 160, c.y + 60), IM_COL32(80, 220, 120, 255), 2.0f);

// ═══ 12.3 每帧重画 = 动画：随帧旋转的三点 ═══
for (int i = 0; i < 3; ++i)
{
    float a = g_t + i * 2.0944f;
    dl->AddCircleFilled(ImVec2(c.x + cosf(a) * 45, c.y + sinf(a) * 45),
                        5.0f, IM_COL32(255, 230, 90, 255));
}

// ═══ 12.4 DrawList 上直接写字（用当前字体）═══
dl->AddText(ImVec2(p.x + 230, p.y + 130), IM_COL32(240, 240, 240, 255),
            "drawlist text");
```

原语家族都是 `Add*`：形状（线/矩形/圆/三角/贝塞尔，Filled 后缀为填充版）、文字（`AddText` 用当前字体）、贴图（`AddImage`）。参数有公共约定：颜色一律 `IM_COL32(r, g, b, a)` 宏打包 8 位通道（控件层用的浮点色 `ImVec4`/`ImColor` 可与之互转）；线原语的最后一个参数是像素粗细（`AddLine` 的 3.0f、`AddBezierQuadratic` 的 2.0f）；圆的分段数（32/48）越大边缘越圆。动画不需要任何定时器或重绘请求——**每帧重跑的 UI 代码本身就是动画循环**：`g_t = frame * 0.05f` 推进相位，三个小圆绕圆心转起来（08 章范式导读的直接兑现）。

## 12.3 PushClipRect：手动裁剪

```cpp
// ═══ 12.5 裁剪：矩形外的不画 ═══
dl->PushClipRect(ImVec2(p.x + 230, p.y + 150), ImVec2(p.x + 330, p.y + 190), true);
dl->AddRectFilled(ImVec2(p.x + 220, p.y + 140), ImVec2(p.x + 360, p.y + 200),
                  IM_COL32(60, 60, 80, 128));
dl->AddText(ImVec2(p.x + 230, p.y + 155), IM_COL32(255, 255, 255, 255),
            "clipped 中文裁剪演示长文本");
dl->PopClipRect();
```

窗口会自动裁剪越界内容，但**自定义矩形内的裁剪要自己推**：`PushClipRect(min, max, true)`（第三参 true = 与现有裁剪矩形求交）之后到 `PopClipRect()` 之间的原语都被限制在矩形内——本例那行长中文只在 100×40 的小窗里露出前几个字。Push/Pop 是栈式配对，与 PushID/PopID 同一心理模型。

## 12.4 中文字体实测

默认嵌入的 ProggyClean 是 ASCII 位图字体，中文一概显示为 "?"。中文的正确打开方式是**自载 TTF/OTF 并指定字形范围**：

```cpp
// ═══ 12.6 三级回退的字体加载（onInit 钩子里，首帧之前）═══
static void LoadFonts()
{
    ImGuiIO& io = ImGui::GetIO();
    const char* candidates[] = {
        "C:/Windows/Fonts/msyh.ttc",       // 微软雅黑
        "C:/Windows/Fonts/simhei.ttf",     // 黑体（兜底）
    };
    for (const char* path : candidates)
    {
        ImFontConfig cfg;
        cfg.OversampleH = 2;               // 横向过采样：中文笔画更平滑
        // 2500 常用简体字形（ChineseFull=21000 全集，烘焙慢）
        ImFont* f = io.Fonts->AddFontFromFileTTF(
            path, 18.0f, &cfg, io.Fonts->GetGlyphRangesChineseSimplifiedCommon());
        if (f) { g_cnFontOk = true; std::cout << "font loaded: " << path << "\n"; return; }
    }
    io.Fonts->AddFontDefault();            // 兜底：至少能跑
    std::cout << "WARN: no CJK font found, fallback to default\n";
}
```

四个实操要点：**路径**（`C:/Windows/Fonts/msyh.ttc` 微软雅黑，实测存在且可载；黑体 simhei 兜底，最后 `AddFontDefault()` 保底——字体缺失不至于崩，只打 WARN）；**范围**（`GetGlyphRangesChineseSimplifiedCommon()` = 2500 常用简体字形 + 标点，全集 21000 烙进图集又慢又费显存）；**字号**在载入时定（18px）；**时机**必须在 CreateContext 之后、首帧 NewFrame 之前——本骨架的 `cfg.onInit = &LoadFonts` 正好落在这个窗口期。加载成功的证据直接打到 stdout（`font loaded: C:/Windows/Fonts/msyh.ttc`），就是 12.6 输出块里比其他章多出的那一行。

窗口内还有一行**运行时自证**，成功与否当场可见：

```cpp
// ═══ 12.7 成功/回退的自证行 ═══
if (g_cnFontOk)
    ImGui::Text("中文渲染 OK（微软雅黑 + 简体全字形范围）");
else
    ImGui::Text("CJK font missing - ASCII fallback");
```

顺带把全教程出现过的三条字号通道收拢：**载入字号**（`AddFontFromFileTTF` 的 18px，烘焙参数，本章）；**io.FontGlobalScale**（运行时整体缩放，不动窗口几何，13 章滑条）；**style.FontScaleDpi**（08 章骨架按显示器 DPI 烘进样式的字段）。各管一段，按需取用。

## 12.5 glyph 计数证据与 1.93 字体重构

```cpp
// ═══ 12.8 首帧量一次烘焙后的字形数 ═══
if (frame == 0)
    g_glyphs = ImGui::GetFontBaked()->Glyphs.Size;   // 1.93：字形数在 baked 层
ImGui::Text("fontsize=%.0f fonts=%d glyphs(baked)=%d",
            ImGui::GetFontSize(), ImGui::GetIO().Fonts->Fonts.Size, g_glyphs);
```

1.93 对字体系统做了重构：运行时实际可用的字形收在 **`ImFontBaked`** 层（`GetFontBaked()` 取当前烘焙层），并且是**按需增量烘焙**的——用到哪个字才烙哪个。证据就是实测输出里的 `glyphs=47`：首帧时刻窗口里实际显示过的字符（ASCII 与已出现的中文）远不到 2500，图集只烙了这么多。想验证范围配置的真实覆盖，得把文本先显示一遍再计数；这不是 bug，是新字架的节俭。

```cpp
// ═══ 12.9 PushFont 临时切换字体 ═══
if (ImGui::Button("push font 26px"))
{
    ImGui::PushFont(ImGui::GetIO().Fonts->Fonts[0]);   // 演示入口（尺寸在载入时定）
    ImGui::Text("PushFont 切换的文本");
    ImGui::PopFont();
}
```

多字体共存时用 `PushFont/PopFont` 栈式切换（同 PushID 心理模型）；要同一字体的多档字号，得按各档字号各 `AddFontFromFileTTF` 一次——字号是烘焙参数，不是渲染参数。

## 12.6 运行与输出

```bash
cd cppgui
pwsh build.ps1 -Example 12_imgui_drawlist_fonts
```

实测输出（`build/docs-ref/12_imgui_drawlist_fonts.out`）：

```text
==== 12 ImGui 自绘与字体 开始 ====
font loaded: C:/Windows/Fonts/msyh.ttc
frames=40; cnfont=1; glyphs=47
==== 12 ImGui 自绘与字体 结束 ====
```

四行比其他章多一行：第 2 行是 `LoadFonts`（onInit）打出的加载成功证据；`cnfont=1` 确认走的是中文路径而非回退；`glyphs=47` 是首帧烘焙层的字形数（按需烘焙，见 12.5）。

## 坑位清单

- **DrawList 是屏幕绝对坐标**：不是窗口局部坐标。自绘前用 `GetCursorScreenPos()` 取基准，窗口移动时每帧重取才能跟着走；画完用 `Dummy()` 占位，否则后续控件直接叠上来（DrawList 不推进排版光标）。
- **字体加载时机只有一条缝**：CreateContext 之后、首帧 NewFrame 之前。本骨架的 `onInit` 钩子正好；在 main 里 `RunImguiApp` 之前直接调 `ImGui::GetIO()` 是空上下文解引用——当场崩溃。
- **范围名没有 SimplifiedFull**：1.93 的实际 API 是 `GetGlyphRangesChineseSimplifiedCommon()`（2500 常用字）；照旧教程写 `SimplifiedFull` 编译不过——本示例初版 UI 文字就写过 Full，编译器当场纠正。
- **字形按需烘焙，计数首帧很小**：1.93 把字形收进 `ImFontBaked::Glyphs`，用到才烙——40 帧实测 `glyphs=47`，不是 2500。想在启动就全量可用，得预先把覆盖文本过一遍，别把小计数当加载失败。
- **字体路径必须带回退链**：硬编码单路径，换台没装该字体的机器 `AddFontFromFileTTF` 返回 nullptr、界面全 "?"。本例 msyh.ttc → simhei.ttf → `AddFontDefault()` 三级回退，失败也只降级不打断。
- **运行中改字体要触发图集重建**：换字体/加字形后 `Fonts->TexID` 变化，渲染后端在 NewFrame 检测到才重建 D3D 纹理——只改 `io.FontDefault` 不触发重建，屏幕上还是旧图集。

---

上一章：[11 · 表格与曲线](11-imgui-tables.md) ｜ 下一章：[13 · 综合实战：迷你监视器](13-imgui-app.md) ｜ 返回：[README](../README.md)
