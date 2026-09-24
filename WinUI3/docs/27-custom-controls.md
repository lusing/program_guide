# 27. 自定义控件与 UserControl

上一篇：[26 样式与控件模板](./26-styles-templates.md) ｜ 下一篇：[28 VisualStateManager 与自适应](./28-vsm-adaptive.md)

现成控件拼不出来的界面有两条出路：**UserControl**（组合现成控件成一个部件）与**模板化自定义控件**（templated control——一个 runtimeclass + 一份可替换的默认模板，WinUI 生态的标准控件就是这么写的）。本章把两条路都走一遍，坑全在实测里。示例代码来自功能工程 `examples/26-theme-lab/`（主题实验室：预设换肤、自定义控件仪表盘、accent 即改、VSM、动画、Shape 图表）。

## 27.1 决策线

| | UserControl | templated Control |
|---|---|---|
| 本质 | 一个 XAML 页面当控件用 | 真正的控件类（继承 `Control`） |
| 外观 | 固定的组合树 | 默认模板（Generic.xaml），**使用者可整体换掉** |
| 属性 | 普通 C++ 属性（x:Bind 需要 IDL 声明） | **依赖属性**（可绑定、可动画、可被样式 Setter 命中） |
| 适用 | 应用内部的私有部件 | 要分发/要深度换肤的正式控件 |

**要"别人能换模板"就 templated，否则 UserControl**——后者成本低一个数量级。

## 27.2 UserControl：组合（主题实验室的真控件）

`26-theme-lab` 仪表盘的四个格子（Active users / Orders today / Revenue / Uptime）就是同一个 UserControl——`LabeledValueControl`。它的完整四件套：

**① XAML**——外观固定，内容由属性喂：

```xml
<UserControl x:Class="ThemeLab.LabeledValueControl" ...
             xmlns:local="using:ThemeLab">
    <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"
            BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
            BorderThickness="1" CornerRadius="10" Padding="18,14">
        <StackPanel Spacing="4">
            <TextBlock Text="{x:Bind Label, Mode=OneWay}" Opacity="0.65"/>
            <TextBlock Text="{x:Bind Value, Mode=OneWay}" FontSize="26" FontWeight="Bold"/>
        </StackPanel>
    </Border>
</UserControl>
```

**② IDL**——x:Bind 路径上的属性必须声明（03 章规则的 UserControl 版）。注意 **runtimeclass 不收静态成员**，依赖属性的 `XXXProperty()` 静态位只能留在 C++ 侧（实测：写了就 MIDL2025 语法错）：

```idl
runtimeclass LabeledValueControl : Microsoft.UI.Xaml.Controls.UserControl
{
    LabeledValueControl();
    String Label;
    String Value;
}
```

**③④ 头/源**——这里有一个关键的升级选择：属性没有用"普通字段封装"，而是**真·依赖属性**。普通字段版 `Mode=OneWay` 的 x:Bind 要靠手动通知（或接受 OneTime）；依赖属性版 SetValue 天生就是变更通知，还能被样式 Setter 和动画命中：

```cpp
Microsoft::UI::Xaml::DependencyProperty LabeledValueControl::m_labelProperty{ nullptr };

Microsoft::UI::Xaml::DependencyProperty LabeledValueControl::LabelProperty()
{
    if (!m_labelProperty)
    {
        // 默认值必须给空串：x:Bind 在 InitializeComponent 里就取值，
        // null 默认会让 unbox 抛异常（stowed 0xC000027B，实测）
        m_labelProperty = Microsoft::UI::Xaml::DependencyProperty::Register(
            L"Label", xaml_typename<Windows::Foundation::IReference<hstring>>(),
            xaml_typename<ThemeLab::LabeledValueControl>(),
            Microsoft::UI::Xaml::PropertyMetadata(box_value(L"")));
    }
    return m_labelProperty;
}

hstring LabeledValueControl::Label() const
{
    return unbox_value<hstring>(GetValue(LabelProperty()));   // 经惰性注册，勿直用字段
}

void LabeledValueControl::Label(hstring const& value)
{
    SetValue(LabelProperty(), box_value(value));
}
```

