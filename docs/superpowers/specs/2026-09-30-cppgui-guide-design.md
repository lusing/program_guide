# C++ GUI 编程指南设计（2026-09-30）

## 1. 背景与问题

`guide` 仓库已有 40+ 门教程（cpp20/sdl2/win32/mfc/wpf/winforms 等），**尚无 C++ GUI
多框架横向教程**。用户本地有四个参考库源码：

| 库 | 版本 | 本地路径 | 范式定位 |
|---|---|---|---|
| wxWidgets | 3.3.4 | `G:\github\cpp\wxWidgets` | 原生保留模式控件库 |
| Dear ImGui | 1.93.0 WIP（master，非 docking 分支） | `G:\github\cpp\imgui` | 即时模式自绘 |
| FTXUI | master | `G:\github\cpp\FTXUI` | 现代声明式 TUI |
| tvision | master | `G:\github\cpp\tvision` | 经典 Turbo Vision TUI |

四者恰好覆盖 C++ 界面编程的四种范式。本任务新建 `cppgui/` 教程目录，四部分各成体系、
24 章全量，规格对齐仓库标准结构（docs/ 分章 + 章号=示例号 + 坑位清单 + 实测验证）。

## 2. 目标与非目标

**目标**：24 章独立文档（每章 150–250 行）+ 25 个示例文件（24 章每章一个 + 08 章 SDL2
后端对照变体）；每部分首章带「范式导读」节；全部示例在本机 MSVC x64 实测构建+冒烟通过；
四个综合章（13/19/24）各完成一个完整小应用。

**非目标**：
- 不做 Qt/GTK（未装；win32 原生已有独立教程）
- imgui 不讲 docking 分支与多视口（本地 master 无此特性，11 章概念注记为止）
- 不做 imgui 全后端矩阵实测（SDL2 对照变体之外只文档提及）
- 各框架不穷举控件/API，每主题章挑代表控件讲透
- 不承诺 macOS/Linux 实测（`run-all.sh` 保留可移植性，缺依赖时声明式跳过）

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 整体结构 | **四部分各成体系**（用户确认）：wx(01–07) → imgui(08–13) → FTXUI(14–19) → tvision(20–24) |
| 规模 | **24 章全量**（用户确认） |
| imgui 后端 | **win32_directx11 主线**（用户确认）；08 章附 `sdl2_opengl3` 对照变体（scoop 已装 sdl2） |
| wx 获取 | **本地源码 CMake 构建一次**（用户确认）：`tools/build-wx.ps1` 产出到 `cppgui/build/dep-wx/`（不入库），后续 `find_package` 复用 |
| 依赖策略 | imgui 源码直接编入示例；FTXUI/tvision `add_subdirectory` 指向本地源码（cache 变量可覆盖路径） |
| 验证策略 | Windows/MSVC x64 实测：构建 24 目标 + 每示例 `--selftest` 自动退出冒烟 + dom 类章节渲染到字符串直捕 stdout |
| 旧文件 | 无（全新目录 `cppgui/`） |

## 4. 环境实测结论（2026-09-30）

| 项 | 结果 |
|---|---|
| MSVC | VS 2022 Community 与 VS 18 Community 并存（`vcvars64.bat` 均在）；build.ps1 用 vswhere 探测最新 Community |
| cmake/ninja | 4.4.3 / 1.13.2（scoop） |
| imgui | 1.93.0 WIP；`imgui.h` 中 ViewportsEnable **0 处命中** → 确认 master 非 docking 分支，11 章按 master 实测 |
| FTXUI | `cmake_minimum_required(3.28.2)`（本机 4.4.3 满足）；`FTXUI_BUILD_EXAMPLES/TESTS/DOCS/MODULES` 均可关；examples/component 53 例 + dom 35 例作素材 |
| tvision | CMake 选项：`TV_BUILD_EXAMPLES` 默认 ON **须显式关**；`TV_USE_STATIC_RTL`/`TV_BUILD_AVSCOLOR` 默认 OFF；examples：tvdemo/tvedit/tvforms/tvdir/palette/mmenu/tvhc |
| wxWidgets | 3.3.4；`lib/` 只有 VMS .opt 文件**无预构建产物**，须自行构建；CMake 支持 3.10...4.1 |
| sdl2 | scoop 已装（`G:\scoop\apps\sdl2`），供 08 章对照变体 |

## 5. 章节结构（docs/，24 章）

章号 = 示例号。每部分第 1 章首节为「范式导读」。

### 第一部分 wxWidgets——原生保留模式（01–07）

| 章 | 文件 | 内容 |
|---|---|---|
| 01 | `01-wx-hello` | wxApp/wxFrame/wxIMPLEMENT_APP、事件表、消息循环、最小窗口 |
| 02 | `02-wx-menus` | 菜单栏/弹出菜单/工具栏/状态栏/加速键、wxEVT_MENU、UpdateUIEvent |
| 03 | `03-wx-sizers` | Box/Grid/FlexGrid/WrapSizer、wxSizerFlags、比例对齐、嵌套布局 |
| 04 | `04-wx-controls` | Button/CheckBox/RadioBox/Choice/ComboBox/Slider/SpinCtrl/多行 TextCtrl/ListCtrl、Bind vs 事件表 |
| 05 | `05-wx-dialogs` | 消息框/文件/颜色/字体对话框、自定义 wxDialog、wxValidator 校验 |
| 06 | `06-wx-drawing` | wxPaintDC/双缓冲/画笔画刷/wxGraphicsContext、鼠标画板、wxEVT_PAINT 坑 |
| 07 | `07-wx-docview-thread` | wxDocument/wxView 最小例 + wxThread/wxQueueEvent/wxEVT_THREAD 后台进度 |

