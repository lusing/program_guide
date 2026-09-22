# WinUI 3 教程 10→35 章大扩充 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 WinUI 3 教程从 10 章/5 例扩充到 35 章/10 例：19 个专门控件章 + 进阶篇 + TaskFlow 实战，每画廊页过 ui-smoke 点击验证。

**Architecture:** 保留概念/工程篇，插入三段控件篇（基础/集合/导航浮层，各自一个 NavigationView 画廊工程，每章一个 Page）、进阶篇（画廊 + 窗口工程）、应用篇（原章重编号 + 新值转换器节 + TaskFlow 收尾）。全部章节整体重新编号。

**Tech Stack:** C++/WinRT 2.0.250303.1、Windows App SDK 1.8.260317003、MSVC (stdcpp20)、CommunityToolkit.WinUI.UI.Controls.DataGrid 7.1.2（仅 20 章）、MSBuild 命令行构建、PowerShell 冒烟。

**Spec:** `docs/superpowers/specs/2026-09-22-winui3-tutorial-expansion-design.md`

## Global Constraints

- 源文件 **UTF-8 无 BOM**，vcxproj 已带 `/utf-8`（中文 SKU 下无 C4819）；**PowerShell 脚本一律纯 ASCII**（沿用 build.ps1 / ui-smoke.ps1 风格）
- 所有工程 `WindowsPackageType=None`（非打包，命令行可跑）、`WindowsAppSDKSelfContained=true`、WASDK 1.8.260317003 + CppWinRT 2.0.250303.1
- 每个工程 ProjectGuid 唯一（`[guid]::NewGuid()` 或手改末段十六进制）
- **MIDL 不跨 .idl 解析 runtimeclass 引用**（MIDL2011）：互相引用的 runtimeclass 合并进同一 `.idl`
- **pch.h 必须包含所有 x:Class 实现头**（XamlTypeInfo.g.cpp 静态断言要求）
- 事件处理器按名字挂接（`Click="OnX"`）不需要进 IDL；只有 `x:Bind` 路径上的成员需要
- ContentDialog 必须设 `XamlRoot`，且只能从内容树根元素取（Window 无 XamlRoot 成员）
- 后台线程回 UI 用 `Microsoft.UI.Dispatching.DispatcherQueue::TryEnqueue`（**禁用 `resume_foreground`**，README 已实测它永不恢复）
- 每章文档为中文、约 250–330 行、机制先行（控件解决什么问题→核心属性机制→画廊页对照代码→实测坑位→与相邻控件取舍）
- 三条验证通道：winmd-probe（元数据）/ build.ps1（编译）/ ui-smoke（运行时截图）。不实的写法回写正文，不可运行时验证的写"诚实边界"
- 每个任务收尾：`./build.ps1 -Examples <dir>` PASS + 对应 smoke 截图判读通过 + git commit（中文 message + Co-Authored-By: Claude Code <noreply@anthropic.com>）

## 内容任务通用模板（Task 4 起所有章节任务遵循）

每个章节任务 = 文档章 + 画廊页 + 验证 + 提交，五步节奏：

1. **写画廊页**（四件套 + 三处登记）：
   - `examples/<NN-gallery>/` 下新增 `XxxPage.idl` / `XxxPage.xaml` / `XxxPage.xaml.h` / `XxxPage.xaml.cpp`（模式见 Task 2 的 ButtonPage 完整代码，改类名即可）
   - vcxproj 四处登记：`ClInclude` / `ClCompile` / `Midl` / `Page`
   - pch.h 的 XamlTypeInfo 注释块下加 `#include "XxxPage.xaml.h"`
   - MainWindow.xaml 的 `NavigationView.MenuItems` 加 `<NavigationViewItem Content="Xxx" Tag="xxx"/>`；MainWindow.xaml.cpp 的 `NavigateTo` 加分支 `ContentFrame().Navigate(xaml_typename<BasicGallery::XxxPage>())`
   - 页面骨架：根 Grid `Margin="24"`，顶部 `<TextBlock x:Name="StatusText" Text="Ready" FontSize="18"/>`，下面 StackPanel Spacing="12" 放演示控件；所有反馈都写进 StatusText（smoke 判读锚点）
2. **smoke 场景**：`tools/ui-smoke/gallery-smoke.ps1` 对应画廊的场景表加一页（nav 偏移 + 页内交互点），跑一次读截图调偏移
3. **写文档** `docs/NN-slug.md`（按任务给的覆盖清单，不遗漏坑位）
4. **验证**：`./build.ps1 -Examples <dir>` PASS；`pwsh tools/ui-smoke/gallery-smoke.ps1 -Gallery <NN> -Page <tag>`；判读 PNG；probe 疑点跑 `tools/winmd-probe`（见各任务清单）
5. **提交**：`git add` 相关文件，message 形如 `docs(winui3): 第 N 章 <控件>——画廊页 + smoke + 文档`

---

### Task 1: 目录重编号与交叉引用修复

**Files:**
- Delete: `WinUI3/docs/06-controls.md`（内容已吸收进将写的 7–25 章；git 历史可 `git show` 找回）
- Rename: `WinUI3/docs/07-layout.md` → `06-layout.md`；`08-binding-mvvm.md` → `32-binding-mvvm.md`；`09-theming-packaging.md` → `33-theming-packaging.md`；`10-os-integration.md` → `34-os-integration.md`
- Rename: `WinUI3/examples/07-layout` → `06-layout`；`examples/08-binding-mvvm` → `32-binding-mvvm`；`examples/10-os-integration` → `34-os-integration`
- Delete: `WinUI3/examples/06-controls`（被画廊吸收；.smoke 旧证据目录一并删）
- Modify: 保留的 docs/01–05、README.md 里全部交叉引用

**Interfaces:**
- Produces: 新编号体系（06=布局、32=绑定、33=主题、34=OS），后续所有任务按此编号建章

- [ ] **Step 1: git mv 文档与示例目录**（删除的用 git rm），一次性完成上面 Files 列表
- [ ] **Step 2: 改文档内部章号**：06-layout.md 标题 `# 7. …`→`# 6. …`、小节 `## 7.1`→`## 6.1`（余类推）；32 章全部 `8.x`→`32.x`；33 章 `9.x`→`33.x`；34 章 `10.x`→`34.x`
- [ ] **Step 3: 修交叉引用**（在 WinUI3/ 下 grep 找全）：
  - `docs/07-layout` → `docs/06-layout`；`docs/08-binding-mvvm` → `docs/32-binding-mvvm`；`docs/09-…` → `docs/33-…`；`docs/10-…` → `docs/34-…`
  - 锚点同步改：`#871-` → `#321-`、`#101-` → `#341-` 等（GitHub 锚点跟标题走）
  - 旧 06-controls 引用按内容映射到未来章节：`6.1 Button`→`docs/07-button.md`、`6.2 TextBox`→`docs/09-textbox.md`、`6.3 CheckBox`→`docs/10-checkbox-radio.md`、`6.4 ComboBox`→`docs/14-combobox.md`、`6.5 ListView`→`docs/17-listview.md`、`6.6 Toggle/Slider`→`docs/11-toggleswitch.md` 与 `docs/12-slider-progress.md`、`6.7 ContentDialog`→`docs/24-dialogs-flyouts.md`（这些链接在对应章节写成前是死链，各章节任务落地时自动变活，README 终稿统一校验）
- [ ] **Step 4: README 临时最小更新**：目录表数字与文件名对上（完整重写留给 Task 36）；`06-controls` 示例行删除
- [ ] **Step 5: 验证**：`./build.ps1` 全绿（目录改名后 build.ps1 自动发现）；`grep -rn "06-controls\|07-layout\|08-binding\|09-theming\|10-os-integration" docs README.md` 无残留
- [ ] **Step 6: Commit** `docs(winui3): 目录重编号——布局 06/绑定 32/主题 33/OS 34，06-controls 吸收进画廊`

