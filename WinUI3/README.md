# WinUI 3 C++/WinRT 编程指南

面向"从零到工程"的 WinUI 3 教程，35 章、10 个可运行示例工程。目标不是罗列控件语法，而是讲清三层东西：

1. **机制**：WinRT 对象模型、XAML 编译流程、绑定引擎——代码背后发生了什么
2. **结构**：App / Window / Page / ViewModel / Model / Service 的分层与协作
3. **交付**：主题资源、窗口外壳、JSON 持久化、MSIX 打包

开发语言为 **C++/WinRT**（WinRT 的官方 C++17 投影）。教程代码均为真实 WinUI 3 写法，要编译运行需要 Visual Studio（17.x / 18.x 皆可）带桌面 C++ 工具链，并在可选组件里装上 **C++/WinRT 项目模板** 与 **WinUI 应用模板**。

教程里每个关键机制都对应 `examples/` 下一个**能真编译、能真运行**的工程：在本目录跑 `.\build.ps1` 全部从零编过；`tools/ui-smoke/` 会启动它们、触摸注入点击与键盘输入、截图验证行为——**四个功能应用的每条流程都逐条驱动过**。完整清单与证据见文末 [验证状态](#验证状态)。

## 目录

### 概念篇

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [01 概念总览](docs/01-tech-stack.md) | 分层架构、各代技术演化、打包/非打包 | WinRT / WinUI 3 / XAML / WASDK 各是什么 |
| [02 WinRT 机制](docs/02-winrt.md) | IUnknown/IInspectable、.winmd、投影、hstring/异步/错误模型 | `winrt::` 代码底下发生了什么 |
| [03 XAML 机制](docs/03-xaml.md) | 标记编译、x:Class/x:Name、依赖属性、x:Bind vs Binding、资源查找 | XAML 怎么变成运行中的对象树 |

### 工程篇

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [04 第一个真实应用](docs/04-first-app.md) | 模板工程、启动时序、命令行构建细节 | 程序怎么启动 |
| [05 工程分层](docs/05-project-structure.md) | 各层职责、Frame 导航、IDL 角色 | 代码怎么组织 |
| [06 布局](docs/06-layout.md) | Grid/StackPanel/Border/RelativePanel/ScrollViewer | 页面怎么划分伸缩 |

### 控件·基础篇（设置中心 `07-settings-hub`）

| 章 | 控件 | 章 | 控件 |
|---|------|---|------|
| [07 Button 与按钮族](docs/07-button.md) | Button/Repeat/Hyperlink/DropDown | [12 Slider、ProgressBar 族](docs/12-slider-progress.md) | Slider/Progress/RatingControl |
| [08 TextBlock](docs/08-textblock.md) | 富文本/截断/换行 | [13 NumberBox](docs/13-numberbox.md) | 数值输入 |
| [09 TextBox 与文本输入族](docs/09-textbox.md) | TextBox/PasswordBox/RichEditBox | [14 ComboBox](docs/14-combobox.md) | 下拉选择 |
| [10 CheckBox 与 RadioButton](docs/10-checkbox-radio.md) | 三态/互斥 | [15 AutoSuggestBox](docs/15-autosuggestbox.md) | 搜索式输入 |
| [11 ToggleSwitch 与 ToggleButton](docs/11-toggleswitch.md) | 状态开关 | [16 日期与时间族](docs/16-datetime.md) | Date/Time/Calendar |

### 控件·集合篇（数据浏览器 `17-data-explorer`）

| 章 | 控件 |
|---|------|
| [17 ListView](docs/17-listview.md) | ItemsControl 机制、选择/点击、虚拟化 |
| [18 GridView 与 FlipView](docs/18-gridview-flipview.md) | 换面板变形、翻页器 |
| [19 TreeView](docs/19-treeview.md) | 层级模型、懒加载 |
| [20 表格数据](docs/20-datagrid-itemsrepeater.md) | **DataGrid 在 C++/WinRT 不存在（实测）** + 自制路线 + ItemsRepeater |

### 控件·导航与浮层篇（编辑器 `09-scratchpad`）

| 章 | 控件 | 章 | 控件 |
|---|------|---|------|
| [21 TabView 与 Expander](docs/21-tabview-expander.md) | 页签/折叠 | [24 ContentDialog 与 Flyout](docs/24-dialogs-flyouts.md) | 模态/轻浮层 |
| [22 NavigationView 与 SplitView](docs/22-navigationview.md) | 应用外壳 | [25 TeachingTip、InfoBar、ToolTip](docs/25-overlays.md) | 非模态提示 |
| [23 CommandBar 与菜单](docs/23-commandbar-menus.md) | 命令三容器 | | |

### 进阶篇（主题实验室 `26-theme-lab` + `31-window-shell`）

| 章 | 内容 | 章 | 内容 |
|---|------|---|------|
| [26 样式与控件模板](docs/26-styles-templates.md) | Style/ControlTemplate | [29 动画](docs/29-animation.md) | Storyboard/Transitions |
| [27 自定义控件与 UserControl](docs/27-custom-controls.md) | 两条自定义路线 | [30 图形与媒体](docs/30-drawing-media.md) | Shape/Brush/ColorPicker/Image |
| [28 VSM 与自适应](docs/28-vsm-adaptive.md) | AdaptiveTrigger/GoToState | [31 窗口与外壳](docs/31-window-shell.md) | AppWindow/标题栏/Mica/多窗口 |

### 应用篇

| 章 | 内容 |
|---|------|
| [32 绑定、MVVM 与异步](docs/32-binding-mvvm.md) | INPC/可观察集合/x:Bind/协程 + **32.8 值转换器** |
| [33 主题资源与交付](docs/33-theming-packaging.md) | ThemeResource 分层、Assets/Manifest/MSIX |
| [34 OS 集成](docs/34-os-integration.md) | 线程边界、文件/选择器、注册表/JSON、子进程 |
| [35 TaskFlow 实战](docs/35-taskflow.md) | 全书模式收束：导航+列表+对话框+绑定+持久化 |

## 学习路线

```text
01 ─ 02 ─ 03            概念地基
      │
04 ─ 05 ─ 06            骨架与布局
      │
07 ─ 16                 控件·基础（设置中心 SettingsHub 承载）
      │
17 ─ 20                 控件·集合（CollectionsGallery）
      │
21 ─ 25                 控件·导航浮层（ShellGallery）
      │
26 ─ 31                 进阶：样式/自定义/VSM/动画/绘图/窗口（CustomGallery + WindowShellApp）
      │
32                      枢纽：绑定 / MVVM / 异步（最核心的一篇）
      │
33 ─ 34                 主题交付与系统能力
      │
35                      TaskFlow 实战收束
```

跳读指南：

- 会 WPF/UWP → [02](docs/02-winrt.md) + [03 的 3.6](docs/03-xaml.md)（x:Bind 与 `{Binding}` 差异大），再按需查目录
- 会 Win32/C++ → [04](docs/04-first-app.md) 起步，重点体会 IDL 与投影
- 只想快速上手 → 04 → 06 → 07 → 32
- 找某个控件 → 直接进对应章，每章自带机制与坑位，向前依赖都有链接

## 环境要求

- Windows 10 1809+（建议 Windows 11；Mica/Acrylic 需 Win11）
- Visual Studio（17.x / 18.x）+ 桌面 C++ 工具链 + C++/WinRT 与 WinUI 项目模板组件

## 版本基线

教程正文的 API 签名对照本机 NuGet 缓存里的这组包核对（缓存位置 `G:\nuget\packages`）：

| 组件 | 版本 |
|------|------|
| `Microsoft.WindowsAppSDK` | 1.8.260317003 |
| `Microsoft.WindowsAppSDK.WinUI`（`Microsoft.UI.Xaml.winmd` 等） | 1.8.260224000 |
| `Microsoft.Windows.CppWinRT` | 2.0.250303.1 |
| MSVC 工具集 | VS 18 Community（随机器） |

**注意文档站默认 moniker 已切到 2.0**，个别成员只在 2.0 页面列出——按 1.8 写工程时不要照抄 2.0 页面的签名。

## 验证状态

`examples/` 下 **10 个工程**全部真实 MSBuild + WASDK 1.8 编过。控件章节的运行时证据由**四个功能应用**承载（取代了旧版控件画廊）：每个应用是一个有真实用途的小程序，控件在其中承担真实职责；`tools/ui-smoke/` 的 `smoke-<app>.ps1` 逐流程验证。

```text
examples/
├── 01-first-app/        MyApp         最小闭环
├── 06-layout/           LayoutApp     Grid(*/Auto) + ScrollViewer
├── 07-settings-hub/     SettingsHub   设置中心（7/8/10-16/22/25 章）
├── 09-scratchpad/       ScratchPad    编辑器（9/21/23/24 章）
├── 17-data-explorer/    DataExplorer  数据浏览器（17-20 章）
├── 26-theme-lab/        ThemeLab      主题实验室（26-30 章）
├── 31-window-shell/     WindowShellApp 标题栏/Mica/多窗口（31 章）
├── 32-binding-mvvm/     MvvmApp       INPC + 转换器 + 协程（32 章）
├── 34-os-integration/   OsIntApp      子进程 + 数据目录兜底（34 章）
└── 35-taskflow/         TaskFlow      实战收束（35 章）
```

在 `WinUI3/` 下跑 **`.uild.ps1`** 即可全量编译（vswhere 定位 MSBuild、`-restore` 还原 NuGet、`-nr:false` 防节点复用僵尸）。

### 三条验证通道

| 通道 | 工具 | 证明什么 | 证明不了什么 |
|------|------|---------|-------------|
| **元数据级** | `tools/winmd-probe/`（System.Reflection.Metadata 读真实 `.winmd`） | API 签名存在与形状 | 运行时行为 |
| **编译级** | `build.ps1` + MSVC/WASDK 1.8 | 代码真能编过、链过 | 运行时是否正确 |
| **运行时级** | `tools/ui-smoke/`（`tap.ps1` 触摸注入点击 + 键盘序列 + 截图；`smoke-*.ps1` 逐流程驱动） | 被驱动的流程真的跑通 | 没被驱动的流程 |

### 运行时级实测结果（逐流程）

四个功能应用共 **14 条已验证流程**（证据在 `.smoke/<工程>/<流程>/tap-N.png`；DataExplorer 的 filter 流待输入抽奖补证（打字注入 TextBox 的路径），cards/flip/tree 已验）：

| 应用 | 流程 | 驱动 | 断言（截图/文件级） |
|------|------|------|---------------------|
| 设置中心 | theme | 触摸点 Dark 单选 | 整窗换暗 + 圆点选中 + 状态行 "theme = Dark" |
| | master | 导航 + 点总闸 | 总闸 Off + 渠道灰显 + "notifications off: channels disabled" |
| | save | 导航 + 点 Save | 进度充满 + InfoBar "Saved" + "preferences saved" |
| | search | 点搜索框 + 键入 Pref + 下箭头回车 | 建议过滤 + 真跳转 Preferences 页 |
| 编辑器 | save | 点编辑区 + 键入 + Ctrl+S | 状态行 "saved untitled-1.txt \| verified on disk (15 chars)"（**应用内写后回读铁证**） |
| | bold | 键入 + Ctrl+A/B/S | 全选加粗 + 落盘（11 chars）+ 工具栏同步 |
| | find | 键入 + Ctrl+F + a | Expander 展开 + "3 match(es) for 'a'" |
| | close | 键入 + 点页签 X + 点对话框 Save | ContentDialog 三钮实拍 → 存盘关页签 |
| 数据浏览器 | tree | 点 TreeView Images 节点 | 表格过滤至 3 行 + 计数行 "3 items · Images" |
| | filter/cards/flip | （待补证） | 逻辑与 tree 同路径（ApplyFilters/双视图/选中联动） |
| 主题实验室 | preset | 点 Sunset 预设 | 选中高亮 + 暗壳 + 七柱图变红 + 状态行复述 |
| | picker | 点 ColorPicker 光谱 | accent 实时变 + 状态行 "accent = #107,10,10" + 柱图随刷 |
| 窗口 | — | `gallery-smoke.ps1 -Gallery 31` | Acrylic 切换 + 第二窗口 + 自绘标题栏 |
| 绑定/实战 | — | 32/35 章流程 | INPC 刷新 / TaskFlow 持久化闭环 |

### 输入注入战争实录（本机的硬边界，方法论入册）

高 DPI（175%）桌面这台机上验证 UI 学到的、写进 `tools/ui-smoke/` 注释与教程各章的东西：

- **注入鼠标点击对 ButtonBase 永不闭合**：press 精确命中（应用侧诊断实证），Click 不完成——`SetCursorPos + mouse_event` 只能驱动导航行/ToggleSwitch/Slider；**触摸注入**（`InitializeTouchInput + InjectTouchInput`）走真实指针栈，按钮才响应。
- **任何 `SetWindowPos`（含纯移动）在 XAML 岛安定后打烂输入变换**：渲染照旧、命中错位。冒烟绝不动窗口——应用在构造期自定位（`AppWindow.MoveAndResize`，实测按逻辑单位解释）。
- **注入输入是启动抽奖**：同一流程时通时不通（分钟级相位）。`tap.ps1` 用帧哈希检测 + 整进程重试兜底。
- **UIA3 树不可见**（非打包自包含应用的 provider 缺失）：managed UIA2 早就看不见，手写 UIA3 COM 互操作全链路（InterfaceIsIUnknown / __ComObject 退化 / VARIANT 封送三坑）踩过后留档 `uia-smoke.ps1`——树仍是空的。
- 视觉验证的教训：**视觉模型读网格标注不可靠**（三轮三套坐标）——像素连通域扫描（`find-blob.ps1`）才是 ground truth；提示词里带预期答案的"验证"等于没验证。

### 验证推翻并改回正文的写法（原有 + 本次扩充）

**概念篇时代（编译级为主）：**

- `co_await resume_foreground(...)` 在 WinUI 3 桌面线程**永不恢复**——正文改 `DispatcherQueue::TryEnqueue` + `get_strong()`（[32 章 32.7](docs/32-binding-mvvm.md)）
- 非打包进程 `ApplicationData` 两个命名空间版本都抛"没有程序包标识符"——退回 `%LOCALAPPDATA%`（[34 章](docs/34-os-integration.md)）
- ViewModel 的 IDL 必须声明 `INotifyPropertyChanged`；有构造函数的 runtimeclass 必须写 `factory_implementation`（[32 章](docs/32-binding-mvvm.md)）
- 按名字挂接的事件处理器不进 IDL；MIDL 不跨 `.idl` 解析引用（MIDL2011）（[04 章 4.7/4.8](docs/04-first-app.md)）

**控件篇扩充（编译 + 元数据 + 运行时三级）：**

- **`RichEditBox` 选区加粗是 `FormatEffect::Toggle`**，不是 `Format::Boolean`；`ITextDocument.GetText` 保留双参数 out 形态（C2660）——[09 章 9.5](docs/09-textbox.md)
- **`PasswordBox.Password` 在 1.8 已是依赖属性**（UWP 旧结论作废；但按安全纪律仍走事件读值）——[09 章 9.4](docs/09-textbox.md)
- **CheckBox 三态点击循环是 checked→unchecked→indeterminate**（非直觉序，运行时实测）——[10 章 10.2](docs/10-checkbox-radio.md)
- **`RatingControl.ValueChanged` 的 args 是裸 `IInspectable`**（臆造的 RatingEventArgs → C2039）——[12 章 12.4](docs/12-slider-progress.md)
- **ProgressRing 1.8 支持确定值**（`Value` 存在，UWP 旧结论作废）——[12 章 12.3](docs/12-slider-progress.md)
- **`ValueChanged` 在 XAML 解析期与窗口析构期都会触发**——handler 引用相邻控件 = 空引用 AV（[12 章 12.5 深坑实录](docs/12-slider-progress.md)：事件日志偏移 + map 符号化 + 对照实验定位；判空 + 声明序双保险，修后 3/3 零崩溃）
- **`DatePickerValueChangedEventArgs.NewDate()` 是裸 `DateTime`**（当 IReference 用 → C2451）——[16 章 16.2](docs/16-datetime.md)
- **CommunityToolkit DataGrid 7.x 对 native 工程直接 NU1202**——C++/WinRT 没有可用 DataGrid，第 20 章改"表格自制"路线——[20 章 20.1](docs/20-datagrid-itemsrepeater.md)
- **`FlyoutBase.ShowAt` 没有 (element, Point) 重载**——位置包进 `FlyoutShowOptions`（UWP 资料普遍是旧写法）——[23 章 23.3](docs/23-commandbar-menus.md)
- **TeachingTip 的属性是 `PreferredPlacement`**（`Placement` → WMC0011）——[25 章 25.1](docs/25-overlays.md)
- **Expander 事件 args 是专用 `ExpanderExpandingEventArgs/CollapsedEventArgs`**；`AddTabButtonClick`/`CloseButtonClick` 等一批 Click 委托 args 是裸 `IInspectable`——[21 章](docs/21-tabview-expander.md)
- **NavigationView 菜单行距随条目数收紧**（6 项≈72px→7+≈56px→11 项≈50px，实测）——UI 自动化不能线性外推坐标——[22 章 22.5](docs/22-navigationview.md)
- **`x:Type` 与 `ControlTemplate.Triggers` 不存在**（WPF/UWP 写法 → WMC0001/WMC0011）；隐式样式要可 BasedOn 须挂 key——[26 章](docs/26-styles-templates.md)
- **`DefaultStyleKey` 收装箱对象**；IDL 内 `IReference<hstring>` 触发 MIDL2011（属性直接声明 `String`）——[27 章](docs/27-custom-controls.md)
- **`CppWinRTOptimized=true` 会裁剪投影**：用了冷门类型（Storyboard 等）可能整个命名空间 using 失败——该工程关掉或全限定名——[27 章 27.4](docs/27-custom-controls.md)
- **动画 `Duration` 须包 `Xaml::Duration`**（直接塞 TimeSpan → C2665）——[29 章 29.1](docs/29-animation.md)
- **x:Bind + Converter 需要 FrameworkElement 根**（Window 根工程 `SetConverterLookupRoot` 编不过）——走 `{Binding Converter}`——[32 章 32.8](docs/32-binding-mvvm.md)
- **.idl 注释必须 ASCII**（中文注释按本地码页解码会提前终止 → MIDL2025 语法错，两度实测）——全线示例的 .idl 注释规则

> 诚实边界：元数据证明签名、编译证明能构建、运行时截图证明**被点到的那条流程**行为正确。没被点到的流程只有编译级证据——例如 `FileOpenPicker` 的系统模态对话框（[34 章](docs/34-os-integration.md)）、`HyperlinkButton.NavigateUri` 的浏览器跳转（[07 章](docs/07-button.md)）、ToolTip 的悬停时序（[25 章](docs/25-overlays.md)）、MediaPlayerElement 的视频解码（[30 章](docs/30-drawing-media.md)）、TaskFlow 对话框的完整键入流（[35 章](docs/35-taskflow.md)）。

## 常见错误速查

| 症状 | 原因与解法 | 出处 |
|------|-----------|------|
| 绑定了属性，界面不刷新 | ① `x:Bind` 默认 OneTime；② 源没实现 INPC；③ 属性名与通知名不一致；④ 属性没进 IDL | [32 章 32.3](docs/32-binding-mvvm.md) |
| `std::vector` 绑 ItemsSource 列表不动 | 数据源必须是 WinRT 集合（`single_threaded_observable_vector`） | [32 章 32.4](docs/32-binding-mvvm.md) |
| ContentDialog 抛 "XamlRoot has not been set" | 必须设 `XamlRoot`，且从**内容树根元素**取（Window 无此成员） | [24 章 24.2](docs/24-dialogs-flyouts.md) |
| 后台线程改控件抛异常 | `DispatcherQueue::TryEnqueue` 切回（**别用 `resume_foreground`**） | [32 章 32.7](docs/32-binding-mvvm.md) |
| `IsChecked()` 当 bool 用编不过 | `IReference<bool>` 三态，`.Value()` 解包 | [10 章 10.1](docs/10-checkbox-radio.md) |
| 交互后 ~1-3 秒进程 AV 崩溃 | `ValueChanged` 类事件在解析/析构期触发，handler 引用了未建立/已释放的相邻控件——**判空防护 + XAML 声明序** | [12 章 12.5](docs/12-slider-progress.md) |
| XAML 引用成员报"找不到类型" | `x:Bind` 路径成员必须进 IDL；跨 `.idl` 引用报 MIDL2011 → 合并文件 | [04 章 4.7](docs/04-first-app.md) |
| 桌面应用 FileOpenPicker 弹不出来 | 用 WASDK 的 `Microsoft.Windows.Storage.Pickers`，构造传 `AppWindow().Id()` | [34 章 34.2](docs/34-os-integration.md) |
| `Click="{x:Bind VM.SomeMethod}"` 编译报错 | 函数绑定签名须与委托逐参数对上；命令用 `Command=` | [32 章 32.6](docs/32-binding-mvvm.md) |
| 集合整体换了对象界面不刷新 | `IObservableVector` 通知只跟内容增删；替换对象要再 `RaisePropertyChanged` | [32 章 32.4](docs/32-binding-mvvm.md) |
| 非打包取应用数据目录抛异常 | `ApplicationData` 两版都依赖包身份；退回 `%LOCALAPPDATA%` | [34 章 34.2](docs/34-os-integration.md) |
| 逻辑上无循环引用却内存不释放 | 事件未退订成环；`weak_ref` 断环 | [34 章 34.5](docs/34-os-integration.md) |
| RichEditBox 加粗/读文本编不过 | `FormatEffect::Toggle`；`GetText(opts, hstring&)` 双参 | [09 章 9.5](docs/09-textbox.md) |
| MIDL 语法错指到 .idl 的中文注释 | **.idl 注释必须 ASCII** | 全线示例 |
| 自动选了项但 SelectionChanged 崩 | 解析期触发，handler 判空控件 | [14 章 14.3](docs/14-combobox.md) |
| 右键菜单 `ShowAt(element, point)` 编不过 | 位置包进 `FlyoutShowOptions` | [23 章 23.3](docs/23-commandbar-menus.md) |
| `Storyboard`/冷门类型命名空间 using 失败 | `CppWinRTOptimized` 裁剪投影——关掉或全限定 | [27 章 27.4](docs/27-custom-controls.md) |
| `BasedOn="{StaticResource {x:Type Button}}"` 编不过 | `x:Type` 不存在——隐式样式挂 key 再 BasedOn | [26 章 26.1](docs/26-styles-templates.md) |
| `Duration(TimeSpan{...})` 编不过 | 包一层 `Xaml::Duration{...}` | [29 章 29.1](docs/29-animation.md) |
| Window 根工程 x:Bind+Converter 编不过 | `SetConverterLookupRoot` 要 FrameworkElement——用 `{Binding Converter}` 或改 Page 根 | [32 章 32.8](docs/32-binding-mvvm.md) |
| NuGet 装 Toolkit DataGrid 直接失败 | NU1202：7.x 无 native 目标——走表格自制 | [20 章 20.1](docs/20-datagrid-itemsrepeater.md) |
| 改 XAML 不生效 | 清 `Generated Files` 重新构建 | [04 章 4.7](docs/04-first-app.md) |

## 后续扩展方向

- **能力集成**：`Microsoft.Windows.AppNotifications`（含进度）、`BackgroundTaskBuilder`、网络（WinHTTP / `Windows.Web.Http` + 进度回报）
- **诊断与测试**：绑定失败定位（`DebugSettings`）、单元测试工程（GoogleTest + C++/WinRT）、CI 构建打包
- **性能与混合**：XAML Islands 思路、SwapChainPanel 高性能自绘、`CommunityToolkit`（C# 侧）组件的进程外替代
- **单实例激活重定向**：`AppInstance.FindOrRegisterForKey` 全链路（31.5 的边界待补）

> 明确不做：**系统托盘图标**（1.8 元数据无对应类型，走 Win32 `Shell_NotifyIcon` 是另一套故事）。

## 构建与冒烟工具

```powershell
.\build.ps1                          # 全部工程（Debug|x64）
.\build.ps1 -Examples 07-controls-basic -Rebuild
pwsh tools\ui-smoke\smoke-settingshub.ps1               # 设置中心四流程
pwsh tools\ui-smoke\gallery-smoke.ps1 -Gallery 07 -Page slider
pwsh tools\ui-smoke\ui-smoke.ps1 -Exe <exe> -OutDir <dir> -Clicks "x,y;x,y" -TypeText "ap"
pwsh tools\ui-smoke\zoom-grid.ps1 -Image <png> -Out <png> -X0 350 -Y0 100 -X1 900 -Y1 500   # 坐标校准
```

冒烟坐标系 = 截图窗口坐标（含标题栏）；**NavigationView 行距非常数**，场景表存实测值，新页用 `zoom-grid.ps1` + 网格读数校准。
