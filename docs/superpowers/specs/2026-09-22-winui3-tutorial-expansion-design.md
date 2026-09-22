# WinUI 3 教程 10 → 35 章大扩充设计

日期：2026-09-22
状态：已批准（用户逐项确认了控件深度、示例组织、实战篇、验证深度四个决策）

## 背景与目标

现有 WinUI 3 C++/WinRT 教程 10 章 / 3074 行 / 5 个示例工程，控件只有 1 章（249 行塞 7 类控件）。参照 WPF（25 章/21 例）、MFC（25 章）、Lazarus（40 章/45 例）的规模，扩充到约 3 倍：

- **35 章**、正文约 9000–9500 行
- 核心控件每个专门一章（19 个专门控件章），次要控件按族合并
- 示例工程 5 → 10 个（按篇分组的画廊工程模式）
- 新增实战篇收尾（TaskFlow 任务管理器）
- 验证：全部工程编译全绿 + **每个画廊页都过 ui-smoke 启动/点击/截图**

## 章节结构（35 章，整体重新编号）

| 篇 | 章 | 内容 | 来源 |
|---|---|---|---|
| 概念 | 1–3 | 概念总览 / WinRT 机制 / XAML 机制 | 原 1–3 保留 |
| 工程 | 4–5 | 第一个真实应用 / 工程分层 | 原 4–5 保留 |
| 布局 | 6 | Grid/StackPanel/Border/RelativePanel/ScrollViewer/VariableSizedWrapGrid + 尺寸对齐 | 原 7 扩充 |
| 控件·基础 | 7 | Button 与按钮族（RepeatButton/HyperlinkButton/DropDownButton） | 新 |
| 控件·基础 | 8 | TextBlock 与文本呈现 | 新 |
| 控件·基础 | 9 | TextBox 与文本输入族（校验；PasswordBox、RichEditBox 两节） | 原 6.2 扩充 |
| 控件·基础 | 10 | CheckBox 与 RadioButton | 原 6.3 扩充 |
| 控件·基础 | 11 | ToggleSwitch 与 ToggleButton | 原 6.6 扩充 |
| 控件·基础 | 12 | Slider、ProgressBar、ProgressRing 与 Rating | 原 6.6 扩充 |
| 控件·基础 | 13 | NumberBox | 新 |
| 控件·基础 | 14 | ComboBox | 原 6.4 扩充 |
| 控件·基础 | 15 | AutoSuggestBox | 新 |
| 控件·基础 | 16 | 日期时间族（DatePicker/TimePicker/CalendarDatePicker/CalendarView） | 新 |
| 控件·集合 | 17 | ListView | 原 6.5 扩充 |
| 控件·集合 | 18 | GridView 与 FlipView | 新 |
| 控件·集合 | 19 | TreeView | 新 |
| 控件·集合 | 20 | DataGrid（CommunityToolkit）与 ItemsRepeater | 新 |
| 控件·导航浮层 | 21 | TabView 与 Expander | 新 |
| 控件·导航浮层 | 22 | NavigationView 与 SplitView | 新 |
| 控件·导航浮层 | 23 | CommandBar 与菜单（MenuBar/MenuFlyout/AppBarButton） | 新 |
| 控件·导航浮层 | 24 | ContentDialog 与 Flyout | 原 6.7 扩充 |
| 控件·导航浮层 | 25 | TeachingTip、InfoBar 与 ToolTip | 新 |
| 进阶 | 26 | 样式与控件模板 | 新 |
| 进阶 | 27 | 自定义控件与 UserControl | 新 |
| 进阶 | 28 | VisualStateManager 与自适应（AdaptiveTrigger） | 新 |
| 进阶 | 29 | 动画：Storyboard 与过渡 | 新 |
| 进阶 | 30 | 图形与媒体（Shape/Path/Image/MediaPlayerElement、ColorPicker） | 新 |
| 进阶 | 31 | 窗口与外壳（AppWindow/标题栏/Mica/多窗口/单实例） | 新（README 后续方向） |
| 应用 | 32 | 绑定、MVVM 与异步（**新增值转换器节**） | 原 8 重编号 |
| 应用 | 33 | 主题资源与交付 | 原 9 重编号 |
| 应用 | 34 | OS 集成 | 原 10 重编号 |
| 应用 | 35 | TaskFlow 实战（NavigationView + ListView + 绑定 + 异步 + JSON 持久化） | 新 |