---

### Task 2: 07-controls-basic 画廊骨架（NavigationView 外壳 + HomePage）

**Files:**
- Create: `WinUI3/examples/07-controls-basic/` 整套：`BasicGallery.vcxproj`（复制 06-layout 的 LayoutApp.vcxproj，改 ProjectGuid 末段、RootNamespace=BasicGallery）、`App.idl/App.xaml/App.xaml.h/App.xaml.cpp/main.cpp/pch.h/pch.cpp`（照抄 06-controls 模式，命名空间改 BasicGallery）、`MainWindow.idl/MainWindow.xaml/MainWindow.xaml.h/MainWindow.xaml.cpp`（下方完整代码）、`HomePage.idl/HomePage.xaml/HomePage.xaml.h/HomePage.xaml.cpp`（ButtonPage 模式改名为 HomePage，内容一个 TextBlock "Basic Controls Gallery"）

**Interfaces:**
- Produces: 画廊页面四件套模板（后续 24 个页面任务照抄）；`NavigateTo(hstring tag)` 分发表模式；smoke 判读锚点 `StatusText`

- [ ] **Step 1: 建 vcxproj 与 App/main/pch**（照抄现有工程，RootNamespace=BasicGallery，新 GUID；pch.h 先只含 `App.xaml.h` + `MainWindow.xaml.h` + `HomePage.xaml.h`）
- [ ] **Step 2: MainWindow.xaml**——NavigationView 外壳：

```xml
<Window
    x:Class="BasicGallery.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <NavigationView x:Name="Nav" IsBackButtonVisible="Auto"
                    SelectionChanged="OnNavSelectionChanged">
        <NavigationView.MenuItems>
            <NavigationViewItem Content="Home" Tag="home"/>
            <NavigationViewItem Content="Button" Tag="button"/>
            <!-- 后续每章任务在此追加一项 -->
        </NavigationView.MenuItems>
        <Frame x:Name="ContentFrame"/>
    </NavigationView>
</Window>
```

- [ ] **Step 3: MainWindow.xaml.h/.cpp**——分发表（.idl 最小化：只 `runtimeclass MainWindow : Microsoft.UI.Xaml.Window { MainWindow(); }`，事件按名字挂接不进 IDL）：

```cpp
// MainWindow.xaml.cpp 关键实现
MainWindow::MainWindow()
{
    InitializeComponent();
    Title(L"BasicGallery");
    ContentFrame().Navigate(xaml_typename<BasicGallery::HomePage>());
}

void MainWindow::OnNavSelectionChanged(NavigationView const&,
    NavigationViewSelectionChangedEventArgs const& args)
{
    if (auto item = args.SelectedItem().try_as<NavigationViewItem>())
    {
        NavigateTo(winrt::unbox_value<winrt::hstring>(item.Tag()));
    }
}

void MainWindow::NavigateTo(winrt::hstring const& tag)
{
    if (tag == L"home") ContentFrame().Navigate(xaml_typename<BasicGallery::HomePage>());
    // 每章任务追加: if (tag == L"button") ...ButtonPage
}
```

（`NavigateTo` 声明进 .xaml.h 私有段；unbox 失败风险：Tag 都是字符串字面量，安全。）

- [ ] **Step 4: HomePage 四件套**——页面模板（后续所有页照此改名）：

`HomePage.idl`:
```idl
namespace BasicGallery
{
    [default_interface]
    runtimeclass HomePage : Microsoft.UI.Xaml.Controls.Page
    {
        HomePage();
    }
}
```
`HomePage.xaml`: 根 `<Page x:Class="BasicGallery.HomePage" …>` 内 Grid Margin="24" + TextBlock；
`HomePage.xaml.h`: `struct HomePage : HomePageT<HomePage> { HomePage(); };` + factory_implementation；
`HomePage.xaml.cpp`: ctor `InitializeComponent();`

- [ ] **Step 5: vcxproj 登记 HomePage**（ClInclude/ClCompile/Midl/Page 四处）与 pch.h 加头
- [ ] **Step 6: 验证**：`./build.ps1 -Examples 07-controls-basic` PASS
- [ ] **Step 7: 手动冒烟**：直接启动 exe，点 Button 导航项确认 Frame 切页（为 Task 3 定 nav 偏移），关掉
- [ ] **Step 8: Commit** `feat(winui3): 07-controls-basic 画廊骨架——NavigationView 外壳 + Frame 分发表`

---

### Task 3: ui-smoke 序列点击扩展 + gallery-smoke 驱动器

**Files:**
- Modify: `WinUI3/tools/ui-smoke/ui-smoke.ps1`（加 `-Clicks` 与 `-TypeText` 参数，保留旧参数路径不动）
- Create: `WinUI3/tools/ui-smoke/gallery-smoke.ps1`（驱动器 + 场景表）

**Interfaces:**
- Produces: `ui-smoke.ps1 -Exe <exe> -OutDir <dir> -Clicks "x,y;x,y" [-TypeText "ab"]`——坐标相对 XAML island 客户区**左上角**，每次点击后存 `click-N.png`（打字在首击聚焦后、末击之前进行）；`gallery-smoke.ps1 -Gallery 07 [-Page button]`——逐页调 ui-smoke，输出 `.smoke/07-controls-basic/<tag>/`

- [ ] **Step 1: ui-smoke.ps1 加参数**：`[string]$Clicks`（分号分隔点列）、`[string]$TypeText`。实现：Get-LargestChild 拿 island 原点后，逐点 `SetCursorPos(origin.X+x, origin.Y+y)` → mouse_event 按下/抬起 → Sleep 700ms → `Save-WindowShot … click-N.png`；若 `-TypeText` 且点数 ≥2，在第 1 次点击后用 `[Win32.Native]::VkKeyScanW`（需在 Add-Type MemberDefinition 里补 P/Invoke 声明 `[DllImport("user32.dll")] public static extern ushort VkKeyScanW(char ch);`）逐字符 keybd_event（处理高字节 shift 位）。旧 `-ClickOffset/-ClickAtScreen` 路径原样保留
- [ ] **Step 2: gallery-smoke.ps1**（纯 ASCII）：

```powershell
param(
    [Parameter(Mandatory=$true)][ValidateSet('07','17','21','26','31','35','01','06','32','34')][string]$Gallery,
    [string]$Page   # optional: run a single scenario
)
# $galleries maps gallery id -> @{ Exe = <path under examples>; Scenarios = @{ tag = @{ Nav='x,y'; Act='x,y'; Type='ab' (optional) } } }
# For each scenario: invoke ui-smoke.ps1 with -Clicks "$Nav" or "$Nav;$Act" (+ -TypeText), OutDir ..\..\.smoke\<galleryDir>\<tag>
```

  初始只装 07 画廊 `home` 场景（Nav='48,140' 之类，靠 Step 3 实测调）
- [ ] **Step 3: 实测调偏移**：跑 `-Gallery 07 -Page home`，读 `.smoke` 截图确认 Nav 落点真点中导航项（点完应仍显示 HomePage）；记下每个导航项的稳定 y 偏移规律（NavigationView 行高固定，相邻项差恒定，后续页可推算再微调）
- [ ] **Step 4: 验证**：连跑两遍结果一致（点击确定性）
- [ ] **Step 5: Commit** `feat(winui3): ui-smoke 序列点击/打字扩展 + gallery-smoke 驱动器`

---

### Task 4: 第 7 章 Button 与按钮族

**Files:**
- Create: `examples/07-controls-basic/ButtonPage.{idl,xaml,xaml.h,xaml.cpp}`、`docs/07-button.md`
- Modify: MainWindow 分发表 + vcxproj + pch.h、gallery-smoke 场景表