### 第二部分 Dear ImGui——即时模式自绘（08–13）

| 章 | 文件 | 内容 |
|---|---|---|
| 08 | `08-imgui-hello`（+`08_imgui_hello_sdl2.cpp` 变体） | win32+D3D11 完整骨架三段式（初始化/循环/清理）、平台与渲染后端两个插拔点、SDL2 变体对照 |
| 09 | `09-imgui-widgets` | 基本控件全集；即时模式语义：无隐藏状态、返回值即事件、ID 栈 push/pop |
| 10 | `10-imgui-windows` | Begin/End 窗口系统、子窗口、窗口标志、SameLine/Spacing 布局推进模型、字体缩放 |
| 11 | `11-imgui-tables` | Tables API（标志/列宽/排序/行选择）、Plot 直方图；docking 分支概念注记 |
| 12 | `12-imgui-drawlist-fonts` | ImDrawList 原语自绘、ImFontAtlas 字形范围、**中文字体与图集重建坑** |
| 13 | `13-imgui-app` | 综合：系统监视器风应用（曲线+表格+设置面板）+ example_null 无头自测思路 |

### 第三部分 FTXUI——现代声明式 TUI（14–19）

| 章 | 文件 | 内容 |
|---|---|---|
| 14 | `14-ftxui-dom` | text/vbox/hbox/border/paragraph/gauge/graph、渲染到字符串、声明式重建语义 |
| 15 | `15-ftxui-components` | ScreenInteractive 三种 Loop、Input/Button/Checkbox/Radiobox/Menu/Slider、焦点与事件冒泡 |
| 16 | `16-ftxui-layout` | Flexbox/GridBox/hflow/dbox/resizable_split、size(FIT/PERCENT) |
| 17 | `17-ftxui-style-canvas` | Color/256 色/真彩、bold/dim/blink/hyperlink 装饰、Canvas 画布动画、linear_gradient |
| 18 | `18-ftxui-composition` | Renderer/CatchEvent/Maybe/Modal/Container 组合、自定义组件、PostEvent 异步 |
| 19 | `19-ftxui-app` | 综合：交互式待办管理器（菜单+输入+复选+模态确认+异步时钟） |

### 第四部分 tvision——经典 Turbo Vision（20–24）

| 章 | 文件 | 内容 |
|---|---|---|
| 20 | `20-tv-hello` | TApplication/TDeskTop 骨架、cmXXX 命令常量、事件驱动模型 |
| 21 | `21-tv-menus-dialogs` | TMenuBar/TSubMenu、TDialog+TInputLine+TButton 模态执行、handleEvent 分发 |
| 22 | `22-tv-views` | TView/TGroup/TWindow 体系、滚动视图、窗口插入桌面 |
| 23 | `23-tv-colors-forms` | 调色板代次体系、tvforms 思路表单、ASCII puzzle 小游戏 |
| 24 | `24-tv-editor` | 综合：迷你文本编辑器（TEditor/TFileEditor 思路，打开/保存/状态栏） |

## 6. 示例与验证

**示例形态**：`examples/NN_topic.cpp` 单文件 main（08 章附加 `_sdl2` 变体）；根
`CMakeLists.txt` 提供 `CPPGUI_ENABLE_{WX,IMGUI,FTXUI,TVISION}` 四开关与
`CPPGUI_{WX,IMGUI,FTXUI,TVISION}_DIR` 路径变量（默认指向 `G:/github/cpp/` 本地布局）；
`CMakePresets.json` 固化 MSVC x64 + Ninja 配置。

**验证三层**（build.ps1 一键执行，写入 README 状态表）：

1. **构建层**：cmake configure + build 全部目标，exit 0；
2. **冒烟层**：每示例 `--selftest`——初始化后运行真实逻辑数百毫秒自动退出、exit 0：
   - wx：定时器到时 `Close(true)`；imgui：主循环帧计数达阈值退出；
   - FTXUI：后台线程 `screen.PostEvent` 退出；tvision：线程注入退出命令（实施时实测）；
3. **输出层**：14/16/17 章等 DOM 渲染类示例以「渲染到字符串打印」为主形态，stdout
   直捕进文档「输出」块，`tools/check_docs.py` 交叉核对章节↔示例对应与输出引用。

## 7. 交付物清单

```
cppgui/
├── README.md            导航 + 工具链 + 验证状态表
├── CHEATSheet.md        四框架 API 速查 + 实测坑位索引
├── docs/                24 章正文（NN-slug.md）
├── examples/            25 个示例文件
├── CMakeLists.txt + CMakePresets.json
├── build.ps1            依赖就绪检查 → 构建 → 冒烟 → 汇总
├── run-all.sh           非 Windows 通道（探测路径，缺则声明式跳过）
└── tools/
    ├── build-wx.ps1     wxWidgets 静态库一次性构建（产物 build/dep-wx/ 不入库）
    └── check_docs.py    文档机器核查
```

`.gitignore` 增补 `cppgui/build/`。

## 8. 风险与对策

| 风险 | 对策 |
|---|---|
| wx 源码构建耗时（10–20 分钟）或失败 | `tools/build-wx.ps1` 独立可重跑、参数最小化（SHARED=OFF、关 samples）、产物缓存复用；失败则文档标注 wx 部分构建态 |
| tvision/FTXUI 源码在 cmake 4.4 + MSVC 下的兼容性 | 实施首日用最小 hello 分别探通再铺开；问题记录进坑位清单 |
| imgui 1.93 WIP 与网络文档漂移 | 一切以本地源码为准（`G:\github\cpp\imgui`） |
| `--selftest` 各框架退出机制差异 | 首个示例（08/14/20）打通后固化成模板 |
| D3D11/Win32 资源释放顺序坑 | 严格按官方 example 三段式清理，实测验证 |
