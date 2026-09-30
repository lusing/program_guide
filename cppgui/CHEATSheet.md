# cppgui CHEATSheet —— C++ GUI/TUI 四框架速查

> 配套 [README](README.md) 与 [docs/](docs/) 24 章正文。坑位索引按框架分组、标注章号；
> 每条都能在对应章的「坑位清单」找到完整成因与解法。**全部为本仓库 MSVC x64 实测**（2026-09，
> wxWidgets 3.3.4 / Dear ImGui 1.93.0 WIP master / FTXUI master / tvision master）。

## 一、四框架范式一句话

| 框架 | 范式 | 状态住在哪 | UI 何时更新 |
|---|---|---|---|
| wxWidgets | 保留模式 | 控件对象树（库里） | 事件回调改状态，库负责重绘 |
| Dear ImGui | 即时模式 | 你的变量 | 主循环每帧重跑 UI 代码 |
| FTXUI | 声明式组件树 | 你的变量 + 组件内 | 每帧重建元素树 diff |
| tvision | 经典桌面隐喻（TUI） | 视图对象树（库里） | 事件驱动 drawView |

## 二、同一任务，四列 API 对照

| 任务 | wx（01–07） | ImGui（08–13） | FTXUI（14–19） | tvision（20–24） |
|---|---|---|---|---|
| 应用入口 | `wxIMPLEMENT_APP(App)` 宏生成 main | `main()` 三段式自管 | `auto screen = ScreenInteractive::Fullscreen(); screen.Loop(renderer);` | `TApp : TApplication` + `app.run()` |
| 建窗口 | `wxFrame` 派生 + `Show(true)` | `Begin("标题")`…`End()` 成对 | `window(text("标题"), child)` 元素 | `TWindow` 派生 + `insertWindow(w)` |
| 按钮+事件 | `Bind(wxEVT_BUTTON, &f, this, id)` | `if (Button("点我")) act();` | `Button("点我", [&]{ act(); })` | `TButton(rect, "标签", cmd)` + `handleEvent` switch |
| 布局 | `wxBoxSizer`/`wxGridSizer` + `SetSizerAndFit` | 手摆坐标 + `SameLine()`（无布局器） | `vbox/hbox/flexbox/gridbox` | `TRect` 手工坐标 + `growMode` |
| 单行输入 | `wxTextCtrl`（值即成员） | `InputText("标签", buf, size)` | `Input(&state, "占位")` 组件 | `TInputLine(rect, maxLen)`（`data` 是缓冲） |
| 列表选择 | `wxChoice`/`wxListBox` | `BeginListBox`/`Combo` | `Menu`/`Radiobox`/`Dropdown` | 菜单 `TSubMenu`（窗口列表用 TListView 系） |
| 自定义绘制 | `wxPaintDC`/`wxGraphicsContext`（06） | `GetWindowDrawList()->AddRect...`（12） | `Canvas` 画布（17） | `draw()` 覆写 + `TDrawBuffer`/`writeChar`（22） |
| 模态对话框 | `wxDialog` + `ShowModal()` 返回值 | `OpenPopup`/`BeginPopup` | `Modal(child, &show)` | `TDialog` + `deskTop->execView(d)` |
| 定时/动画 | `wxTimer` + `EVT_TIMER` | 帧计数（`io.DeltaTime` 累加） | `screen.Post(Task{...})` 延时投递 | `setTimer(ms)` → `cmTimerExpired` 广播 |
| 优雅退出 | `Close(true)` 走关窗链 | `done = true` 出主循环 | `screen.Exit()`/Loop 返回 | `message(this, evCommand, cmQuit, 0)` |
| 中文 | `wxString::FromUTF8` 铁律 | 自载字体 + GlyphRanges（12） | UTF-8 原生 | UTF-8 原生（strwidth 按宽字符计 2） |
| selftest 通路 | `wxTimer::StartOnce(600)` + `Close(true)` | 40 帧计数退出 | 无头 Post 自定义事件退出（19） | `setTimer(600)` → 广播 → `cmQuit` |

## 三、构建接线速查（CMakeLists.txt 事实）