完整清单（与页面四件套同构）：`.idl` + `.xaml` + `.xaml.h` + `.xaml.cpp`，vcxproj 四处登记（Page 项 + Midl 项），pch.h 加头。使用处 `xmlns:local="using:ThemeLab"`：

```xml
<local:LabeledValueControl x:Name="TileUsers" Label="Active users" Value="1,284"/>
<local:LabeledValueControl x:Name="TileOrders" Label="Orders today" Value="312"/>
```

### 27.2.1 DP 三连坑（26-theme-lab 逐个撞出来的启动崩溃）

上面的实现注释里埋了两颗雷的解法，完整事故记录值得整段读——症状都是启动即崩（0xC000027B stowed exception）：

**坑①：DP 不带默认值。** `Register(..., nullptr)`（无 PropertyMetadata）时，`GetValue` 在属性未被赋值前返回 null IInspectable，`unbox_value<hstring>(null)` 抛异常。而 **x:Bind 的生成代码在 `InitializeComponent` 里就取一次值**——解析期即崩。解法就是上面的 `PropertyMetadata(box_value(L""))`。

**坑②：getter/setter 直用未注册的静态字段。** 惰性注册放在 `LabelProperty()` 里，但若 `Label()` 写成 `GetValue(m_labelProperty)`（直用字段），首次调用时字段还是 nullptr——`GetValue(nullptr)` 照样崩。**所有取值路径必须先经 `LabelProperty()`**。

**坑③：错误信息会指路。** 这类崩溃用 App 级 `UnhandledException` 钩子把 `e.Message()` 写文件（主题实验室开发时的临时诊断），拿到的是 `Failed to assign to property 'ThemeLab.LabeledValueControl.Label'. [Line: 77 Position: 44]`——直接指到 MainWindow.xaml 第 77 行的 `Label="Active users"` 属性赋值，三分钟锁定坑②。这套"钩子落盘读消息"的手法对一切 stowed 崩溃通用。

另一个相关实测：**IDL 注释必须纯 ASCII**。LabeledValueControl.idl 里写中文注释，MIDL 报的却是第 5 行 `runtimeclass` 一带莫名的 MIDL2025 语法错——错误位置和真因（注释字节）隔着两行，排查时先查文件编码再查语法。

## 27.3 templated Control：五件套

`LabeledValueControl`（Label/Value 两属性 + PART 部件）的完整构成：

**① IDL**（与引用它的页面合并在同一个 `.idl`——MIDL2011 规则）：

```idl
runtimeclass LabeledValueControl : Microsoft.UI.Xaml.Controls.Control
{
    LabeledValueControl();
    String Label;
    String Value;
}
```

**② 实现头/源**——依赖属性 + DefaultStyleKey + OnApplyTemplate：

```cpp
LabeledValueControl::LabeledValueControl()
{
    // 27.3 实测坑①：DefaultStyleKey 的属性类型是 object，值是装箱字符串
    DefaultStyleKey(box_value(L"ThemeLab.LabeledValueControl"));
}

Windows::UI::Xaml::DependencyProperty LabeledValueControl::ValueProperty()
{
    if (!s_valueProperty)
    {
        s_valueProperty = Microsoft::UI::Xaml::DependencyProperty::Register(
            L"Value", xaml_typename<Windows::Foundation::IInspectable>(),
            xaml_typename<ThemeLab::LabeledValueControl>(), nullptr);
    }
    return s_valueProperty;
}

void LabeledValueControl::OnApplyTemplate()
{
    base_type::OnApplyTemplate();
    // TemplatePart 约定：模板就位后取部件
    if (auto part = GetTemplateChild(L"PART_ValueText").try_as<TextBlock>())
    {
        part.Text(Value().empty() ? L"-" : Value());
    }
}
```

**③ 默认模板**（`Themes/Generic.xaml`，vcxproj 里作 `Page` 项登记）：

