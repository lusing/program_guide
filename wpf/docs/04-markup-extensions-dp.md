# 04 · 标记扩展与依赖属性：WPF 的地基

> 对应示例：`examples/03_hello_wpf`（复用）

> **本章你将学会**：花括号标记扩展的工作原理、依赖属性机制与值优先级、附加属性。
> **前置章节**：[03 XAML 基础](03-xaml-basics.md)。

## 1. 标记扩展：花括号的魔法

第 03 章的属性值都是"字面量"。但有些值没法写死——"这个文本框的内容 = 某个数据对象的 Name 属性"。XAML 的解法：**值以 `{` 开头时，交给一个可编程对象（MarkupExtension）去求值**：

```xml
<TextBlock Text="{Binding Path=UserName}"/>
<!--                ↑ 不是字符串！是一个 Binding 扩展实例 -->
```

等价的 C# 形态（帮你祛魅）：

```csharp
textBlock.SetBinding(TextBlock.TextProperty, new Binding("UserName"));
```

高频扩展先认识五个，后文逐一展开：

| 扩展 | 作用 | 详见 |
|---|---|---|
| `{Binding ...}` | 绑定到数据 | 第 09、10 章 |
| `{StaticResource key}` | 查资源字典（加载时一次定值） | 第 13 章 |
| `{DynamicResource key}` | 查资源字典（运行时跟随变化） | 第 13 章 |
| `{x:Static local:Foo.Bar}` | 取静态字段/属性/枚举值 | — |
| `{x:Null}` | 显式赋 null（覆盖继承来的值） | — |

写法细则：花括号内 `名字=值` 逗号分隔，值含空格要加引号——`{Binding Path=My Text}` 解析失败，`{Binding Path='My Text'}` 才对。想显示一个以 `{` 开头的普通字符串，前面加空格或 `{}` 转义：`Content="{}{不是扩展}"`。

## 2. 绑定错误是静默的（先记住这条）

`{Binding}` 求值失败不抛异常、不停程序——Path 打错、DataContext 为 null，界面只是显示空白，Visual Studio"输出"窗口里多一行小字：

```text
System.Windows.Data Error: 40 : BindingExpression path error:
'UserrName' property not found for 'object' ...
```

这是 XAML 学习期最大的挫败感来源。**养成习惯：界面不对劲，先看输出窗口**。第 10 章有完整的绑定调试清单。

## 3. 普通属性 vs 依赖属性

C# 普通属性是"字段加壳"：值存在自己的字段里，谁赋值就是谁。WPF 的控件属性几乎都不是普通属性，而是**依赖属性（DependencyProperty）**——**把"值的存放"外包给 WPF 属性系统**，换来一整批普通属性给不了的能力：

```csharp
// TextBlock.Text 的真身：一个静态只读字段 + 包装器
public static readonly DependencyProperty TextProperty =
    DependencyProperty.Register(nameof(Text), typeof(string), typeof(TextBlock), new PropertyMetadata(""));

public string Text                     // 普通外观的包装
{
    get => (string)GetValue(TextProperty);
    set => SetValue(TextProperty, value);
}
```

注意依赖属性的定义是 `static readonly`——全类型共享一份注册信息，每个**实例**的值才存在属性系统里。外包换来什么：

| 能力 | 说明 | 哪章用到 |
|---|---|---|
| 数据绑定 | 值可以被绑定表达式驱动 | 09-10 |
| 样式/触发器 | Style/Trigger 批量设值、条件改值 | 13-14 |
| 动画 | 动画系统插值驱动它 | 20 |
| 值继承 | `FontSize`、`DataContext` 沿树向下继承 | 09 |
| 优先级合成 | 多个来源同时"想要"这个值时按固定规则裁决 | 本章第 4 节 |

**规则一句话：要被绑定/样式/动画驱动的属性，必须是依赖属性。** 这也预告了第 10 章的分工：绑定的**目标**端必须是依赖属性（控件属性天然满足），绑定的**源**端只需要普通属性 + INPC 通知。

## 4. 值优先级：一个值的最终裁决

同一个属性可能同时被样式、模板、绑定、本地赋值"想要"。WPF 按固定的优先级从高到低裁决：

```text
高  动画（正在运行的动画值）
 │  本地值（XAML 特性 / C# SetValue 直接赋的值）
 │  模板触发器 / 样式触发器
 │  样式 Setter
 │  （主题默认样式）
 │  属性值继承（沿树继承来的，如 FontSize、DataContext）
低  默认值（注册时的 PropertyMetadata）
```

两个实用推论：

