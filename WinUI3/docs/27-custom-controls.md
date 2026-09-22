# 27. 自定义控件与 UserControl

上一篇：[26 样式与控件模板](./26-styles-templates.md) ｜ 下一篇：[28 VisualStateManager 与自适应](./28-vsm-adaptive.md)

现成控件拼不出来的界面有两条出路：**UserControl**（组合现成控件成一个部件）与**模板化自定义控件**（templated control——一个 runtimeclass + 一份可替换的默认模板，WinUI 生态的标准控件就是这么写的）。本章把两条路都走一遍，坑全在实测里。示例来自画廊工程的 `CustomControlPage`（导航 **CustomControl** 项）与它身后的 `TitleRow` / `LabeledValueControl`。

## 27.1 决策线

| | UserControl | templated Control |
|---|---|---|
| 本质 | 一个 XAML 页面当控件用 | 真正的控件类（继承 `Control`） |
| 外观 | 固定的组合树 | 默认模板（Generic.xaml），**使用者可整体换掉** |
| 属性 | 普通 C++ 属性（x:Bind 需要 IDL 声明） | **依赖属性**（可绑定、可动画、可被样式 Setter 命中） |
| 适用 | 应用内部的私有部件 | 要分发/要深度换肤的正式控件 |

**要"别人能换模板"就 templated，否则 UserControl**——后者成本低一个数量级。

## 27.2 UserControl：组合

```xml
<UserControl x:Class="CustomGallery.TitleRow" ...>
    <Border Background="{ThemeResource CardBackgroundFillColorDefaultBrush}" ...>
        <StackPanel Orientation="Horizontal" Spacing="12">
            <TextBlock Text="{x:Bind Title, Mode=OneWay}" FontWeight="SemiBold"/>
            <TextBlock Text="{x:Bind Value, Mode=OneWay}" Opacity="0.7"/>
        </StackPanel>
    </Border>
</UserControl>
```

```idl
// TitleRow.idl —— x:Bind 路径上的属性必须声明（03 章规则的 UserControl 版）
runtimeclass TitleRow : Microsoft.UI.Xaml.Controls.UserControl
{
    TitleRow();
    String Title;
    String Value;
}
```

```cpp
hstring TitleRow::Title() { return m_title; }
void TitleRow::Title(hstring const& value) { m_title = value; }
```

完整清单（与页面四件套同构）：`.idl` + `.xaml` + `.xaml.h` + `.xaml.cpp`，vcxproj 四处登记（Page 项），pch.h 加头。使用处 `xmlns:local="using:CustomGallery"` + `<local:TitleRow Title="Tasks done" Value="7"/>`。

**实现细节**：属性是普通字段封装（不是依赖属性），所以 `Mode=OneWay` 的 x:Bind 要靠手动通知（或接受 OneTime）；对"设一次就用"的部件足够。

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
    DefaultStyleKey(box_value(L"CustomGallery.LabeledValueControl"));
}

Windows::UI::Xaml::DependencyProperty LabeledValueControl::ValueProperty()
{
    if (!s_valueProperty)
    {
        s_valueProperty = Microsoft::UI::Xaml::DependencyProperty::Register(
            L"Value", xaml_typename<Windows::Foundation::IInspectable>(),
            xaml_typename<CustomGallery::LabeledValueControl>(), nullptr);
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

`26-customization` 工程开发时撞上的一族连环坑，值得整段记录：

- **症状**：`using namespace Microsoft::UI::Xaml::Media::Animation;` 在某页面 C2760 语法错，仿佛命名空间不存在。
- **根因链**：模板工程默认 `CppWinRTOptimized=true`——cppwinrt 按"工程实际引用"**裁剪生成的投影头**；用了冷门类型（Storyboard 等）而工程 IDL 没引用过它时，该命名空间的声明可能不完整。
- **解法**（本工程实测有效）：该 vcxproj 里 `<CppWinRTOptimized>false</CppWinRTOptimized>` 换全量投影（慢一点，类型全）；代码里冷门类型用**全限定名**最稳。

配套教训：**改这类源文件用编辑器/精确工具，别用 shell 里拼的字符串替换**——本工程曾因换行风格（CRLF/LF）不匹配导致替换静默未命中，排查了一整轮。

## 27.5 实测坑位

1. **DefaultStyleKey 收装箱对象**（27.3①，C2665 实测：传裸字符串字面量编不过，`box_value` 包装）。
2. **IDL 里 `IReference<hstring>` 写法在工程命名空间内 MIDL2011**：`hstring` 被解析成 `CustomGallery.hstring`——属性直接声明 `String`，可空语义在实现层自己管。
3. **templated 控件的声明与引用它的页面同 .idl**（04 章 MIDL2011 规则的控件版）。
4. **Generic.xaml 必须叫这个名字、放 Themes/ 下**：DefaultStyleKey 的查找路径写死。
5. **`GetTemplateChild` 返回 IInspectable**：`try_as<TextBlock>()` 判空再取。
6. **投影裁剪**（27.4）。

## 27.6 小结

| 需求 | 路线 |
|------|------|
| 私有组合部件 | UserControl 四件套（IDL 声明 x:Bind 属性） |
| 可换模板的正式控件 | templated Control：IDL + DP + DefaultStyleKey + Generic.xaml + OnApplyTemplate |
| 模板内读属性 | `{TemplateBinding Prop}` |
| 模板部件交互 | `GetTemplateChild(L"PART_X")` |

画廊 `CustomControlPage` 运行时证据：`.smoke/26-customization/customcontrol/click-2.png`——TitleRow 显示 "Tasks done 7"，点击 Bump value 后 LabeledValueControl 显示 **progress / 1**、状态行 "value = 1"。

---

上一篇：[26 样式与控件模板](./26-styles-templates.md) ｜ 下一篇：[28 VisualStateManager 与自适应](./28-vsm-adaptive.md) ｜ 返回 [目录](../README.md)