```xml
<Style TargetType="local:LabeledValueControl">
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="local:LabeledValueControl">
                <Border ...>
                    <StackPanel Orientation="Horizontal" Spacing="10">
                        <TextBlock Text="{TemplateBinding Label}" Opacity="0.7"/>
                        <TextBlock x:Name="PART_ValueText" FontWeight="SemiBold"/>
                    </StackPanel>
                </Border>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
```

**④⑤** vcxproj 登记（ClInclude/ClCompile；**没有独立 Midl**——声明在页面的 .idl 里）+ pch.h 加头。

运行链：`DefaultStyleKey`（装箱类名串）→ 框架到 `Themes/Generic.xaml` 找同名隐式 Style → 应用模板 → `{TemplateBinding Label}` 拉属性 → `OnApplyTemplate` 里 `GetTemplateChild(L"PART_ValueText")` 拿部件干活。**全链路已实测**（Bump value 按钮 → Value DP → 模板部件刷新，smoke 截图 "value = 1"）。

## 27.4 本地工程的投影陷阱（CppWinRTOptimized）

本套教程的画廊工程（已由功能工程取代）开发时撞上的一族连环坑，值得整段记录：

- **症状**：`using namespace Microsoft::UI::Xaml::Media::Animation;` 在某页面 C2760 语法错，仿佛命名空间不存在。
- **根因链**：模板工程默认 `CppWinRTOptimized=true`——cppwinrt 按"工程实际引用"**裁剪生成的投影头**；用了冷门类型（Storyboard 等）而工程 IDL 没引用过它时，该命名空间的声明可能不完整。
- **解法**（本工程实测有效）：该 vcxproj 里 `<CppWinRTOptimized>false</CppWinRTOptimized>` 换全量投影（慢一点，类型全）；代码里冷门类型用**全限定名**最稳。

配套教训：**改这类源文件用编辑器/精确工具，别用 shell 里拼的字符串替换**——本工程曾因换行风格（CRLF/LF）不匹配导致替换静默未命中，排查了一整轮。

## 27.5 实测坑位

1. **DefaultStyleKey 收装箱对象**（27.3①，C2665 实测：传裸字符串字面量编不过，`box_value` 包装）。
2. **IDL 里 `IReference<hstring>` 写法在工程命名空间内 MIDL2011**：`hstring` 被解析成 `ThemeLab.hstring`——属性直接声明 `String`，可空语义在实现层自己管。
3. **templated 控件的声明与引用它的页面同 .idl**（04 章 MIDL2011 规则的控件版）。
4. **Generic.xaml 必须叫这个名字、放 Themes/ 下**：DefaultStyleKey 的查找路径写死。
5. **`GetTemplateChild` 返回 IInspectable**：`try_as<TextBlock>()` 判空再取。
6. **UserControl + DP 的三连坑**（27.2.1）：默认值必给、取值先经惰性注册、stowed 崩溃用 UnhandledException 落盘定位。
7. **IDL 注释必须 ASCII**（27.2.1 坑③的姊妹）：中文注释的报错位置会漂移。
8. **投影裁剪**（27.4）。

## 27.6 小结

| 需求 | 路线 |
|------|------|
| 私有组合部件 | UserControl 四件套（IDL 声明 x:Bind 属性） |
| 可换模板的正式控件 | templated Control：IDL + DP + DefaultStyleKey + Generic.xaml + OnApplyTemplate |
| 模板内读属性 | `{TemplateBinding Prop}` |
| 模板部件交互 | `GetTemplateChild(L"PART_X")` |

运行时证据：`.smoke/26-theme-lab/preset/tap-1.png`——仪表盘四格全是 LabeledValueControl（UserControl + Label/Value 两个依赖属性）：Active users/Orders today/Revenue/Uptime 各自独立取值，x:Bind OneWay 刷新。它的完整实现（含 DP 注册的三个实测坑）就在本章。

---

上一篇：[26 样式与控件模板](./26-styles-templates.md) ｜ 下一篇：[28 VisualStateManager 与自适应](./28-vsm-adaptive.md) ｜ 返回 [目录](../README.md)
