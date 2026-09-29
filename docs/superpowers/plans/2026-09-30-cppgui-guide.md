# C++ GUI 编程指南实施计划（2026-09-30）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新建 `cppgui/` 教程——四部分各成体系 24 章（wx 01–07 / imgui 08–13 / FTXUI 14–19 / tvision 20–24），25 个示例（08 章附 SDL2 变体），全部本机 MSVC x64 实测三层验证通过，docs/ 分章正文 + CHEATSheet + README 对齐仓库标准结构。

**Architecture:** 先建 wx 静态库预构建与根 CMake 装配（Task 1–2，含四框架首例探针固化 `--selftest` 模板），再按四部分批次写示例（每批构建+冒烟+提交），示例全绿后撰写分章正文，最后 CHEATSheet/README/check_docs/终验。**用户特别指示：每章动笔前必读对应框架源码自带的 docs 与 examples**（参考索引见下）。

**Tech Stack:** MSVC x64（VS 2022 / VS 18 Community，vswhere 探测）+ CMake 4.4.3 + Ninja 1.13.2（scoop）。wxWidgets 3.3.4 / Dear ImGui 1.93.0 WIP（master，**无 docking/多视口**）/ FTXUI master / tvision master，源码均在 `G:/github/cpp/`。

**Spec:** `docs/superpowers/specs/2026-09-30-cppgui-guide-design.md`

## Global Constraints（实施遵守）

- 框架路径 cache 变量默认值：`CPPGUI_WX_DIR=G:/github/cpp/wxWidgets`、`CPPGUI_IMGUI_DIR=G:/github/cpp/imgui`、`CPPGUI_FTXUI_DIR=G:/github/cpp/FTXUI`、`CPPGUI_TVISION_DIR=G:/github/cpp/tvision`（均可覆盖）。
- 每示例支持 `--selftest`：初始化后运行真实逻辑数百毫秒自动退出、exit 0、stdout 打印结束标记 `==== NN <中文名> 结束 ====`（build.ps1 判定 exit 0 + 结束标记 + stderr 空）。
- 自家代码编译零警告：`/std:c++20 /EHsc /utf-8 /W3`；第三方源码（FTXUI/tvision/imgui/wx）不套此标准。
- 章号 = 示例号；正文 150–250 行/章；每章坑位清单 3–6 条（以实测发现为准，不编造）。
- 文档「输出」块一律来自实测 stdout（TUI 渲染类示例形态设计为「渲染到字符串打印」保证可溯）。
- `cppgui/build/` 不入库（.gitignore 增补）；`run-all.sh` 由根 `.gitattributes` 的 `*.sh text eol=lf` 保证 LF。
- imgui master `imgui.h` 无 ViewportsEnable（实测 0 处命中）——11 章多视口只作概念注记并引用 docs/FAQ.md。
- 提交信息带 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

## 已核实技术事实（executor 直接采用，勿再猜）