1. **XAML 里直接写了 `Background="Red"`，任何样式触发器都改不动它**——本地值优先级高于触发器。想要"默认值 + 触发器改值"，默认值必须写进 Style 的 Setter，不能写在元素上（第 14 章的核心坑）
2. **动画优先于一切**——动画播完属性回到先前值，除非 `FillBehavior="HoldEnd"`（第 20 章）

记住这张优先级表，WPF 的"属性怎么变成这个值的"九成疑难都有答案。

## 5. 附加属性：属性定义在别人身上

第 05 章会出现这样的代码：

```xml
<Grid>
    <Button Grid.Row="1" Grid.Column="2" Content="我在第 2 行第 3 列"/>
</Grid>
```

`Button` 没有 `Row` 属性——`Grid.Row` 是**附加属性（Attached Property）**：属性注册在 Grid 上，值却挂在子元素身上。语义是"Grid 问每个孩子：你该在第几行？"——布局信息由孩子申报、容器解释。

C# 里的对应写法：

```csharp
Grid.SetRow(button, 1);          // 设置附加属性
var row = Grid.GetRow(button);   // 读取
```

附加属性的常见出场：`Grid.Row/Column`（定位）、`Canvas.Left/Top`（绝对坐标）、`DockPanel.Dock`（停靠方向）、`ToolTipService.ToolTip`。第 08 章的 `VirtualizingStackPanel.IsVirtualizing` 也属此类。

定义方法与依赖属性同族（`RegisterAttached`），写自定义控件/容器时才会自己定义，入门阶段用懂即可。

## 6. 自己注册一个依赖属性（选读）

自定义控件免不了注册依赖属性。最小模板（含变更回调）：

```csharp
public static readonly DependencyProperty AccentProperty =
    DependencyProperty.Register(
        nameof(Accent),                    // 属性名（字符串与包装器一致）
        typeof(Brush), typeof(MyControl),  // 属性类型、所属类型
        new PropertyMetadata(Brushes.SteelBlue, OnAccentChanged));

public Brush Accent
{
    get => (Brush)GetValue(AccentProperty);
    set => SetValue(AccentProperty, value);
}

private static void OnAccentChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
{
    // 值变化时的响应逻辑；d 是发生变化的实例，需要强转回 MyControl
}
```

三个易错点：`nameof` 与注册名必须一致（不一致运行期绑定失败）；默认值必须是**不可变对象**（写 `new Brush()` 会所有实例共享同一引用）；回调是 static 的，实例状态通过 `d` 拿。

## 7. 常见坑

**标记扩展里引号混用**：`StringFormat='Hello, {0}!'` 外层双引号内层单引号；格式串以 `{` 开头要加 `{}` 转义（`StringFormat={}{0:N2}`），否则解析器把 `{0:N2}` 当扩展。

**绑定/资源全是静默失败**：见第 2 节。输出窗口是 XAML 时代的"控制台"。

**给依赖属性包装器写字段**：包装器里不该有 `_field = value`——依赖属性没有字段，值在属性系统里。包装器只有 GetValue/SetValue 两件事，附加逻辑应放元数据回调。

**默认值共享引用**：`PropertyMetadata(new List<string>())` 会让所有实例共享同一个 List。可变默认值改用回调里惰性创建（FrameworkPropertyMetadata 的 coerce/changed）。

**附加属性当普通属性用**：`button.Row = 1` 不存在——附加属性只能 `Grid.SetRow(btn, 1)`，XAML 里写作 `Grid.Row="1"`。

## 8. 实战建议

- 现阶段不必手写依赖属性，但要**认得出**：看到 `public static readonly DependencyProperty XxxProperty` 就知道这是依赖属性的定义处
- 属性"不听话"时，先套值优先级表排查：大概率是本地值压住了样式/触发器
- 附加属性反着记效率高：`容器.属性` 写在**子元素**身上——定位信息永远由孩子申报
- 自定义类型暴露给绑定的属性，普通属性 + INPC（第 10 章）就够了——依赖属性是给"控件端"用的

## 自测

1. **`{Binding Name}` 和字符串 `"Binding Name"` 的本质区别？** —— 前者创建 Binding 标记扩展实例由它求值，后者是字面字符串。
2. **依赖属性把什么外包了？换来哪五个能力？** —— 值的存放；绑定、样式/触发器、动画、值继承、优先级合成。
3. **样式触发器改不动元素的 Background，为什么？** —— 本地值优先级高于样式触发器（第 4 节优先级表）。
4. **`Grid.Row="1"` 为什么能写在 Button 上？** —— 附加属性：注册在 Grid、值挂在子元素，布局信息由孩子申报。

---
上一章：[03 XAML 语言基础](03-xaml-basics.md) ｜ 下一章：[05 布局系统](05-layout.md)