**页面与 smoke**：Button 计数（Click → StatusText "clicked N"）；RepeatButton（按住连发，Delay/Interval 标注）；HyperlinkButton NavigateUri="https://learn.microsoft.com/"（浏览器打开——运行时验证边界，smoke 只截图不点它）；DropDownButton + MenuFlyout 三项；smoke：Nav → 点主 Button → click-2.png 显示 "clicked 1"

**文档必须覆盖**：ButtonBase 继承树（Button/RepeatButton/HyperlinkButton/DropDownButton/ToggleButton 指向 11 章）；Click 事件签名与按名字挂接不进 IDL（README 结论重申）；Command vs Click（指向 32 章）；IsEnabled 禁用语义与 AutomationProperties；RepeatButton 的 Delay/Interval 默认值（**probe**）；HyperlinkButton.NavigateUri 机制（ShellExecute 打开浏览器，应用内导航要用 Frame.Navigate 对比）；DropDownButton 的 Flyout 自动管理 vs Button.Flyout；CornerRadius/Padding 造型。
**probe 清单**：`RepeatButton.Delay/Interval`、`DropDownButton` 在 1.8 元数据存在性、`HyperlinkButton.NavigateUri` 类型（Windows.Foundation.Uri）。

- [ ] Step 1–5: 按通用模板五步执行（页面 → smoke → 文档 → 验证 → 提交 `docs(winui3): 第 7 章 Button 与按钮族`）

---

### Task 5: 第 8 章 TextBlock 与文本呈现

**Files:** `examples/07-controls-basic/TextBlockPage.*`、`docs/08-textblock.md`、三处登记、场景表

**页面与 smoke**：多 Run 富文本（粗体/彩色内联）；TextTrimming 三态切换 Button（None/CharacterEllipsis/WordEllipsis → StatusText 同步显示当前模式）；TextWrapping 对比两行；smoke：Nav → 点切换 Button → click-2.png 状态行变 "trim = CharacterEllipsis"

**文档必须覆盖**：Inline/Run 集合模型（hstring 拼接 vs 多 Run 的取舍）；TextWrapping WrapWholeWords 语义；TextTrimming 枚举；字体四件套 FontFamily/FontSize/FontStyle/FontWeight 与主题资源默认值；IsTextSelectionEnabled（TextBlock 也能选文本）；x:Bind OneTime 默认导致文本不刷新的坑（链 32 章）；长文本无滚动是容器职责（链 06 章）。

- [ ] 按通用模板五步执行

---

### Task 6: 第 9 章 TextBox 与文本输入族

**Files:** `examples/07-controls-basic/TextBoxPage.*`、`docs/09-textbox.md`、登记、场景表

**页面与 smoke**：TextBox（Header/PlaceholderText/MaxLength=20，TextChanged → StatusText 实时字数）；PasswordBox（PasswordChanged → "password length = N"）；RichEditBox + "Bold" 按钮（ITextRange.CharacterFormat().Bold）+ "Read text" 按钮（GetText 回读 → StatusText）；smoke：Nav → 点 "Read text" → click-2.png 显示富文本内容（先在 XAML 里给 RichEditBox 初值文本，保证确定性）

**文档必须覆盖**：TextChanged 无旧值/新值参数（要自己记——机制：文本已在控件里改完）；TwoWay x:Bind 的 UpdateSourceTrigger 时机（**运行时实测**：LostFocus 还是每键——用 32 章工程式小实验写进正文）；Header vs PlaceholderText 职责差异；InputScope/IsTextPredictionEnabled；**PasswordBox.Password 不是依赖属性 → 不可 x:Bind**（安全设计机制，只能 PasswordChanged 事件读）；PasswordRevealMode；RichEditBox 的内容在 Document()（ITextDocument/ITextRange），不是 string 属性；与 26 章样式联动预告。
**probe 清单**：`RichEditBox.Document` 返回类型与 `ITextDocument.GetText` 签名（out 参数在 C++/WinRT 的形状）、`TextBox.AcceptsReturn`。

- [ ] 按通用模板五步执行

---

### Task 7: 第 10 章 CheckBox 与 RadioButton

**Files:** `examples/07-controls-basic/CheckBoxPage.*`、`docs/10-checkbox-radio.md`、登记、场景表（迁原 6.3 内容并扩充）

**页面与 smoke**：CheckBox（IsChecked 三态：Checked/Unchecked/Indeterminate 各更新 StatusText，含 `.Value()` 解包）；IsThreeState 开关；RadioButton GroupName 两组互斥；smoke：Nav → 点 CheckBox → click-2.png "indeterminate"（设 IsThreeState=True 时点击循环三态，确定性）

**文档必须覆盖**：`IsChecked()` 返回 `IReference<bool>` 三态的机制（README 核心坑，正式展开：为什么不是 bool——三态是真实业务状态）；`.Value()` 解包与空值风险；Checked/Unchecked/Indeterminate 三事件 vs 只挂前两个的坑；RadioButton GroupName 机制（同容器同名互斥；不同容器同名也互斥——跨容器行为写清）；CheckBox 与 ToggleSwitch（11 章）的 UI 规范取舍。

- [ ] 按通用模板五步执行

---

### Task 8: 第 11 章 ToggleSwitch 与 ToggleButton

**Files:** `examples/07-controls-basic/TogglePage.*`、`docs/11-toggleswitch.md`、登记、场景表

**页面与 smoke**：ToggleSwitch（IsOn 普通 bool、Toggled、OnContent/OffContent 定制文案）；ToggleButton（工具栏场景：三个 ToggleButton 当格式开关，IsChecked 三态同 CheckBox 基类机制）；smoke：Nav → 点 ToggleSwitch → click-2.png "autosave on/off" 翻转

**文档必须覆盖**：IsOn 是普通 bool（与 CheckBox 三态的对照表）；Toggled 事件时机（初始化设 IsOn 也触发——ctor 里接线的坑）；OnContent/OffContent/Header；ToggleButton 继承自 CheckBox 的语义（IsChecked 同为 IReference<bool>）；「设置项用 ToggleSwitch、工具栏状态用 ToggleButton、表单多选用 CheckBox」规范；CommandBar 里 AppBarToggleButton（链 23 章）。

- [ ] 按通用模板五步执行

---

### Task 9: 第 12 章 Slider、ProgressBar、ProgressRing 与 Rating

**Files:** `examples/07-controls-basic/SliderPage.*`、`docs/12-slider-progress.md`、登记、场景表

**页面与 smoke**：Slider（0–100）ValueChanged → StatusText + 同步驱动下方 ProgressBar().Value()（确定进度联动演示）；ProgressRing IsIndeterminate 由按钮开关；Rating ValueChanged → StatusText "rating = N"；smoke：Nav → 点 Slider 轨道中段（track 点击直接跳值）→ click-2.png "volume = 50" 一带 ProgressBar 半满

**文档必须覆盖**：RangeBase 机制（Minimum/Maximum/Value/StepFrequency/SnapsTo/TickFrequency/TickPlacement，继承者 Slider/ProgressBar）；ValueChanged 的 RangeBaseValueChangedEventArgs（NewValue/OldValue）；ProgressBar 确定值 vs IsIndeterminate 不确定模式；**ProgressRing 在 1.8 是否支持确定值（probe！WinUI 2.8 加了 determinate，WinUI 3 何时跟进按元数据写）**；Rating 的 Value/Caption/IsReadOnly/PlaceholderValue；Thumb 交互与键盘；进度联动 = 无绑定的属性直写演示 + x:Bind 函数绑定替代方案预告（链 32 章）。
**probe 清单**：`ProgressRing` 是否有 Value/Minimum/Maximum、`Rating.Caption` 类型、`Slider.ThumbToolTipValueConverter`。