| 事实 | 出处 |
|---|---|
| FTXUI targets：`screen`/`dom`/`component` + INTERFACE `ftxui`（**链接 `ftxui` 即可**） | `FTXUI/CMakeLists.txt:50-182` |
| FTXUI 须关：`FTXUI_BUILD_EXAMPLES/TESTS/DOCS/MODULES`（均默认 OFF，显式 FORCE 兜底） | 同上 options |
| tvision target：`tvision` + ALIAS `tvision::tvision`；须 `TV_BUILD_EXAMPLES=OFF`（默认 ON）；`TV_USE_STATIC_RTL`/`TV_BUILD_AVSCOLOR` 默认 OFF 不动 | `tvision/source/CMakeLists.txt:6-7`、`tvision/CMakeLists.txt:127` |
| imgui win32+dx11 链接：`d3d11.lib d3dcompiler.lib dxgi.lib`（Windows SDK 自带，零第三方） | `examples/example_win32_directx11/*.vcxproj` |
| imgui 编入源：`imgui.cpp imgui_draw.cpp imgui_tables.cpp imgui_widgets.cpp imgui_demo.cpp` + `backends/imgui_impl_{win32,dx11}.cpp`（sdl2 变体换 `impl_sdl2.cpp + impl_opengl3.cpp`） | `imgui/` 目录 |
| SDL2（08 变体）：`find_package(SDL2 CONFIG REQUIRED PATHS G:/scoop/apps/sdl2/current/lib/cmake/SDL2)`，链接 `SDL2::SDL2`，代码里 `#define SDL_MAIN_HANDLED`（sdl2 教程已验证套路） | `sdl2/README.md` 工具链节 |
| wx 构建：`cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=<prefix> -DwxBUILD_SHARED=OFF`（samples/demos 默认 OFF，无需再关）；用后 `find_package(wxWidgets CONFIG REQUIRED)` + `wx::core wx::base wx::adv wx::html` | `wxWidgets/build/cmake/options.cmake:11-21` |
| tvision selftest 通路：构造里 `setTimer(600)`（TProgram 方法，一次性）→ 到期广播 `evBroadcast + cmTimerExpired`（infoPtr=定时器 id）→ 子类 `handleEvent` 捕获后 `message(this, evCommand, cmQuit)` → `TProgram::handleEvent` 对 `evCommand/cmQuit` 执行 `endModal` | `tvision/source/tvision/tprogram.cpp:212、205` |
| FTXUI selftest 通路：`std::thread` 延时后 `screen.PostEvent(Event::Custom)`，组件 `CatchEvent` 捕获 `Event::Custom` 后返回 true 退出循环 | `FTXUI/examples/component/custom_loop.cpp` |
| FTXUI 渲染到字符串：`auto screen = Screen::Create(Dimension::Fixed(64), Dimension::Fit(document)); Render(screen, document); std::cout << screen.ToString();`（Fixed 宽度保证文档输出确定性） | `FTXUI/examples/dom/*.cpp` |
| wx selftest 通路：`OnInit` 里扫 `argv` 识别 `--selftest` → frame 内 `Bind(wxEVT_TIMER, ...){ Close(true); }` + `m_timer->StartOnce(600)` | wx 标准用法 |
| imgui selftest 通路：主循环帧计数 `if (selftest && ++frame > 40) done = true;` | 官方骨架改 |

## 框架参考索引（用户指示：动笔前必读）

| 部分 | 必读参考 |
|---|---|
| wx | `samples/minimal/minimal.cpp`、`samples/menu/`、`samples/toolbar/`、`samples/sizer/`、`samples/widgets/`、`samples/dialogs/`、`samples/drawing/painting.cpp`、`samples/docview/`、`samples/thread/`；API 事实标准 `interface/wx/*.h` |
| imgui | `docs/FAQ.md`、`docs/FONTS.md`（中文字体）、`docs/BACKENDS.md`、`docs/EXAMPLES.md`；`imgui_demo.cpp`（活字典）；`examples/example_win32_directx11/main.cpp`、`examples/example_sdl2_opengl3/main.cpp` |
| FTXUI | `doc/introduction.md`、`doc/module-dom.md`、`doc/module-component.md`、`doc/module-screen.md`；`examples/dom/*.cpp`（35 例）、`examples/component/*.cpp`（53 例）——章节内容与官方示例一一对应 |
| tvision | `README.md`；`examples/hello.cpp`（根目录）、`examples/tvdemo/`（tvdemo1.cpp 菜单/fileview.cpp 滚动/puzzle.cpp 游戏/gadgets.cpp 时钟）、`examples/tvedit/`、`examples/tvforms/`、`examples/palette/`；头文件 `include/tvision/*.h` |

---

### Task 1: 仓库骨架 + wxWidgets 静态库预构建

**Files:**
- Create: `cppgui/tools/build-wx.ps1`
- Create: `cppgui/docs/`、`cppgui/examples/`（空目录骨架）
- Modify: `.gitignore`（增 `cppgui/build/`）

**Interfaces:**
- Produces: `cppgui/build/dep-wx/`（wx 安装前缀，含 `lib/*.lib` 与 `lib/cmake/wxWidgets/`），Task 2 的 `find_package` 指向它。

- [ ] **Step 1: 建目录骨架与 .gitignore 增补**

```text
cppgui/{docs,examples,tools}/
.gitignore 追加一行：cppgui/build/
```

- [ ] **Step 2: 写 tools/build-wx.ps1**（核心逻辑，pwsh 7，UTF-8 无 BOM）

