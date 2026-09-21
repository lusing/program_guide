# 03 · XAML 语言基础：对象树的声明式写法

> 对应示例：`examples/03_hello_wpf`（复用）

> **本章你将学会**：XAML 与 C# 的对应关系、三种属性写法、两套命名空间、内容属性、x:Name 的作用。
> **前置章节**：[02 应用骨架](02-app-lifecycle.md)。

## 1. XAML 是什么

初学者常把 XAML 当成"微软版的 HTML"，这个类比只对了一半。准确的定义是：

> **XAML 不是模板语言，而是对象图的声明式写法**——每个元素 = 一个对象，每个属性 = 一次赋值，嵌套 = 对象树。

它没有"if"、没有循环、没有任何流程控制，因为它的职责只有一个：**把一组对象及其嵌套关系写下来**。运行时解析器按声明构建真实的 .NET 对象。（XAML 确实存在 x:ClassModifier 等编译期指令，但全部是声明性的。）

编译时 XAML 被转成 BAML（二进制格式）嵌进程序集，运行时由解析器实例化。所以"XAML 里能写什么"完全由"对象有哪些属性"决定——没有一丝超自然能力。

## 2. 三种等价写法：从 XAML 到 C#

同一个按钮，三种写法完全等价：

**写法一：属性特性（attribute）**——最常用，一行搞定：

```xml
<Button Background="Red" Content="确定" />
```

**写法二：属性元素（property element）**——属性值复杂时展开成子元素：

```xml
<Button Content="确定">
    <Button.Background>Red</Button.Background>
</Button>
```

**写法三：纯 C#**——和 XAML 毫无关系地构造同样的对象：

```csharp
var b = new Button { Background = Brushes.Red, Content = "确定" };
```

把三种写法并排看，映射关系一目了然：`Background="Red"` 是"对 Background 属性赋字符串 Red"，`<Button.Background>` 是它的展开形式，C# 是它的最终形态。**能互相翻译，才是真的懂了 XAML**。

### TypeConverter：字符串怎么变成对象

`Background="Red"` 能成立靠的是 **TypeConverter（类型转换器）**：XAML 里一切属性值都是字符串，`Red` 由 BrushConverter 转成 `SolidColorBrush`，`Width="220"` 转成 double。常见的都有转换器兜底；没有转换器的复杂类型（如渐变画刷要配多个渐变点）就得用属性元素语法展开：

```xml
<Button Content="渐变按钮">
    <Button.Background>
        <LinearGradientBrush>
            <GradientStop Color="Yellow" Offset="0"/>
            <GradientStop Color="Orange" Offset="1"/>
        </LinearGradientBrush>
    </Button.Background>
</Button>
```

## 3. 两套命名空间

每个 XAML 根元素开头两行 xmlns 是固定搭配，初学者经常抄丢一个：

```xml
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"   ← 默认：WPF 全部控件
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"              ← x: 前缀：XAML 语言自身
```

- **默认命名空间**把几十个 WPF 的 .NET 命名空间（`System.Windows.Controls`、`System.Windows.Shapes` 等）打包映射到"无前缀"，所以 `<Button>`、`<Grid>` 直接写
- **x: 前缀**是 XAML 语言自身的能力：`x:Class`（连到哪个 C# 类）、`x:Name`（生成字段，见第 6 节）、`x:Key`（资源字典键，第 13 章）、`x:Static`（取静态成员）

URL 只是"身份证号"，不是网址——不联网、不下载任何东西，纯粹用来唯一标识这套映射。

**要用自己的类**（ViewModel、转换器、自定义控件），追加一个映射：

```xml
xmlns:local="clr-namespace:HelloWpfApp"           <!-- 同程序集 -->
xmlns:sys="clr-namespace:System;assembly=mscorlib" <!-- 别的程序集要带 assembly -->
```

前缀名随你取，`local` 是惯例（"本项目的类"）。

## 4. 集合语法与内容属性

`StackPanel` 里能直接罗列子元素，不用写 `<StackPanel.Children>`：

```xml
<StackPanel>
    <TextBlock Text="第一行" />
    <Button Content="按钮" />
</StackPanel>
<!-- 完整展开等价于：
<StackPanel>
    <StackPanel.Children>
        <TextBlock Text="第一行"/>
        <Button Content="按钮"/>
    </StackPanel.Children>
</StackPanel> -->
```

能这样简写，是因为 StackPanel 把 `Children` 属性标记成了**内容属性（ContentProperty）**——一个类型最多指定一个"最重要的属性"，XAML 里它的子元素直接归它。类似的还有：