- [ ] 按通用模板五步执行

---

### Task 10: 第 13 章 NumberBox

**Files:** `examples/07-controls-basic/NumberBoxPage.*`、`docs/13-numberbox.md`、登记、场景表

**页面与 smoke**：NumberBox（Value/ValueChanged → StatusText）；SpinButtonPlacementMode Compact/Inline；AcceptsExpression=True（"2+3*4" 回车得 14，文档讲、smoke 用 spin 按钮）；smoke：Nav → 点 spin-up 增按钮 → click-2.png "value = 1"（Value 初值 0）

**文档必须覆盖**：Value 是 double 且空输入 = NaN（判断 `std::isnan`）；ValidationMode（InvalidInputOverwritten/KeepInvalid，**probe 确认枚举名与默认值**）；SmallChange/LargeChange 与滚动轮；PlaceholderText/Header；TextBox 做数值输入的痛点（NumberBox 存在的理由：解析/步进/表达式）；与 Slider 的取舍（精确输入 vs 快速调值）。
**probe 清单**：`NumberBoxValidationMode` 枚举成员、`NumberBox.AcceptsExpression`、`SpinButtonPlacementMode`。

- [ ] 按通用模板五步执行

---

### Task 11: 第 14 章 ComboBox

**Files:** `examples/07-controls-basic/ComboBoxPage.*`、`docs/14-combobox.md`、登记、场景表（迁原 6.4 并扩充）

**页面与 smoke**：ComboBox 静态 Items（x:String 三项，SelectionChanged → unbox → StatusText，**SelectedItem 是 IInspectable 必须 unbox_value**——README 核心坑保留）；SelectedIndex 程序化设置演示；IsEditable ComboBox（可输入过滤，**probe 确认 1.8 有此属性**）；ItemsSource = single_threaded_vector<hstring> 装箱；smoke：Nav → 点 ComboBox 展开（click-2.png 显示下拉）→ 点列表第二项（click-3.png "theme = Dark"）

**文档必须覆盖**：Items 三种喂法（XAML 子元素/ItemsSource/ItemsSource+ItemTemplate）；SelectedItem 装箱机制与 unbox；SelectedIndex 与初始化时序坑（**InitializeComponent 期间设初始选中会触发 SelectionChanged，此时 handler 字段未就绪——实测写法：ctor 里先接线再设，或 handler 判控件空**）；IsEditable/PlaceholderText/MaxDropDownHeight；ComboBox vs AutoSuggestBox（15 章）vs MenuFlyout（23 章）取舍；ItemsSource 替换后选中丢失（链 17 章 ListView 同坑）。
**probe 清单**：`ComboBox.IsEditable`、`ComboBox.PlaceholderText`、`SelectionChangedEventArgs.AddedItems` 形状。

- [ ] 按通用模板五步执行

---

### Task 12: 第 15 章 AutoSuggestBox

**Files:** `examples/07-controls-basic/AutoSuggestPage.*`、`docs/15-autosuggestbox.md`、登记、场景表

**页面与 smoke**：AutoSuggestBox + 静态词表（水果名 6 个）：TextChanged(Reason==UserInput) → 前缀过滤 → ItemsSource 更新；SuggestionChosen → StatusText "chosen = apple"；QuerySubmitted；smoke：Nav → 点输入框 → TypeText "ap" → click-3.png 显示建议列表；再点建议项 → click-4.png "chosen = apple"（依赖 Task 3 的 -TypeText）

**文档必须覆盖**：AutoSuggestBoxTextChangedEventArgs.Reason（UserInput/Programmatic——**改 ItemsSource 引发的 Text 变化不算用户输入**，防重入）；SuggestionChosen vs QuerySubmitted 语义（选词 vs 回车/按钮提交）；建议列表 = ItemsSource（IObservableVector 或整体替换）；与 ComboBox 的取舍（已知选项 vs 自由输入/搜索）；最小可搜索列表完整模式（本章给出 30 行内完整代码）。

- [ ] 按通用模板五步执行

---

### Task 13: 第 16 章 日期与时间族

**Files:** `examples/07-controls-basic/DateTimePage.*`、`docs/16-datetime.md`、登记、场景表

**页面与 smoke**：DatePicker（DateChanged → StatusText "2026-09-22"）；TimePicker；CalendarDatePicker（下拉日历）；CalendarView（SelectionMode=Multiple，SelectedDatesChanged）；"Set to today" 按钮程序化设值（保证 smoke 确定性）；smoke：Nav → 点 "Set to today" → click-2.png 状态行显示今天日期、DatePicker 显示同步

**文档必须覆盖**：`Date` 是 `IReference<Windows::Foundation::DateTime>`（可空——未选 = nullptr，读前判空的坑）；`Time` 是 TimeSpan（Tick 机制与 `std::chrono` 互转）；DatePicker 的日/月/年 spinner 交互与 YearVisible/MinYear/MaxYear；**DatePicker.Date 与 SelectedDate 的关系（probe：WASDK 新增了 SelectedDate IReference + SelectedDateChanged？按元数据写）**；CalendarDatePicker 与 DatePicker 取舍（日历可视 vs spinner）；CalendarView 的 SelectedDates 集合/BlackoutDates？（probe 存在性）；时区/本地化一句带过（clock_t 系统）。
**probe 清单**：`DatePicker.SelectedDate`/`SelectedDateChanged` 存在性、`CalendarView.SelectionMode`/`BlackoutDates`、`CalendarDatePicker.IsTodayHighlighted`。

- [ ] 按通用模板五步执行

---

### Task 14: 基础篇阶段收尾

- [ ] **Step 1**: `./build.ps1` 全量全绿（01/06/07/32/34 五工程）
- [ ] **Step 2**: `pwsh tools/ui-smoke/gallery-smoke.ps1 -Gallery 07` 全 10 页跑通，逐页判读截图（StatusText 变化全部确认）
- [ ] **Step 3**: 对照新截图与文档陈述，发现不符回写正文（"验证推翻"条目记入 README 草稿区）
- [ ] **Step 4**: Commit `docs(winui3): 控件·基础篇 10 章收尾——画廊全页 smoke 通过`

---

### Task 15: 17-controls-collections 画廊骨架（含 DataGrid 包前置验证）

**Files:**
- Create: `examples/17-controls-collections/` 整套（CollectionsGallery，照 Task 2 模式：NavigationView 外壳 + ListViewPage/GridViewPage/TreeViewPage/DataGridPage 四个占位 HomePage 式页面 + 四个导航项）
- Modify: gallery-smoke.ps1 加 17 画廊注册

**关键差异**：vcxproj 的 PackageReference 加 `<PackageReference Include="CommunityToolkit.WinUI.UI.Controls.DataGrid" Version="7.1.2" />`（**提前到骨架就引入，编译+启动立即验证与 WASDK 1.8/CppWinRT 2.0.250303.1 的兼容性——这是本计划最大的外部风险，早失败早调整**）。

- [ ] Step 1: 建工程（照 Task 2 五步，导航项 listview/gridview/treeview/datagrid）
- [ ] Step 2: `./build.ps1 -Examples 17-controls-collections` PASS（restore 7.1.2 成功 = 兼容性第一道关）
- [ ] Step 3: 启动 exe 冒烟（能起窗 = 第二道关；若 7.1.2 与 1.8 冲突：20 章降级为"元数据级证据 + 诚实边界"方案并在该任务记录）
- [ ] Step 4: gallery-smoke 场景表加 17 画廊 home 场景并调偏移
- [ ] Step 5: Commit `feat(winui3): 17-controls-collections 画廊骨架 + DataGrid 包兼容性前置验证`

---

### Task 16: 第 17 章 ListView