```powershell
# 已有产物则跳过（build/dep-wx/lib/cmake/wxWidgets 存在即视为就绪）
param([switch]$Force)
$wxSrc = "G:/github/cpp/wxWidgets"    # 可用环境变量 CPPGUI_WX_DIR 覆盖
$prefix = "$PSScriptRoot/../build/dep-wx"
if ((Test-Path "$prefix/lib/cmake/wxWidgets") -and -not $Force) { "wx 就绪: $prefix"; exit 0 }
# vcvars（vswhere 探测最新 Community，回退已知路径）后连缀 cmake：
#   cmd /c "call `"$vcvars`" && cmake -S $wxSrc -B build/wx-build -G Ninja
#     -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=<绝对路径 prefix>
#     -DwxBUILD_SHARED=OFF && cmake --build build/wx-build --target install"
"预计 10–20 分钟" 提示后再跑；输出末行打印 lib 数量与安装前缀。
```

- [ ] **Step 3: 实跑** `pwsh cppgui/tools/build-wx.ps1`，确认 `build/dep-wx/lib/cmake/wxWidgets/wxWidgetsConfig.cmake` 存在、`lib/*.lib` 生成（wxbase/wxmsw_core/wxmsw_adv/wxmsw_html 等）。记录实际耗时。

- [ ] **Step 4: Commit** `feat(cppgui): 仓库骨架与 wxWidgets 3.3.4 静态库预构建脚本`

### Task 2: 根 CMake 装配 + 验证脚本 + 四框架首例（固化 selftest 模板）

**Files:**
- Create: `cppgui/CMakeLists.txt`、`cppgui/CMakePresets.json`
- Create: `cppgui/build.ps1`、`cppgui/run-all.sh`
- Create: `cppgui/examples/01_wx_hello.cpp`、`08_imgui_hello.cpp`、`08_imgui_hello_sdl2.cpp`、`14_ftxui_dom.cpp`、`20_tv_hello.cpp`

**Interfaces:**
- Consumes: Task 1 的 `build/dep-wx`；四框架源码目录。
- Produces: CMake 函数 `cppgui_add_example(<name>)`（建目标、放行 /W3 无警告、输出到 `build/bin/`）；`build.ps1 [-All | -Example NN_name]` 判定协议；四框架 selftest 代码模板（后续所有示例照抄）。

- [ ] **Step 1: 写根 CMakeLists.txt**（结构如下，逐块落实）

```cmake
cmake_minimum_required(VERSION 3.28)
project(cppgui LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
option(CPPGUI_ENABLE_WX ON) / CPPGUI_ENABLE_IMGUI / CPPGUI_ENABLE_FTXUI / CPPGUI_ENABLE_TVISION
set(CPPGUI_WX_DIR "G:/github/cpp/wxWidgets" CACHE PATH "...")  # 其余三框架同式

function(cppgui_add_example NAME)
  add_executable(${NAME} examples/${NAME}.cpp)
  target_compile_options(${NAME} PRIVATE /W3)   # MSVC 分支（if(MSVC)）
  set_target_properties(${NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
endfunction()

# --- imgui（源码编入，两个后端库）---
add_library(cppgui_imgui STATIC
  ${CPPGUI_IMGUI_DIR}/imgui.cpp ${CPPGUI_IMGUI_DIR}/imgui_draw.cpp
  ${CPPGUI_IMGUI_DIR}/imgui_tables.cpp ${CPPGUI_IMGUI_DIR}/imgui_widgets.cpp
  ${CPPGUI_IMGUI_DIR}/imgui_demo.cpp
  ${CPPGUI_IMGUI_DIR}/backends/imgui_impl_win32.cpp
  ${CPPGUI_IMGUI_DIR}/backends/imgui_impl_dx11.cpp)
target_include_directories(cppgui_imgui PUBLIC ${CPPGUI_IMGUI_DIR} ${CPPGUI_IMGUI_DIR}/backends)
# 08 变体另建 cppgui_imgui_sdl2（同核心源 + impl_sdl2.cpp + impl_opengl3.cpp）
# find_package(SDL2 CONFIG REQUIRED PATHS "G:/scoop/apps/sdl2/current/lib/cmake/SDL2")

# --- FTXUI ---
set(FTXUI_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)  # TESTS/DOCS/MODULES 同式
add_subdirectory(${CPPGUI_FTXUI_DIR} ${CMAKE_BINARY_DIR}/ftxui EXCLUDE_FROM_ALL)
# 示例链接：target_link_libraries(NN PRIVATE ftxui)

# --- tvision ---
set(TV_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
add_subdirectory(${CPPGUI_TVISION_DIR} ${CMAKE_BINARY_DIR}/tvision EXCLUDE_FROM_ALL)
# 链接：tvision

# --- wx ---
find_package(wxWidgets CONFIG REQUIRED PATHS ${CMAKE_SOURCE_DIR}/build/dep-wx NO_DEFAULT_PATH)
# 链接：wx::core wx::base wx::adv wx::html
```

- [ ] **Step 2: CMakePresets.json**：configurePreset `msvc-x64`（Ninja、binaryDir `${sourceDir}/build`、`CMAKE_CXX_FLAGS="/utf-8 /EHsc"`）+ 同名 buildPreset。

- [ ] **Step 3: 写 build.ps1**（参考 `sdl2/build.ps1` 的 vcvars/cmd 连缀与判定框架，pwsh 7 无 BOM）：vcvars 探测（vswhere → `G:\Program Files\Microsoft Visual Studio\{2022,18}\Community\VC\Auxiliary\Build\vcvars64.bat`）→ `cmake --preset msvc-x64` → `cmake --build --preset msvc-x64 --target <name>` → 跑 `build/bin/<name>.exe --selftest`（超时 30s）→ 判定：exit 0 + stdout 含 `==== NN ` 与 ` 结束 ====` + stderr 空。`-All` 遍历全部目标。`run-all.sh`：非 Windows 探测各框架目录与 cmake，缺失即打印「声明式跳过」不失败。

- [ ] **Step 4: 写四个首例并全绿**（模板固化，正文在 Task 7/8 撰写）：

- `01_wx_hello.cpp`：改自 `samples/minimal/minimal.cpp`。`wxIMPLEMENT_APP`、`OnInit` 建 frame（含一条菜单 File→Quit 与状态栏）、selftest（Global Constraints 表中 wx 通路，`wxEVT_TIMER` 里 `Close(true)`）。运行态正常显示窗口直到关闭。
- `08_imgui_hello.cpp`：改自 `examples/example_win32_directx11/main.cpp` 全骨架（CreateDeviceD3D11/消息循环/NewFrame/Render/Cleanup 三段式逐段中文注释），UI = 一个窗口内 Text + Button 计数器（演示即时模式：无回调、每帧重算）。selftest 帧计数。另编 `08_imgui_hello_sdl2.cpp`（同 UI，换 `examples/example_sdl2_opengl3/main.cpp` 骨架，`#define SDL_MAIN_HANDLED`）。
- `14_ftxui_dom.cpp`：`text/vbox/hbox/border/gauge/separator` 组一棵元素树，渲染到字符串打印（Fixed(64) 宽度），再演示同一棵树换 `FTXUI/examples/dom/graph.cpp` 风格 graph。本例 selftest 与正常运行输出一致（纯输出型，仍支持 `--selftest` 直通打印）。
- `20_tv_hello.cpp`：改自 `tvision/examples/hello.cpp`（根目录）。TApplication 派生 + `initMenuBar`（Alt-X Quit）/`initStatusLine`；正文后补 Uses_* 宏机制讲解素材注释。selftest 走 setTimer 通路。

- [ ] **Step 5: 验证**：`pwsh cppgui/build.ps1 -All`（当前 5 目标）全绿；异常路径（如删 dep-wx 后报清晰错误）抽查一次。

- [ ] **Step 6: Commit** `feat(cppgui): 根 CMake 装配/验证双入口与四框架首例——selftest 模板定型`

### Task 3: wx 批次——02 menus / 03 sizers / 04 controls / 05 dialogs / 06 drawing / 07 docview+thread

**Files:** Create `cppgui/examples/02_wx_menus.cpp` … `07_wx_docview_thread.cpp`（六个单文件，每个含 `--selftest` 与结束标记）

每章规格（写码前先读对应 samples）：

- **02_wx_menus**：菜单栏（子菜单/分隔线/`wxMenuItem::MakeCheckable`/单选组 `Check`+radio 组）、加速键 `"&File"`、`wxToolBar::AddTool`（含分隔）、`SetStatusText` 分区状态栏、`Bind(wxEVT_MENU)` 与旧式事件表 `EVT_MENU` 双写法对照、`wxEVT_UPDATE_UI` 动态禁用、`PopupMenu` 右键菜单。参考 `samples/menu/menu.cpp`、`samples/toolbar/toolbar.cpp`。
- **03_wx_sizers**：`wxBoxSizer` 嵌套（proportion 0/1/2 对照）、border 四向、`wxALIGN_*`/`wxEXPAND`、`wxGridSizer/wxFlexGridSizer`（AddGrowableCol）、`wxWrapSizer`、`wxSizerFlags` 链式、spacer、`SetSizerAndFit` 与 resizable 窗口联动。参考 `samples/sizer/`（sizer.cpp 与 sap.cpp）。
- **04_wx_controls**：Button/CheckBox/RadioBox/StaticText/Choice/ComboBox（可编辑项增删）/Slider/SpinCtrl/Gauge（定时器驱动进度）/单行与多行 wxTextCtrl（`wxTE_MULTILINE|wxTE_RICH2`）/wxListCtrl report 模式（`InsertColumn/InsertItem/SetItem` + 选中事件）。每控件至少一个事件 Bind。参考 `samples/widgets/`（按 widgets.bkl 列表挑子目录）。
- **05_wx_dialogs**：`wxMessageDialog` 五种样式标志实测、`wxFileDialog` 打开/保存/通配符、`wxColourDialog`/`wxFontDialog` 取回并应用到面板、自定义 `wxDialog`（sizer + OK/Cancel + `TransferDataTo/FromWindow`）、`wxTextValidator`(`wxFILTER_ALPHANUMERIC` 等) 拦截非法输入实测、`ShowModal` 返回值分派。参考 `samples/dialogs/dialogs.cpp`。
- **06_wx_drawing**：`wxEVT_PAINT` 中必须 `wxPaintDC`、`wxBufferedPaintDC` 双缓冲对照（resize 时闪烁差异正文描述）、线/矩形/椭圆/多边形/文字、`wxPen/wxBrush` 样式与透明、`wxGraphicsContext` 抗锯齿对照同图、鼠标拖拽画板（`wxEVT_LEFT_DOWN/MOTION/UP` + 拖拽捕捉，笔迹存 `std::vector` 重放——天然契合 selftest：selftest 模式程序化注入 20 个点后截图无门，改为打印点数校验）。参考 `samples/drawing/painting.cpp`。
- **07_wx_docview_thread**：上半：`wxDocManager` + `wxDocument`/`wxView` 最小文档视图（New/Open/Save/SaveAs 菜单、`wxDocTemplate` 注册、view 的 `OnDraw`）；下半：`wxThread` 派生（`wxThread::Run`）、两个 worker 并发计数、`wxQueueEvent` 发 `wxThreadEvent` → 主线程 `wxEVT_THREAD` 更新两条 `wxGauge`，结束打标记。参考 `samples/docview/docview.cpp`、`samples/thread/thread.cpp`。

- [ ] **Step 1: 六个示例逐一写完**（每写完一个即 `build.ps1 -Example NN_wx_...` 全绿再写下一个）
- [ ] **Step 2: `-All` 全绿**（11 目标：Task 2 的 5 + 本批 6）
- [ ] **Step 3: Commit** `feat(cppgui): wx 批次——菜单/布局/控件/对话框/自绘/docview+线程 6 例`

### Task 4: imgui 批次——09 widgets / 10 windows / 11 tables / 12 drawlist+fonts / 13 app

**Files:** Create `cppgui/examples/09_imgui_widgets.cpp` … `13_imgui_app.cpp`（五个单文件）

每章规格（写码前必读 `imgui_demo.cpp` 对应小节 + `docs/FAQ.md`）：

- **09_imgui_widgets**：Checkbox/Radio/SliderFloat/SliderInt/InputInt3/InputText/Combo/Listbox/ProgressBar/ColorEdit3；**全部控件演示 `if (ImGui::XXX(...))` 返回值即事件**语义；ID 机制：两同名 Button 告警复现 + `PushID/PopID` 与 `"##id"` 后缀两种解法；`SameLine`/`Separator`。参考 `imgui_demo.cpp` Widgets 节。
- **10_imgui_windows**：`Begin` 返回 collapsing 布尔、`SetNextWindowPos/Size/SizeConstraints`、flags 对照（NoResize/NoCollapse/AlwaysAutoResize/NoSavedSettings——ini 持久化与 `io.IniFilename` 置空）、ChildWindow（`BeginChild` + 自动高度、`IsChildHovered`）、`BeginTabBar/TabItem`、`io.FontGlobalScale` 缩放、三窗口排版。参考 demo Windows 节。
- **11_imgui_tables**：`BeginTable` flags（Resizable/Sortable/RowBg/Borders）、`TableSetupColumn`（WidthStretch/WidthFixed 对照）、`TableHeadersRow`、隔行变色、排序：`TableGetSortSpecs` 实测排 `std::vector` 数据、行选择（`IsItemClicked` + 上下文菜单 `BeginPopup`）；`PlotLines/PlotHistogram` 滑动数据窗。正文末「多视口与 docking」注记：master 无此特性（实测 0 处 ViewportsEnable），指引 docs/FAQ 的 docking 分支说明。参考 demo Tables/Plots 节。
- **12_imgui_drawlist_fonts**：`GetWindowDrawList()`：AddLine/AddRect/AddCircleFilled/AddTriangleFilled/AddBezierQuadratic/AddText（坐标=窗口绝对坐标讲解）；clipping `PushClipRect/PopClipRect`；字体：`io.Fonts->AddFontFromFileTTF("C:/Windows/Fonts/msyh.ttc", 18.0f, nullptr, io.Fonts->GetGlyphRangesChineseSimplifiedFull())`（运行时检查文件存在、失败回退默认并打印），中文渲染验证 + glyph ranges 概念 + 图集重建时机（改字体后帧内自动重建的边界，引 docs/FONTS.md）。selftest 打印 glyph 计数。参考 docs/FONTS.md。
- **13_imgui_app**：系统监视器风综合应用：ring buffer 双曲线（CPU 模拟随机游走/内存正弦）双 PlotLines、进程表格（6 列可排序、行选中）、右侧设置 dock（主题 `ImGui::StyleColorsDark/Light/Classic` 切换 + FontGlobalScale slider + 帧率显示 `io.Framerate`）、底部滚动日志窗（`SetScrollHereY(1.0f)` 自动追底）。正文注记 example_null 无头测试思路。参考 demo 全节 + docs/EXAMPLES.md。

- [ ] **Step 1: 五个示例逐一写完并逐个全绿**
- [ ] **Step 2: `-All` 全绿**（16 目标）
- [ ] **Step 3: Commit** `feat(cppgui): imgui 批次——控件/窗口/表格/自绘字体/监视器应用 5 例`

### Task 5: FTXUI 批次——15 components / 16 layout / 17 style+canvas / 18 composition / 19 app

**Files:** Create `cppgui/examples/15_ftxui_components.cpp` … `19_ftxui_app.cpp`（五个单文件）

每章规格（官方 examples 与章节一一对应，写码前必读对应 example 源文件 + `doc/module-*.md`）：

- **15_ftxui_components**：`ScreenInteractive::Fullscreen()` + `Container::Vertical` 聚合 Input/Button/Checkbox/Radiobox/Menu/Slider/Toggle/Dropdown；`Renderer` 外壳包 border|window；焦点环演示（Tab 循环、`Component::SetActiveChild`）；`CatchEvent` 拦 `Event::SpecialKey` q/Escape 退出；selftest 走 PostEvent(Event::Custom)。参考 `examples/component/{button,input,checkbox,radiobox,menu,menu2,slider,toggle,dropdown,focus,custom_loop}.cpp`。
- **16_ftxui_layout**：`size(WIDTH, EQUAL|PERCENT, ...)` 三维、`FlexboxConfig`（gap/justify/align）、`Gridbox`、`hflow/vflow`、`dbox` 叠放（前景提示层）、`ResizableSplit(LEFT|TOP, ...)`、`window(text, body)` 组合。渲染到字符串打印为主（非交互帧用 Fixed 宽度），交互部分 selftest。参考 `examples/component/flexbox_gallery.cpp`、`examples/dom/{gridbox,vflow,dbox? 见目录}.cpp`、`examples/component/resizable_split.cpp`、`window.cpp`。
- **17_ftxui_style_canvas**：`Color::Red/Blue256? → Color256(n)/Color::RGB(r,g,b)/HSV`；装饰 `bold/dim/inverted/blink/underlined/strikethrough/hyperlink`（输出层 ANSI 转义讲解——stdout 直捕即证据）；`Canvas`（`SetPixel/DrawPointLine/DrawBlockLine/画布坐标系 y 向下`）+ 动画（thread 周期 `PostEvent(Event::Custom)` 重绘，参考 `examples/component/canvas_animated.cpp`）；`linear_gradient` 一瞥。参考 `examples/dom/{color_*,style_*,canvas,linear_gradient}.cpp`。
- **18_ftxui_composition**：自定义组件三件套（`Renderer(comp, []{...})` / `CatchEvent` / `Make<Component>` 继承 `ComponentBase` 手写 `Render+OnEvent`——以一个「方向键移动的 @ 角色」组件为例）；`Container::{Vertical,Horizontal,Tab}` 与 Tab 内容切换；`Maybe(子, 条件)` 条件渲染；`Modal(子, &show)` 模态层；跨线程 `Sender/Receiver`（worker 线程 `sender->Send` → `screen.Loop(component, receiver)` 消费，参考 `doc/module-component.md` 末节与 `examples/component/print_above.cpp` 思路）。
- **19_ftxui_app**：交互式待办管理器综合：左侧分类 Menu + 右侧任务列表（Checkbox 完成态 + 删除按钮）、底部 Input+Button 新增、`Container::Tab` 切列表/统计两视图、`Modal` 确认清空、右上角异步时钟（thread 每秒 PostEvent）、空列表 `Maybe` 占位。全部 14–18 技术点回收。

- [ ] **Step 1: 五个示例逐一写完并逐个全绿**
- [ ] **Step 2: `-All` 全绿**（21 目标）
- [ ] **Step 3: Commit** `feat(cppgui): FTXUI 批次——组件/布局/样式画布/组合子/待办应用 5 例`

### Task 6: tvision 批次——21 menus+dialogs / 22 views / 23 colors+forms / 24 editor

**Files:** Create `cppgui/examples/21_tv_menus_dialogs.cpp` … `24_tv_editor.cpp`（四个单文件）

每章规格（写码前必读 tvdemo 对应源文件与 `include/tvision/*.h`；Uses_* 宏开头按需 `#define`）：

- **21_tv_menus_dialogs**：`initMenuBar` 完整菜单树（`TSubMenu/TMenuItem`、`newItem/newLine`、快捷键 kbXXX、自制命令从 `cmUser` 起）；`handleEvent` 分发 evCommand（含 `TApplication::handleEvent` 基类回call）；`TStatusLine/TStatusItem`（~Alt-X~ Exit 风格）；`TDialog`+`TInputLine`（`TRect` 手工摆放）+`TLabel`+`TButton`（默认/普通/Center）、`execDialog` 模态返回值。参考 `tvdemo/tvdemo1.cpp`、根 `hello.cpp`。
- **22_tv_views**：TWindow 派生（`TWindowInit(bounds, initFrame)`）+ `insertWindow`；`TScroller` 滚动文本视图（`setLimit/insertLine? 按 fileview.cpp 实际 API`，加载一段内置文本滚读）；`TView::draw` 覆写（`writeChar/writeStr` 直接绘制）；窗口 grow/zoom/close 与拖动（正文描述交互、selftest 自动化验证窗口数）。参考 `tvdemo/fileview.cpp`、`tvdemo/ascii.cpp`。
- **23_tv_colors_forms**：调色板代次：`TPalette` 数组覆写改变某控件类别配色（对照 `examples/palette/` 与 `include/tvision/tview.h` 的 getColor 映射）；`tvforms` 表单思想简版（字段+校验+提交，参考 `examples/tvforms/`）；ASCII puzzle 小游戏改编（`tvdemo/puzzle.cpp`——4×4 滑块，键鼠操作，selftest 走 setTimer 通路）。三主题中调色板与 puzzle 必做、forms 简版。
- **24_tv_editor**：迷你文本编辑器：`TEditWindow/TEditor`（或 `TFileEditor`，按 `tvedit/` 与 `include/tvision/editors.h` 实测选择）多窗口编辑、`TFileDialog` 打开/保存、状态栏行列显示（editor 的 `updateCommands`/消息）、cmSave/cmOpen 命令接线。selftest：程序化打开内置缓冲→改一字→校验 dirty 标志→quit。

- [ ] **Step 1: 四个示例逐一写完并逐个全绿**（tvision 章风险最高：API 冷门，以头文件与 tvdemo 实测为准，遇到与规格不符处以实测 API 回写本计划相应行）
- [ ] **Step 2: `-All` 全绿**（25 目标）
- [ ] **Step 3: Commit** `feat(cppgui): tvision 批次——菜单对话框/视图/调色板/编辑器 4 例——25 示例全量收官`

### Task 7: docs 第一二部分——01–13 章正文

**Files:** Create `cppgui/docs/01-wx-hello.md` … `13-imgui-app.md`（13 个分章文件，NN-slug.md）

- [ ] **Step 1: 写 wx 七章**。每章结构（仓库惯例）：范式导读（01 章）或承接前文 → 概念讲解 → 示例代码走读（引 examples/ 文件与关键片段）→ 「运行与输出」块（**实测** stdout/selftest 输出摘录）→ 「实测坑位」3–6 条（真实发现，例如：wxEVT_PAINT 里缺 wxPaintDC 的断言失败、validator 与 TransferData 的执行顺序等，以实际踩到为准）。
- [ ] **Step 2: 写 imgui 六章**。08 章含范式导读 + 双后端对照段（win32_dx11 与 sdl2 两骨架 diff 讲解平台/渲染后端插拔点）；12 章中文字体实测记录（msyh.ttc 路径、glyph ranges、图集重建）。
- [ ] **Step 3: 交叉核对**：每章引用的输出块与 `build/bin` 实跑输出一致（逐字节或逐行子序列）；每章开头的示例文件链接存在。
- [ ] **Step 4: Commit** `docs(cppgui): 第一二部分正文——wx 七章 + imgui 六章`

### Task 8: docs 第三四部分——14–24 章正文

**Files:** Create `cppgui/docs/14-ftxui-dom.md` … `24-tv-editor.md`（11 个分章文件）

- [ ] **Step 1: 写 FTXUI 六章**。14 章含范式导读（声明式/不可变元素树/每帧重建 diff 与 imgui 即时模式对照）；输出块用 Fixed 宽度渲染字符串（确定性可溯）。
- [ ] **Step 2: 写 tvision 五章**。20 章含范式导读（Borland 桌面隐喻、Uses_* 宏体系、事件循环与 wx/imgui 三方对照收束）；21–24 以头文件实测 API 为准回写正文。
- [ ] **Step 3: 交叉核对同 Task 7 Step 3。**
- [ ] **Step 4: Commit** `docs(cppgui): 第三四部分正文——FTXUI 六章 + tvision 五章——24 章齐`

### Task 9: CHEATSheet + README + check_docs + 根导航 + 终验 + 记忆

**Files:**
- Create: `cppgui/CHEATSheet.md`、`cppgui/README.md`、`cppgui/tools/check_docs.py`
- Modify: 根 `README.md`（按字母序插入 cppgui 条目，格式对齐 sdl2 条目：目录+验证状态+实测亮点+链接）
- Modify: `G:\xulun\.claude\projects\G--code-guide\memory\`（新增本教程记忆文件 + MEMORY.md 索引行）

- [ ] **Step 1: tools/check_docs.py**（参考 `coq-hott/build/check-docs.py` 五关设计）：① 章节文件 NN ↔ 示例文件 NN 一一对应（08 容忍双文件）② 正文 ```text 输出块与 `build/bin` 实跑 stdout 行子序列匹配 ③ 每章「实测坑位」条数 ≥3 且与 CHEATSheet 引用一致 ④ docs 内相对链接有效 ⑤ README 导航含全部 24 章。`build.ps1 -All` 末尾自动调用。
- [ ] **Step 2: CHEATSheet.md**：四框架横向速查（同一任务——建窗口/按钮事件/布局/文本输入/自定义绘制——四列 API 对照表）+ 全部实测坑位汇总索引（按框架分组，引用章号）。
- [ ] **Step 3: README.md**：目录树、工具链表（版本/路径/预构建说明）、构建与验证入口、**验证状态表**（25 目标 × 三层判定全绿记录 + wx 构建耗时）、macOS/Linux 说明（run-all.sh 声明式跳过）。
- [ ] **Step 4: 全量终验**：清空 `cppgui/build/` → `pwsh build.ps1 -All` 从零全绿（含 wx 复用检查、check_docs 五关）→ 根 README 条目落笔。
- [ ] **Step 5: 更新 auto-memory**：新建 `cppgui-tutorial-build.md`（结构 + 实测坑位 top 摘要 + 四框架 target/链接事实表），MEMORY.md 加索引行。
- [ ] **Step 6: Commit** `feat(cppgui): CHEATSheet/README/check_docs/根导航——四部分 24 章定稿，25 目标终验全绿`

---

## Self-Review 记录

- **Spec 覆盖**：24 章（Task 3–6 示例 + Task 7–8 正文）、25 示例（08 双文件）、三层验证（Task 2 build.ps1 固化）、check_docs（Task 9）、CHEATSheet/README/根导航/记忆（Task 9）——spec §5–§7 全部有任务承接；spec §8 风险（tvision/FTXUI 首例探通）由 Task 2 提前 + Task 6 Step 1 的「实测 API 回写」机制覆盖。
- **占位符扫描**：无 TBD/TODO；每章规格均给了内容点 + 参考文件 + 验证形态。
- **类型/命名一致性**：`cppgui_add_example`、`build/dep-wx`、`build/bin/`、`--selftest`、结束标记格式在各任务间一致；FTXUI 链接名统一 `ftxui`、tvision 统一 `tvision`。