| 类型 | 内容属性 | 直接写子元素 = 给谁 |
|---|---|---|
| `ContentControl`（Button 等） | `Content` | 按钮里的内容 |
| `ItemsControl`（ListBox 等） | `Items` | 条目集合 |
| `Grid` | `Children` | 子元素 |
| `Window`/`Page` | `Content` | 窗口内容 |

这解释了两个常见写法：`<Button>确定</Button>` 等价于 `<Button Content="确定"/>`；`<ListBox>` 里直接写 `<ListBoxItem/>` 等价于往 `Items` 里加条目。理解了内容属性，XAML 里"元素套元素"就不再是语法背诵，而是对象构造的自然结果。

## 5. 内容可以是任意对象

WPF 与 WinForms 的分水岭在这里：**Content/Items 装的是 object，不是字符串**。

```xml
<Button>
    <StackPanel Orientation="Horizontal">
        <Ellipse Width="12" Height="12" Fill="Green"/>
        <TextBlock Text=" 在线" Margin="4,0,0,0"/>
    </StackPanel>
</Button>
```

按钮里装一棵 UI 子树完全合法（一个按钮 = 图标 + 文字，不需要"自绘按钮"）。更进一步，内容可以是非 UI 对象——`ListBox` 绑定一组 `Person`，条目默认显示 `ToString()`，配 DataTemplate 才显示成你想要的样子（第 15 章兑现这个伏笔）。

## 6. x:Name 与 Name

```xml
<TextBox x:Name="NameTextBox" />
```

`x:Name` 做两件事：

1. 在生成的分部类（.g.cs）里创建同名字段——所以 C# 里能直接写 `NameTextBox.Text`
2. 给对象登记名字，供 `{Binding ElementName=NameTextBox}` 绑定（第 09 章）和 `FindName` 查找

多数控件还有个 `Name` 属性（框架层面的便捷别名），两者效果几乎总是一样，教程统一用 `x:Name`。**规则：需要在 C# 里访问的元素才命名**——给每个元素都起名是无意义的噪音。

## 7. 常见坑

**XAML 区分大小写**：`<button>` 直接编译错误（正确是 `<Button>`），`content` 属性同理。属性值不区分（`Red`/`red` 都行）。

**报错"属性 XX 不存在"**：先查三处——元素名拼对了吗；属性真的在这个类型上吗（`Grid` 没有 `Padding`，第 05 章有专属坑条目）；默认命名空间的两行 xmlns 抄全了吗。

**x:Name 改名后 C# 报错**：字段在 obj 的 .g.cs 里生成，改 XAML 后 IDE 没重新生成。Rebuild 一次。

**属性元素写错顺序**：`<Button.Background>` 必须是 Button 的**直接子元素**，多套一层 Grid 就报错。属性元素属于它的对象，不能隔代。

**`Content="123"` 与 `Content="{Binding Count}"` 的显示差异**：前者的 Content 是字符串 "123"，后者是数字——显示上一样，但 StringFormat、对齐等行为可能不同；格式化交给 StringFormat（第 09 章）而不是在数据端凑字符串。

## 8. 实战建议

- 简单值用属性特性、复杂对象用属性元素，两者混用是常态，别追求"全特性"或"全元素"
- 每写一段 XAML，心里过一遍它的 C# 形态（`new Button { Content = ..., Background = ... }`）——第 23 章导航示例有纯 C# 构建界面的正面对照
- 自定义类型要在 XAML 里用，先加 xmlns 映射；"找不到类型"是编译期错误，比绑定错误友好得多，改起来快
- 数字/尺寸直接写（TypeConverter 会转），颜色能写名字就写名字（`AliceBlue`），要精确值再写 `#3B82F6`（RGBA 的十六进制）

## 自测

1. **XAML 的本质是什么？为什么它没有 if 和循环？** —— 对象图的声明式写法；它的职责只是"描述一组对象和嵌套关系"，逻辑属于 C#。
2. **`Background="Red"` 里的字符串是怎么变成画刷的？** —— TypeConverter（BrushConverter）在解析时转换。
3. **`<Button>确定</Button>` 为什么不用写 `Content=`？** —— Button 的内容属性是 Content，直接子元素自动赋给它。
4. **`x:Name` 做了哪两件事？** —— 生成分部类同名字段 + 登记名字供 ElementName 绑定/FindName 使用。

---
上一章：[02 应用骨架与生命周期](02-app-lifecycle.md) ｜ 下一章：[04 标记扩展与依赖属性](04-markup-extensions-dp.md)