**Files:** `examples/17-controls-collections/ListViewPage.*`（占位页换成真内容）、`docs/17-listview.md`、场景表

**页面与 smoke**：ListView ItemsSource = `single_threaded_vector<IInspectable>`（装箱 hstring 若干）；DataTemplate `<TextBlock Text="{Binding}"/>`；SelectionMode 用三个 RadioButton 现场切换（Single/Multiple/None）；SelectionChanged → StatusText（Multiple 模式下 AddedItems/RemovedItems 解包演示）；IsItemClickEnabled + ItemClick → StatusText；smoke：Nav → 点第二项 → click-2.png "selected = banana"

**文档必须覆盖**：SelectionMode 四值语义；SelectionChangedEventArgs.AddedItems/RemovedItems（IVector<IInspectable>，解包模式）；ItemClick 与 SelectionChanged 互斥语义（IsItemClickEnabled=true 时点按走 ItemClick）；ItemTemplate/DataTemplate 与 {Binding}（运行期绑定，对照 x:Bind 编译期——链 32）；ItemsSource 必须是 WinRT 集合（README 核心坑正式展开：std::vector 不通知）；**替换整个 ItemsSource 对象后选中/滚动状态丢失**；虚拟化机制（ItemsStackPanel 默认开、容器回收 → container 内状态是临时态的坑）；空态占位；与 GridView（18 章）共享 ItemsControl 基础。
**probe 清单**：`ListView.SelectionMode` 枚举、`ItemClickEventArgs` 形状。

- [ ] 按通用模板五步执行（本章起"占位页换真内容"= 改四件套 + 文档 + smoke）

---

### Task 17: 第 18 章 GridView 与 FlipView

**Files:** `examples/17-controls-collections/GridViewPage.*`、`docs/18-gridview-flipview.md`、场景表

**页面与 smoke**：GridView 同一份数据平铺（ItemTemplate 卡片式：Border+TextBlock）；ItemsPanel 说明（默认 ItemsWrapGrid）；FlipView 三页（编号色块）；"Next" 按钮程序化 SelectedIndex+1 → SelectionChanged → StatusText "page = 2"；smoke：Nav → 点 Next → click-2.png FlipView 翻到第二页 + 状态行

**文档必须覆盖**：GridView = ListView 换默认 ItemsPanel（ItemsWrapGrid vs ItemsStackPanel）——选择器基类 Selector 共有语义；ItemsPanel 替换的机制；卡片区滚动方向；FlipView 单项展示模型（相册/引导页场景）；FlipView.SelectionChanged/SelectedIndex；FlipView 与 ContentDialog 向导模式（24 章）取舍。

- [ ] 按通用模板五步执行

---

### Task 18: 第 19 章 TreeView

**Files:** `examples/17-controls-collections/TreeViewPage.*`、`docs/19-treeview.md`、场景表

**页面与 smoke**：TreeView 程序化建树（TreeViewNode：根 3 个、各 2 子）；ItemInvoked → StatusText 节点名；"Expand all" 按钮（遍历 IsExpanded(true)）；SelectionMode Single；smoke：Nav → 点 "Expand all" → click-2.png 树全展开 → 点一个子节点 → click-3.png "invoked = …"

**文档必须覆盖**：TreeViewNode 模型（Content/Children/HasChildren/IsExpanded/Depth）；RootNodes 集合；ItemInvoked vs ExpansionChanged（**probe 确认 1.8 事件名：ExpansionStateChanged?**）；程序化展开/收起；**ItemsSource + HierarchicalDataTemplate 在 WinUI 3 C++/WinRT 的可用性（probe：TreeView.ItemsSource 存在性 + HierarchicalDataTemplate 类型）——按元数据结论写，若仅 TreeViewNode 模式可用则明说并给绑定替代（自建同步）**；懒加载模式（HasChildren + Expanding 事件）；与 ListView 嵌套缩进的取舍。
**probe 清单**：`TreeView.ItemsSource`、`HierarchicalDataTemplate`、`TreeViewNode` 全属性、`TreeView.ItemInvoked` args 类型。

- [ ] 按通用模板五步执行

---

### Task 19: 第 20 章 DataGrid 与 ItemsRepeater

**Files:** `examples/17-controls-collections/DataGridPage.*`、`docs/20-datagrid-itemsrepeater.md`、场景表

**页面与 smoke**：`TaskRow` runtimeclass（Title/Priority/Done 三属性，INPC 不必需但给上——与 32 章模式一致）与 Page 放**同一个 .idl**（MIDL2011 规避）；DataGrid：AutoGenerateColumns=False + DataGridTextColumn(Binding={Binding Title})×2 + DataGridCheckBoxColumn({Binding Done})、CanUserSortColumns、SelectionChanged → StatusText；ItemsRepeater：UniformGridLayout 平铺 + StackLayout 纵排切换按钮；**App.xaml 合并 toolkit 资源字典（`ms-appx:///CommunityToolkit.WinUI.UI.Controls.DataGrid/Themes/Generic.xaml`——若编译/运行报资源缺失，试验正确写法并记录）**；smoke：Nav → 点 DataGrid 第二行 → click-2.png 选中高亮 + 状态行

**文档必须覆盖**：为什么需要 DataGrid（表格=列头排序/列宽/编辑，ListView 做不了的）；Toolkit DataGrid 的引入全流程（NuGet→资源字典→xmlns→列）——**把实测遇到的坑全部写进正文**；DataGridTextColumn/DataGridCheckBoxColumn/DataGridTemplateColumn；AutoGenerateColumns 与手写列；排序事件 Sorting；SelectionChanged/SelectedIndex；虚拟化与大数据量；ItemsRepeater 的定位（**无内建选择/无内建交互的"裸重复器"**——与 ListView 的本质差异：性能/自由度 vs 功能）；Layout（StackLayout/UniformGridLayout/FlowLayout）；ItemTemplate；选择要自己做的最小模式。
**probe 清单**：toolkit winmd 里 `DataGrid` 类型/`DataGridTextColumn.Binding` 形状、`ItemsRepeater.Layout`、`UniformGridLayout` 属性。

- [ ] 按通用模板五步执行

---

### Task 20: 集合篇收尾

- [ ] `./build.ps1 -Examples 17-controls-collections` PASS + `-Gallery 17` 全 4 页 smoke 判读 + 回写正文 + Commit `docs(winui3): 控件·集合篇 4 章收尾`

---

### Task 21: 21-controls-shell 画廊骨架

**Files:** Create `examples/21-controls-shell/`（ShellGallery，照 Task 2 模式）：导航项 tabview/navigationview/commandbar/dialogs/overlays 五个占位页；gallery-smoke.ps1 注册 21

- [ ] 建工程 → build PASS → home 场景调偏移 → Commit `feat(winui3): 21-controls-shell 画廊骨架`

---

### Task 22: 第 21 章 TabView 与 Expander

**Files:** `examples/21-controls-shell/TabViewPage.*`、`docs/21-tabview-expander.md`、场景表

**页面与 smoke**：TabView 三静态页（TabViewItem Header/IconSource(SymbolIcon)）；SelectionChanged → StatusText；AddTabButtonClick 真加页；TabCloseRequested 真删（tabcount 状态行）；Expander（Header/Content + Expanding/Collapsed → StatusText）；smoke：Nav → 点第二个 tab → click-2.png "tab = 2" → 点 + 加页 → click-3.png "tab = 2 (3 tabs)"

**文档必须覆盖**：TabItems vs TabItemsSource；TabViewItem（Header/IconSource/IsClosable）；TabCloseRequested 语义（**关闭不自动发生，要在事件里移除**）；AddTabButtonClick + IsAddTabButtonVisible；SelectionChanged；文档型 UI 的 tab 模式 vs 路由导航（22 章 NavigationView）取舍；Expander 的 Expanding/Collapsed 事件 vs IsExpanded 直控；ExpandDirection。