| 框架 | 接入方式 | 链接 | 关键开关 |
|---|---|---|---|
| wx | `find_package(wxWidgets CONFIG REQUIRED PATHS build/dep-wx)` | `wx::core wx::base wx::adv` | 预构建由 tools/build-wx.ps1 产（`wxBUILD_SHARED=OFF`） |
| imgui | 源码直接编入静态库（core+backends） | `cppgui_imgui d3d11 dxgi d3dcompiler`（SDL2 变体：`cppgui_imgui_sdl2 opengl32`） | master 无 docking/多视口 |
| FTXUI | `add_subdirectory` | `ftxui`（INTERFACE 聚合） | `FTXUI_BUILD_{EXAMPLES,TESTS,DOCS,MODULES}=OFF` |
| tvision | `add_subdirectory` | `tvision` | `TV_BUILD_EXAMPLES=OFF`（默认 ON） |

## 四、实测坑位索引（134 条 → 按框架归组）

### wxWidgets（38 条）

- 命令行/入口：基类 OnInit 吞未注册参数退出码 255（01）；AddSwitch 短名长名顺序（01）
- 编码：窄字面量中文按 GBK 解释，一律 FromUTF8（01/02/04，源码与 .rc 同病）
- 菜单/工具栏：命令号避开标准 ID（02）；AddTool 后必须 Realize（02）；radio 组靠连续 Append（02）；PopupMenu 吃客户区坐标（02）；UPDATE_UI 空闲高频（02）
- Sizer：wxTextCtrl 第 3 参是初值不是样式——撞私有 `wxString(int)` C2248（03）；proportion 管主轴、wxEXPAND 管交叉轴（03）；对齐旗标与 wxEXPAND 互斥（03）；AddSpacer 固定 vs AddStretchSpacer 弹性（03）；SetSizerAndFit 会撑大窗口（03）
- 控件：事件参数类型因控件而异（04）；RadioBox majorDimension 双语义（04）；ListCtrl 三步填格不能乱序（04）；Gauge 无事件（04）
- 对话框：Validate 负路径弹「Validation conflict」模态框（05）；wxTextValidator 3.3 无 SetMinLength（05）；过滤器与 Validate 是两道闸（05）；OK 按钮别自己 Bind（05）；标准对话框栈上构造即可（05）
- 绘图：OnPaint 必须无条件创建 paint DC（06）；双缓冲前提 wxBG_STYLE_PAINT（06）；Refresh(false) ≠ Refresh()（06）；CaptureMouse/ReleaseMouse 配对（06）；wxGraphicsContext::Create 返回裸指针（06）；读 paint 计数先 wxYield（06）
- docview/线程：缺 wxDECLARE_DYNAMIC_CLASS → CreateDocument 返 nullptr（07）；非 SILENT 弹选模板框（07）；SaveObject/LoadObject 双签名随 wxUSE_STD_IOSTREAM（07）；UI 线程外禁碰控件（07）；DETACHED 线程指针是状态位（07）；OnExit 别 delete 文档管理器（07）

### Dear ImGui（34 条）

- 骨架：NewFrame 三步顺序固定（08）；WM_SIZE 里不能直接 ResizeBuffers（08）；最小化后必须降速（08）；WndProc 先喂 imgui 且屏蔽 Alt 菜单（08）；SDL2 main 代理坑（08）；IniFilename 默认写 cwd（08/10）
- 控件：同名控件同 ID 状态串扰——PushID/PopID 或 `##id`（09）；PushID/PopID 严格配对（09）；返回值只在那一帧有效（09）；状态必须自己持有（09）；默认字体只有 ASCII（09）
- 窗口：Begin 返回 false 也要 End（10）；ImGuiCond_Always 与拖窗口打架（10）；NoSavedSettings 与 FirstUseEver 成对（10）；ChildWindow 不是子控件容器（10）；没有布局管理器（10）
- 表格：imgui 不替你排序（11）；SpecsDirty 记得清零（11）；用 stable_sort（11）；列宽策略要显式（11）；BeginPopupContextItem 挂最后一个 item（11）；PlotLines offset 即环形写指针（11）
- 绘制/字体：DrawList 是屏幕绝对坐标（12）；字体加载时机只有一条缝——CreateContext 后首帧前（12）；范围名没有 SimplifiedFull，实际是 SimplifiedCommon（12）；字形按需烘焙首帧计数小（12）；字体路径带回退链（12）；运行中改字体要触发图集重建（12）
- 综合：自动滚底别无条件 SetScrollHereY（13）；滑条副作用每帧触发（13）；FontGlobalScale 要每帧赋（13）；环形缓冲差一错误（13）；图例消隐用 `##` 前缀（13）

