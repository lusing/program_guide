# 03 · XAML 语言：标记扩展与对象树

> 对应示例：`examples/01_hello_wpf`（复用）

## 1. XAML 是什么

XAML 不是模板语言，它**是对象图的声明式写法**：每个元素 = 一个对象，每个属性 = 一次赋值，嵌套 = 对象树。编译时 XAML 被转成 BAML 嵌进程序集，运行时由解析器构建真实对象——所以"XAML 里能写什么"完全由"对象有哪些属性"决定，没有一丝超自然能力。

同一个按钮的三种等价写法，感受一下映射关系：

```xml
<Button Background="Red" Content="确定" />           <!-- 属性特性 -->
```

```xml
<Button Content="确定">                               <!-- 属性元素 -->
    <Button.Background>Red</Button.Background>
</Button>
```

```csharp
var b = new Button { Background = Brushes.Red, Content = "确定" };   // 纯 C#
```

`Background="Red"` 能成立靠的是 **TypeConverter**：XAML 里一切属性值都是字符串，`Red` 由 BrushConverter 转成 SolidColorBrush，`Width="220"` 转成 double。没有对应转换器的复杂类型就得用属性元素语法展开。

## 2. 两套命名空间

每个 XAML 根元素上的两行 xmlns 是固定搭配：

```xml
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"   ← 默认：WPF 全部控件
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"              ← x: 前缀：XAML 语言自身
```

默认命名空间把几十个 WPF 命名空间（`System.Windows.Controls` 等）打包映射成"无前缀"，所以 `<Button>`、`<Grid>` 直接写。`x:` 前缀是语言特性：`x:Class`（连到哪个类）、`x:Name`（生成字段）、`x:Key`（资源字典键）、`x:Static`（取静态成员）。要用自己的类再追加一个命名空间映射，如 `xmlns:local="clr-namespace:MyApp"`。

## 3. 标记扩展：花括号的魔法

`{...}` 开头的值是标记扩展（MarkupExtension）——把"取值"委托给一个可编程对象。高频的五个：

| 扩展 | 作用 | 详见 |
|---|---|---|
| `{Binding ...}` | 绑定到数据 | 第 06 章 |
| `{StaticResource key}` | 查资源字典（编译时一次性） | 第 08 章 |
| `{DynamicResource key}` | 查资源字典（运行时跟随变化） | 第 08 章 |
| `{x:Static local:Foo.Bar}` | 取静态字段/属性/枚举 | — |
| `{x:Null}` | 显式赋 null（覆盖继承值） | — |

绑定错误是静默的：Path 打错、DataContext 为 null，界面只显示空白，输出窗口里有一行警告。这是 XAML 学习期最大的挫败感来源——**跑起来后先看"输出"面板**。

## 4. 集合语法与内容属性

`StackPanel` 里能直接写子元素，是因为它把 `Children`（一个 UIElementCollection）标记成了**内容属性**：

```xml
<StackPanel>
    <TextBlock Text="第一行" />
    <Button Content="按钮" />
</StackPanel>
<!-- 等价于 <StackPanel><StackPanel.Children>…展开…</StackPanel.Children></StackPanel> -->
```

`Grid` 的 `RowDefinitions`、`Menu` 的 `Items` 同理。理解了这一点，XAML 里"元素套元素"就不再是语法，而是对象构造。

## 5. x:Name 与 Name

`x:Name="NameTextBox"` 做两件事：① 在生成的分部类里建同名字段；② 给对象注册逻辑名，供 `{ElementName=...}` 绑定和 `FindName` 查找。`Name` 是多数控件上的便捷别名（框架属性），两者几乎总可互换。

hello 示例里事件处理直接用 `NameTextBox.Text`，走的就是生成字段这条路。

## 6. 依赖属性初识

普通 C# 属性是"字段加壳"；依赖属性（DependencyProperty）则是**把值的存放外包给 WPF 的属性系统**，换来一整批能力：

- **数据绑定**：值可以被绑定表达式驱动（普通属性做不到）
- **样式与触发器**：Style/Trigger 能批量设值、条件改值
- **动画**：动画系统可以插值驱动它
- **值继承**：`FontSize`、`DataContext` 沿树继承
- **优先级合成**：同一个属性可能同时被样式、动画、本地值"想要"，系统按固定优先级裁决（动画 > 本地值 > 样式 > 继承 > 默认）

规则一句话：**要被绑定/样式/动画驱动的属性，必须是依赖属性**。这也是第 06 章里"ViewModel 普通属性 + INPC"与"控件依赖属性"分工的原因：绑定目标是依赖属性，绑定源只需要 INPC 通知。

## 7. 常见坑

**XAML 区分大小写**：`<button>` 直接编译错误。属性值不区分（`Red`/`red` 都行），元素和属性名区分。

**标记扩展的字符串引号**：`StringFormat='Hello, {0}!'` 里外层双引号内层单引号，混用会解析失败；格式串以 `{` 开头时前面要加 `{}` 转义，如 `StringFormat={}{0:N2}`。

**x:Name 找不到字段**：XAML 改了名但没重新生成（字段在 obj 的 .g.cs 里），先 Rebuild。

**绑定静默失败**：详见上一节。开发期挂上跟踪：`PresentationTraceSources.Refresh(); PresentationTraceSources.DataBindingSource.Switch.Level = SourceLevels.Warning;`

**Content 里写文本与控件的混淆**：`<Button>确定</Button>` 与 `<Button Content="确定"/>` 等价（内容属性是 Content），但 `<Button>123</Button>` 的 Content 是字符串 "123"，而 `Content="{Binding Count}"` 的 Content 是数字——显示格式要用 StringFormat 控制。

## 8. 实战建议

- 简单属性用特性语法，复杂对象用属性元素语法——两者混用是常态，别追求全特性
- 会改 XAML 也要会"从 XAML 反推 C#"：`new Button { Content = ..., Background = ... }`，第 11 章导航示例有纯 C# 构建界面的对照
- 自定义类型要在 XAML 里用，先加 xmlns 映射；找不到类型是编译期错误，比绑定错误友好得多
- 数字/尺寸用 TypeConverter 直接写，颜色能用名字就写名字（`AliceBlue`），需要精确值再写 `#3B82F6`

---
上一章：[02 应用骨架与生命周期](02-app-lifecycle.md) ｜ 下一章：[04 布局系统](04-layout.md)