- [ ] 按通用模板五步执行

---

### Task 23: 第 22 章 NavigationView 与 SplitView

**Files:** `examples/21-controls-shell/NavigationViewPage.*`（注意类名 NavPage 避免与控件类型撞名可读性更好——用 NavPage）、`docs/22-navigationview.md`、场景表

**页面与 smoke**：页面内嵌第二个 NavigationView（PaneDisplayMode=Left）；三个按钮现场切 Left/LeftCompact/Top（GoToState 无关，直接改属性）；内嵌 Frame 切两页；下方讲解区：SplitView 独立小 demo（DisplayMode Overlay/Inline 切换按钮 + IsPaneOpen）；smoke：Nav → 点 "Compact" 按钮 → click-2.png 内嵌NavigationView 变窄条

**文档必须覆盖**：NavigationView 结构解剖（Pane/Content/Frame 协作——**画廊外壳本身就是活教材，正文直接引用外壳代码**）；SelectionChanged vs ItemInvoked（含 SettingsItem 的 tag 判定）；PaneDisplayMode 五值与断点规范（左/顶切换的窗口宽度惯例）；BackButton（IsBackButtonVisible/BackRequested）；Header 区域；FooterMenuItems；MenuItemTransition?；Separator/Header 分组；**SplitView 是 NavigationView 的底座**（DisplayMode Overlay/CompactInline、OpenPaneLength、IsPaneOpen）；Frame.Navigate(xaml_typename<T>) 机制；NavigationCacheMode 页面缓存。

- [ ] 按通用模板五步执行

---

### Task 24: 第 23 章 CommandBar 与菜单

**Files:** `examples/21-controls-shell/CommandBarPage.*`、`docs/23-commandbar-menus.md`、场景表

**页面与 smoke**：CommandBar（PrimaryCommands：AppBarButton(SymbolIcon Save/Add)×3 + AppBarSeparator + AppBarToggleButton；SecondaryCommands：两项溢出）；点击 Add → StatusText "added"；MenuBar（File: Open/Exit、Edit: Cut/Copy，RadioMenuFlyoutItem 视图组）；右键区 Border + MenuFlyout（FlyoutBase.AttachedFlyout，RightTapped 事件里 ShowAt）；smoke：Nav → 点 Add 按钮 → click-2.png "added 1"

**文档必须覆盖**：PrimaryCommands vs SecondaryCommands（溢出机制 IsOpen/DefaultLabelPosition）；AppBarButton/ToggleButton/Separator 三件套；Icon 类型（SymbolIcon/FontIcon/BitmapIcon）；Command 绑定入口（链 32）；MenuBar 与 MenuFlyoutItem/ToggleMenuFlyoutItem/RadioMenuFlyoutItem/MenuFlyoutSeparator；上下文菜单标准模式（AttachedFlyout + RightTapped + ShowAt(position)）；KeyboardAccelerators 一句带过。

- [ ] 按通用模板五步执行

---

### Task 25: 第 24 章 ContentDialog 与 Flyout

**Files:** `examples/21-controls-shell/DialogsPage.*`、`docs/24-dialogs-flyouts.md`、场景表（迁原 6.7 并扩充）

**页面与 smoke**："Show dialog" 按钮（三键 Primary/Secondary/Close + DefaultButton=Primary，ShowAsync 协程 co_await → StatusText 显示哪个键）；Button.Flyout 内三 MenuFlyoutItem 的轻按钮；"Show flyout" 按钮程序化 Flyout().ShowAt(target)；smoke：Nav → 点 Show dialog → click-2.png 模态弹出 → 点 Primary → click-3.png "dialog: primary"

**文档必须覆盖**：**XamlRoot 必须显式设置且从内容树根取（README 核心坑正式展开：Window 无 XamlRoot 的原因——XamlRoot 属于 XAML 树）**；ShowAsync 是 IAsyncOperation<ContentDialogResult> 协程模式；Primary/Secondary/Close 三键语义（Close 无返回值语义）；DefaultButton 与回车绑定；**同时只允许一个 ContentDialog（第二个 ShowAsync 抛异常）+ Closing 事件取消模式**；Content/Title 任意 UIElement（自定义表单对话框完整示例——TaskFlow 35 章预告）；Button.Flyout 语法糖 vs FlyoutBase.AttachedFlyout+ShowAt；placement 枚举；light-dismiss 行为差异（Flyout 点击外部关闭 vs ContentDialog 模态）；TeachingTip（25 章）是第三种浮层预告。

- [ ] 按通用模板五步执行

---

### Task 26: 第 25 章 TeachingTip、InfoBar 与 ToolTip

**Files:** `examples/21-controls-shell/OverlaysPage.*`、`docs/25-overlays.md`、场景表

**页面与 smoke**：TeachingTip（Target 锚定按钮、Title/Subtitle/ActionButton、按钮触发 IsOpen(true)）；InfoBar（Severity 四态按钮循环 Info/Warning/Error/Success + Message + 关闭钮）；ToolTip（ToolTipService.ToolTip 附加在按钮上 + 内容为 StackPanel 富提示）；smoke：Nav → 点 "Show tip" → click-2.png TeachingTip 气泡 → 点 Severity 循环 → click-3.png InfoBar 变 Warning 色

**文档必须覆盖**：TeachingTip 定位（非模态教学气泡 vs ContentDialog 模态 vs InfoBar 常驻）：Target 锚定与 placement、IsOpen 时序（**页面加载即弹的坑**）、HeroContent、ActionButton/CloseButtonClick、ShouldConstrainToRootBounds；InfoBar：Severity/IsOpen/Title/Message/ActionButton/Closing、AreCloseButtonsEnabled?（probe）、常驻 vs 自动消失策略；ToolTipService.ToolTip 附加属性机制、InitialDelay/Placement（**probe 枚举名**）、内容可以是任意元素（富提示）；三种浮层的选择矩阵（结尾表格）。
**probe 清单**：`TeachingTip.ShouldConstrainToRootBounds`、`InfoBar.AreCloseButtonsEnabled`、`ToolTipService.Placement` 枚举。

- [ ] 按通用模板五步执行

---

### Task 27: 壳篇收尾

- [ ] `./build.ps1 -Examples 21-controls-shell` PASS + `-Gallery 21` 全 5 页 smoke 判读 + 回写 + Commit `docs(winui3): 控件·导航浮层篇 5 章收尾`

---

### Task 28: 26-customization 画廊骨架

**Files:** Create `examples/26-customization/`（CustomGallery）：导航项 styles/custom/vsm/animation/drawing 五占位页；gallery-smoke 注册 26

- [ ] 建工程 → build PASS → 调偏移 → Commit `feat(winui3): 26-customization 画廊骨架`

---

### Task 29: 第 26 章 样式与控件模板

**Files:** `examples/26-customization/StylesPage.*`、`docs/26-styles-templates.md`、场景表

**页面与 smoke**：隐式样式（Page.Resources 里无 key 的 `<Style TargetType="Button">`——页面所有按钮变蓝底圆角）；显式 keyed Style + BasedOn 继承演示（两个按钮对照）；ControlTemplate 重造 Button（Border+ContentPresenter+TemplateBinding，圆角渐变），按钮仍可点（Click → StatusText 证明模板没弄坏交互）；smoke：Nav → 点模板化按钮 → click-2.png "templated button clicked"

**文档必须覆盖**：Style 机制（Setter 集合；隐式=无 key 全类型生效 vs 显式={StaticResource key}）；BasedOn 继承链；**样式只能设在类型有的属性上**；资源查找顺序（Page→App→theme，链 33 章展开）；ControlTemplate 与 TemplateBinding（模板内引用模板宿主属性）；ContentPresenter（模板里内容占位）；默认模板从哪来（generic.xaml 主题字典——链 27 章）；改模板 vs 改样式的决策线（属性=样式，结构=模板）；VisualState 在模板内（预告 28 章）。