## 示例工程（5 → 10）

```text
examples/
├── 01-first-app             保留
├── 06-layout                原 07-layout 重编号；原 06-controls 删除（内容吸收进画廊）
├── 07-controls-basic        新画廊：Button/TextBlock/TextBox/CheckBox/ToggleSwitch/Slider-Progress/NumberBox/ComboBox/AutoSuggestBox/DateTime 10 页
├── 17-controls-collections  新画廊：ListView/GridView/TreeView/DataGrid-ItemsRepeater 4 页
├── 21-controls-shell        新画廊：TabView-Expander/NavigationView/CommandBar/Dialogs-Flyout/Overlays 5 页
├── 26-customization         新画廊：Styles/CustomControl/VSM/Animation/Drawing-Media 5 页
├── 31-window-shell          新小工程：标题栏/Mica/多窗口
├── 32-binding-mvvm          原 08 重编号
├── 34-os-integration        原 10 重编号
└── 35-taskflow              新实战工程
```

- 画廊页 = 每章一个 `Page`，NavigationView 导航；页面是「最小可运行演示 + 关键属性/事件」
- build.ps1 免改（自动发现 `examples/*/*.vcxproj`）
- 版本基线不变：Windows App SDK 1.8 / MSVC 14.44 等，按本机 NuGet 缓存核对

## 验证策略（三条通道不动，运行时级扩到每页）

1. **编译级**：11 个工程 `build.ps1` 全绿（底线）
2. **运行时级**：ui-smoke.ps1 扩展出场景表驱动——每个画廊一份场景定义（启动 → 点导航项 → 截图 → 页内交互 → 再截图），约 29 条流程全跑；截图证据人工判读后写入 README 验证状态
3. **元数据级**：winmd-probe 核对新增控件 API 签名（TreeView/CalendarView/AutoSuggestBox 等，含 CommunityToolkit DataGrid 的 winmd）

实测推翻正文的写法照旧回写章节 + README「验证推翻」清单 + 错误速查表扩容。

## 文档规格

- 每章沿用现有风格：机制先行（控件解决什么问题、核心属性背后的机制）→ 真实代码（与画廊页对应）→ 实测坑位
- 原 06-controls 的 7 节内容拆解迁移进 7–16 章；原 08 的素材留 32 章并加值转换器节
- README 重写：新目录、学习路线图、验证状态、错误速查表

## 实施阶段（每阶段收尾 build.ps1 全绿 + smoke 批跑，不绿不进下一阶段）

1. 画廊工程骨架（NavigationView 外壳 + 页面导航模式）+ ui-smoke 场景驱动改造 + 目录重编号
2. 控件·基础篇：10 章 + 画廊 A（07-controls-basic）
3. 控件·集合篇：4 章 + 画廊 B（17-controls-collections）
4. 控件·导航浮层篇：5 章 + 画廊 C（21-controls-shell）
5. 进阶篇：6 章 + 画廊 D（26-customization）+ 31-window-shell
6. 应用篇重编号 + 32 章值转换器节 + TaskFlow 实战（35）
7. README 重写 + 全量验证汇总

## 明确不做

- 系统托盘图标（1.8 元数据无此类型，README 已声明）
- 追平 Lazarus 40 章的全控件覆盖（CalendarView/FlipView/Rating/ColorPicker/ToolTip 等按族合并，不单独成章）
- C# / CsWinRT 视角（教程定位 C++/WinRT）