### FTXUI（26 条）

- DOM：GraphFunction 形状是 `vector<int>(int w, int h)`（14）；渲染到字符串必须 Dimension::Fixed 钉宽（14）；ToString 自带 CRLF，Windows 管道再叠成 `\r\r\n`（14）
- 组件：Toggle 状态是 int 不是 bool（15）；ScreenInteractive 已改名 App（15）；`Renderer(child, fn)` 不自动画 child（15/18）；CatchEvent 返回 true 才吃掉事件（15）；TUI 改控制台 CP，.NET 管道须钉 UTF-8（15）
- 布局：Constraint 没有 PERCENT（16）；FlexboxConfig 字段名 justify_content（16）；ResizableSplit 进不了渲染到字符串管线（16）；EQUAL 挡不住交叉轴拉伸（16）
- 样式：256 色无 Color256() 工厂——`Color::Palette256` 嵌套枚举（17）；HSV 的 hue 是 uint8_t（17）；Canvas 无画圆 API 参数方程手画（17）；LinearGradient 改 builder（17）；SGR/OSC8 转义在 ToString 原样保留（17）
- 组合：虚函数叫 OnRender() 非 Render()（18）；Maybe 参数序组件在前（18）；Modal 三参签名（18）；跨线程正道 `Post(Task{Closure})`（18）
- 综合：业务结构别叫 Task 撞名（19）；帧内容不得依赖时序（19）；selftest 别进带 Input 的终端循环（19）；无头触发 Button 喂 Event::Return（19）；`menu |= CatchEvent` 与 `CatchEvent(menu, fn)` 两用法（19）

### tvision（36 条）

- 骨架：Uses_* 宏必须写在 include 之前（20/22）；命令号从 100 起（20/21）；cmTimerExpired 是广播不是命令（20）；菜单栏/状态栏 TRect 自己剪一行（20）；先基类 handleEvent 再 clearEvent（20）；execView 是模态嵌套循环（20/21）
- 对话框：虚基类 TWindowInit 列基类列表最前（21）；TInputLine 的 TRect 高度恒 1（21）；对话框不自动居中（21）；execView 模态等输入 selftest 挂死——免模态直构取数（21）；valid() 兼任取数钩子（21）；销毁走 TObject::destroy（21）
- 视图：广播不许 clearEvent——吃掉 cmTimerExpired 挂死 60s（22）；Uses_TBackground 不展开则 TBackground*/TView* 不可比（22）；TView 默认不收键盘（22）；setLimit 须等 sfExposed（22）；writeChar/writeStr 吃调色板下标 vs TDrawBuffer 吃真色号（22）；scrollTo 静默夹取（22）
- 调色板/表单：三级间接条目=属主下标不是色号（23）；越界下标不报错返 errorAttr 0xCF（23）；窗口级覆写是整体替换（23）；validator 是私有成员（23）；valid(cmOK) 失败路径弹模态（23）；selftest 禁 rand（23）
- 编辑器：save() 前必须填 fileName（24）；缓冲行分隔 \r\n 使 bufLen≠strlen（24）；命令接线分三层应用层别越位（24）；构造期先全禁编辑命令（24）；取字走 bufChar 跨缝（24）；execDialog 五步包装（24）

## 五、验证口径速记

- 判定：构建 exit 0 + `--selftest` exit 0（60s 超时）+ stdout（或 sidecar）含 `==== NN ` 起/`结束 ====` 止 + stderr 空 + 两跑 stdout 一致
- 产物去向：控制台子系统（imgui/FTXUI）走 stdout；GUI/直写控制台（wx/tvision）走 sidecar `build/selftest-<名>.txt`
- 文档对账：`python tools/check_docs.py` 五关——现场重跑二进制做输出子序列对账（反假绿）