- [ ] 按通用模板五步执行

---

### Task 30: 第 27 章 自定义控件与 UserControl

**Files:** `examples/26-customization/CustomControlPage.*` + `LabeledValueControl`（templated control：`LabeledValueControl.idl/xaml.h/xaml.cpp` + `Themes/Generic.xaml`）、`docs/27-custom-controls.md`、场景表

**页面与 smoke**：UserControl 区：`TitleRow` UserControl（Label+Value 两 TextBlock 组合，x:Name 内部直连 + 对外事件）；templated control 区：`LabeledValueControl`（runtimeclass : Control，依赖属性 Label/Value（**probe 注册宏**），ctor `DefaultStyleKey(L"CustomGallery.LabeledValueControl")`，Generic.xaml 给默认模板 Border+两个 TextBlock + TemplateBinding）；页面上两种控件各摆两个；smoke：Nav → 点 "Bump" 按钮改 LabeledValueControl.Value() → click-2.png 值变化

**文档必须覆盖**：两条路线的决策线（**组合现成控件=UserControl；要可换模板/给第三方=templated Control**）；UserControl 的 x:Class+InitializeComponent 复用机制、对外暴露属性/事件模式；templated control 完整五件套（idl/头/实现/Generic.xaml/vcxproj 登记方式——**Generic.xaml 的 Build Action 实测正确写法写进正文**）；DefaultStyleKey 机制；依赖属性注册（`DependencyProperty::Register` + `_labelProperty` 静态，**按 1.8 元数据核对 API 形状**）；TemplatePart 约定（OnApplyTemplate + GetTemplateChild）；vs Win32 自绘控件的心智对照（MFC 教程读者）。
**probe 清单**：`DependencyProperty.Register` 签名、`Control.OnApplyTemplate`/`GetTemplateChild`、`DefaultStyleKey` 属性。

- [ ] 按通用模板五步执行

---

### Task 31: 第 28 章 VisualStateManager 与自适应

**Files:** `examples/26-customization/VsmPage.*`、`docs/28-vsm-adaptive.md`、场景表

**页面与 smoke**：两组 VisualState（Narrow/Wide）+ AdaptiveTrigger（MinWindowWidth=900/600）；状态里用 Setter 切 StackPanel.Orientation 与元素 Visibility；"Force narrow/wide" 按钮调 `VisualStateManager::GoToState`（确定性 smoke 路径）；smoke：Nav → 点 "Force narrow" → click-2.png 布局变纵向

**文档必须覆盖**：VisualStateGroups/VisualState/Setters 模型（与样式的关系：状态是"命名的属性批量覆盖"）；GoToState 手动切换 vs 触发器自动；AdaptiveTrigger MinWindowWidth/MinWindowHeight（**窗口宽度=触发器评估时机：resize 时重新评估**）；窗口宽度断点策略（窄/中/宽三档布局设计法）；与 06 章 Grid 星号布局的配合（自适应两条腿：布局伸缩 + 状态切换）；StateTrigger 自定义入口一句带过；模板内 VSM 与控件默认状态（链 26 章）。

- [ ] 按通用模板五步执行

---

### Task 32: 第 29 章 动画

**Files:** `examples/26-customization/AnimationPage.*`、`docs/29-animation.md`、场景表

**页面与 smoke**：Storyboard + DoubleAnimation（矩形 Width 0→300，Duration 1s，HoldEnd）由按钮 Begin；ColorAnimation（Fill 红→蓝）；RepeatBehavior="Forever" 的 ProgressRing 式旋转（**DoubleAnimation 转 RotateTransform**）；"Animate" 按钮触发 → smoke：Nav → 点 Animate → 等 2s → click-2.png 矩形已变宽变蓝（终态确定性）；Button.Transitions / EntranceThemeTransition 一行演示

**文档必须覆盖**：Storyboard 驱动模型（x:Name 注册进 Page.Resources，`FindName` 后 Begin）；DoubleAnimation From/To/By/Duration/RepeatBehavior/AutoReverse/EasingFunction（CubicEase 等）；**EnableDependentAnimation 机制（默认禁"影响布局的动画"的规则——Width 动画为何常"不动"，正文实测写法）**；ColorAnimation/ObjectAnimationUsingKeyFrames；变换优先（RenderTransform 动画不动布局——性能机制）；Transitions 家族（ThemeTransition 隐式过场 vs Storyboard 显式控制）与导航过场（NavigationThemeTransition，画廊外壳已用）；动画节奏规范一句。

- [ ] 按通用模板五步执行

---

### Task 33: 第 30 章 图形与媒体

**Files:** `examples/26-customization/DrawingPage.*` + `Assets/shapes.png`（任一小图，Content 项登记进 vcxproj）、`docs/30-drawing-media.md`、场景表

**页面与 smoke**：Shape 区（Ellipse/Rectangle/Line/Polygon/Path 迷你语法各一，Stroke/Fill/StrokeThickness）；LinearGradientBrush 演示；Image（Assets 图片，Stretch 三态按钮切换）；ColorPicker（ColorChanged → 把旁边 Ellipse Fill 改成所选色——确定性）；MediaPlayerElement 无源摆一个（诚实边界：视频解码运行时验证不做）；smoke：Nav → ColorPicker 点选色板上一点 → click-2.png 椭圆变所选色

**文档必须覆盖**：Shape 基类（Stroke/Fill/StrokeThickness/Stretch/StrokeDashArray）；Path Data 迷你语法（M/L/A/Z 与 H/V、弧参数表）；Brush 家族（Solid/LinearGradient/RadialGradient——**ImageBrush**）；Shape 不是控件（无模板无交互，点击要套 Border/容器）；Image 的 Source（BitmapImage/UriSource/ms-appx 资源地址）、DecodePixelWidth（解码即缩放的内存机制）、Stretch/NineGrid；ColorPicker（Color 属性/ColorSpectrumComponents/IsAlphaEnabled/IsColorPreviewVisible? probe）；MediaPlayerElement 一段（Source/PosterSource/AutoPlay）；SwapChainPanel 指一句（高性能渲染入口，超出本教程）。
**probe 清单**：`ColorPicker` 主要属性、`Image.NineGrid` 类型、`Path.Data` 类型。

- [ ] 按通用模板五步执行

---

### Task 34: 进阶篇收尾

- [ ] `./build.ps1 -Examples 26-customization` PASS + `-Gallery 26` 全 5 页 smoke 判读 + 回写 + Commit `docs(winui3): 进阶篇画廊 5 章收尾`

---

### Task 35: 第 31 章 窗口与外壳 + 31-window-shell 工程

**Files:** Create `examples/31-window-shell/`（WindowShellApp：单页演示，无需画廊导航）；`docs/31-window-shell.md`；gallery-smoke 注册 31

**页面与 smoke**：ExtendsContentIntoTitleBar + SetTitleBar(自定义拖拽区)；AppWindow.TitleBar 按钮前景色定制；SystemBackdrop 三按钮（None/Mica/DesktopAcrylic——`Microsoft.UI.Xaml.Media.MicaBackdrop` 等）；"New window" 按钮（`make<ChildWindow>() + Activate()`，多窗口）；OverlappedPresenter（PreferredMinimumWidth? **probe**）；smoke：Nav（此工程无导航，直接交互）→ 点 "Mica" → click-1.png 云母背景 + 自绘标题栏；再点 "New window" → click-2.png 两个窗（ui-smoke 拍 MainWindowHandle——若第二窗不入镜，用"诚实边界"记 manual 验证）

**文档必须覆盖**：Window 与 AppWindow 双层 API（谁管什么：Window=XAML 宿主，AppWindow=壳 HWND 语义）；标题栏三种做法（系统默认/ExtendsContentIntoTitleBar+SetTitleBar/AppWindow.TitleBar 按钮 API）与命中测试机制（SetTitleBar 区域成为拖拽区的规则 + Caption 是默认拖拽区）；SystemBackdrop 类型族（Mica/Acrylic，标题栏扩展时背景贯通）；多窗口（每 Window 独立 UI 线程/DispatcherQueue？实测写清 —— 多窗同线程 vs 每窗一线程两模式）；窗口尺寸/位置（AppWindow.Resize/Move，OverlappedPresenter 边框/最小尺寸 **probe**）；图标（AppWindow.SetIcon）；单实例（Microsoft.Windows.AppLifecycle.AppInstance：GetInstances/FindOrRegisterForKey/RedirectActivationTo + ActivationRegistrationManager——**README 后续方向正式落实；运行时验证边界：第二实例启动重定向的实测做一次记录**）。
**probe 清单**：`Window.AppWindow` 存在性（1.8 ✓）、`MicaBackdrop/DesktopAcrylicBackdrop`、`OverlappedPresenter.PreferredMinimumWidth/Height`、`AppInstance.FindOrRegisterForKey`、`AppWindow.SetIcon`。

- [ ] 建工程 → 页面四件套 → build PASS → smoke 调偏移 → 文档 → Commit `docs(winui3): 第 31 章 窗口与外壳 + 31-window-shell 工程`

---

### Task 36: 第 32 章 增补值转换器节 + 示例扩展

**Files:** Modify `docs/32-binding-mvvm.md`（新 32.8 节）、`examples/32-binding-mvvm/`（主窗口加转换器演示区）

**内容**：`IValueConverter` runtimeclass 完整实现（.idl 声明 `Microsoft.UI.Xaml.Data.IValueConverter` 的 Convert/ConvertBack 签名（**probe 精确形状**）→ 实现 box/unbox → Page.Resources 注册 `{StaticResource}` → `x:Bind` 用 `Converter={StaticResource …}` 与 ConverterParameter）；**x:Bind 没有内置 bool→Visibility 转换（README 既载结论）→ 函数绑定替代（`x:Bind ShowCount(Count)`）两条路线对照**；转换器 vs 函数绑定的选择（转换器可复用跨页/跨工程，函数绑定免注册类型）；示例：任务计数 → 文案（int→string）+ 布尔 → 可见性两个转换器。

- [ ] probe IValueConverter.Convert 精确签名 → 示例扩展 → build PASS → smoke（点 "Add item" 两项 → 转换器驱动的状态区出现）→ 文档节 → Commit `docs(winui3): 32 章新增值转换器节——IValueConverter 与函数绑定双路线`

---

### Task 37: 第 35 章 TaskFlow 实战 + 35-taskflow 工程

**Files:** Create `examples/35-taskflow/`（TaskFlow）+ `docs/35-taskflow.md`；gallery-smoke 注册 35

**工程结构**（收束全书）：

```text
TaskFlow/
├── App.* / main.cpp / pch.* / MainWindow.*   NavigationView 外壳（Tasks/Settings 两项）
├── TaskListPage.*     列表页：ListView + DataTemplate + 增/完成/删
├── SettingsPage.*     设置页：ToggleSwitch（Mica 开关）+ 说明
├── Task.h/cpp         Model::Task runtimeclass（INPC：Title/Done）
├── TaskViewModel.*    VM：IObservableVector<Task> + LoadAsync/SaveAsync + Add/Toggle/Remove
├── Storage.h/cpp      Service：Windows.Data.Json 序列化 → %LOCALAPPDATA%\TaskFlow\tasks.json
└── AddTaskDialog.*    ContentDialog 自定义表单（TextBox+CheckBox）
```

（Task/TaskViewModel/AddTaskDialog 的 runtimeclass 各自独立 .idl，互不引用页类型则无 MIDL2011；VM 被 x:Bind 引用 → 成员进 IDL + factory_implementation——32 章模式。）

**必经模式**（每条在正文标注出处章号）：INPC 完整实现（32）、IObservableVector（32）、x:Bind OneWay/TwoWay（32/03）、协程异步 + TryEnqueue 切回 UI（32）、JSON + GetEnvironmentVariableW 兜底（34——**非打包不能 ApplicationData 的实测结论落地**）、ContentDialog 表单（24）、NavigationView 导航（22）、Mica 主题（31/33）。

**smoke**：① 点 "Add sample" → 列表出现两项（click 截图判读）② 点列表项复选框 → 项划线/状态变（ListView ItemTemplate 里 CheckBox IsChecked={Binding Done}）③ 重启进程 → 数据还在（持久化证明：smoke 跑两次读 tasks.json + 二次启动截图）。

- [ ] 建工程（骨架→Model/VM→Storage→页面→对话框，每步 build 一次）→ 全 smoke 三条 → 文档（含分层图与文件清单）→ Commit `feat(winui3): TaskFlow 实战工程 + 第 35 章——全书收束`

---

### Task 38: README 全面重写 + 全量终验

**Files:** Rewrite `WinUI3/README.md`

- [ ] **Step 1**: 新目录表（35 篇七部分）、新学习路线图（ASCII，依赖链到 35）、环境要求与版本基线照旧
- [ ] **Step 2**: 验证状态区重写：10 工程清单表、**每画廊每页 smoke 结果表**（页名/交互/证据截图路径）、新"验证推翻并改回正文的写法"清单（把各阶段记下的新坑全部汇总——预计 ProgressRing determinate、TreeView ItemsSource、DataGrid 资源字典、Generic.xaml 构建动作、UpdateSourceTrigger 实测等条目）
- [ ] **Step 3**: 常见错误速查表扩容（新坑按"症状/原因与解法/出处"格式补 ~10 行）
- [ ] **Step 4**: 后续扩展方向更新（删已落实项：值转换器/窗口外壳/自定义控件/VSM；保留：通知/后台任务/测试/Islands）
- [ ] **Step 5**: **全量终验**：`./build.ps1` 10 工程全绿；`gallery-smoke.ps1` 全画廊全页跑通并逐页判读；`grep -rn "](docs/" README.md docs/*.md` 无死链
- [ ] **Step 6**: Commit `docs(winui3): README 重写——35 章目录/验证状态/速查表扩容`

---

### Task 39: 记忆沉淀

- [ ] 写 `G:\xulun\.claude\projects\G--code-guide\memory\winui3-tutorial-build.md`：35 章结构、画廊工程模式（页面四件套+三处登记）、gallery-smoke 场景驱动、本计划实测推翻正文的全部坑、DataGrid/Generic.xaml 等构建配方；MEMORY.md 加索引行

---

## Self-Review 记录

1. **Spec 覆盖**：35 章全部有任务（1–5 章 Task 1 保留；6 章 Task 1 重编号；7–16 = Task 4–13；17–20 = Task 16–19；21–25 = Task 22–26；26–30 = Task 29–33；31 = Task 35；32 增补 = Task 36；33/34 = Task 1 重编号；35 = Task 37）；10 工程齐（01/06/07/17/21/26/31/32/34/35）；三条通道与每页 smoke = Task 3 + 各收尾任务；README = Task 38。✓
2. **占位符扫描**：内容任务的文档正文本身是交付物，由覆盖清单+页面规格驱动，无 TBD。✓
3. **类型一致性**：画廊应用名 BasicGallery/CollectionsGallery/ShellGallery/CustomGallery/WindowShellApp/TaskFlow 与 gallery-smoke.ps1 的 ValidateSet 参数、目录名 07/17/21/26/31/35 一致；页面 Tag 命名与分发表分支一致。✓
