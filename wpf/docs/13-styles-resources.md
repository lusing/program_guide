# 13 · 资源与样式

> 对应示例：`examples/13_styles`（按钮样式 + BasedOn 继承）

> **本章你将学会**：资源字典与查找链、StaticResource 与 DynamicResource 的选择、Style 的三种复用方式。
> **前置章节**：[04 依赖属性](04-markup-extensions-dp.md)、[12 命令](12-commands.md)。

## 1. 资源系统：可复用对象的存放地

WPF 里"可复用的对象"（样式、画刷、模板、转换器实例）都放**资源字典（ResourceDictionary）**，`x:Key` 是键，`StaticResource`/`DynamicResource` 按键取用：

```xml
<Window.Resources>
    <SolidColorBrush x:Key="AccentBrush" Color="#3B82F6"/>   <!-- 资源：一个画刷对象 -->
    <Style x:Key="PrimaryButtonStyle" TargetType="Button">...</Style>
</Window.Resources>

<Button Background="{StaticResource AccentBrush}" .../>
```

**查找链沿逻辑树向上**，这就是"作用域"：

```text
元素自己的 Resources → 父元素 Resources → …… → Window.Resources → App.Resources → 系统主题
```

所以：窗口级定义、全窗口可用；**App 级定义、全程序可用**（换主题的全局颜色就放这）。同一个键可以就近覆盖——子级定义同名键会遮蔽上级（理解了第 09 章 DataContext 继承，这里的机制是同一套"沿树向上找"）。

## 2. StaticResource 与 DynamicResource

两种取法一字之差，行为不同：

| | StaticResource | DynamicResource |
|---|---|---|
| 解析时机 | 加载时查一次，值**定死** | 保留引用，资源变了**跟着变** |
| 性能 | 快 | 略慢（要维护引用链） |
| 前向引用 | 不允许（先定义后使用） | 允许 |
| 典型场景 | 样式、画刷、模板 | 运行时换主题/换语言 |

选择口诀：**默认 Static，只在"资源会被替换"时 Dynamic**。换肤场景是 Dynamic 的主场：App.Resources 里 `AccentBrush` 换一个新对象，全程序引用它的地方立刻变色——Static 做不到（值已拷走）。

前向引用的坑具体化：同一个字典里，Style A `BasedOn` 写在它后面的 Style B——StaticResource 直接报"找不到资源"；DynamicResource 能过。所以**资源声明顺序很重要**：被依赖的放前面。

## 3. Style：一组 Setter 的打包

样式 = 一组"属性 = 值"的打包，配给目标类型。`13_styles` 示例的主样式：

```xml
<Style x:Key="PrimaryButtonStyle" TargetType="Button">
    <Setter Property="Background" Value="#3B82F6"/>
    <Setter Property="Foreground" Value="White"/>
    <Setter Property="FontWeight" Value="Bold"/>
    <Setter Property="Padding" Value="14,8"/>
    <Setter Property="Margin" Value="0,0,12,0"/>
</Style>
```

```xml
<Button Content="保存" Style="{StaticResource PrimaryButtonStyle}"/>
```

三个要点：

- **TargetType 必写**：Setter 的属性名按它校验，拼错编译期就报（比绑定错误友好）
- **隐式样式**：省略 `x:Key` 时，样式自动作用于**该作用域内所有** TargetType 元素——批量统一外观：

```xml
<Style TargetType="Button">          <!-- 无 x:Key：所有 Button 都归它管 -->
    <Setter Property="Padding" Value="14,8"/>
</Style>
```

- **BasedOn 继承**：公共部分抽基样式，变体只写差异（示例里蓝/绿两个按钮共用一套结构）：

```xml
<Style x:Key="GreenButtonStyle" TargetType="Button" BasedOn="{StaticResource PrimaryButtonStyle}">
    <Setter Property="Background" Value="#10B981"/>   <!-- 只覆盖颜色，其余继承 -->
</Style>
```

## 4. 样式的边界：改不了"结构"

Style 能做的是**给属性赋值**（含默认值和条件值）。它管不了两件事：

1. **控件内部长什么样**——默认按钮的圆角、悬停动效是模板（ControlTemplate）画的，Style 改 Background 在部分主题下会被模板内部视觉盖住。要"圆角按钮、渐变按钮"得重写模板（第 15 章）
2. **数据的展示形态**——列表条目怎么排版是 DataTemplate 的事（第 15 章）

一句话分工：**值在样式里，结构在模板里**。样式解决"统一属性"，模板解决"重画长相"。

## 5. 组织大项目的资源

界面多了以后，全塞 App.xaml 会失控。标准做法：**独立资源字典文件 + 合并**：

```text
Themes/
├── Colors.xaml      颜色画刷
├── Buttons.xaml     按钮样式（引用 Colors.xaml 的画刷）
└── Text.xaml        文本样式
```

```xml
<!-- App.xaml -->
<Application.Resources>
    <ResourceDictionary>
        <ResourceDictionary.MergedDictionaries>
            <ResourceDictionary Source="Themes/Colors.xaml"/>
            <ResourceDictionary Source="Themes/Buttons.xaml"/>
        </ResourceDictionary.MergedDictionaries>
    </ResourceDictionary>
</Application.Resources>
```

被合并字典的顺序 = 查找优先级（后面的遮蔽前面的）。主颜色抽成 `Colors.xaml` 里的画刷资源，全部样式引用它——**换主题只改这一个文件**。

## 6. 常见坑

**StaticResource 找不到（运行时异常）**：`XamlParseException: 无法找到名为…的资源`。三查：键名拼写、定义是否在使用点**之后**（前向引用不允许）、是否在别的未合并的字典里。

**隐式样式对 Window 不生效**：Window 的隐式样式查找有特例（不沿树找 App 级隐式样式），显式给 Window 写 `Style="{StaticResource ...}"` 即可。

**样式写了一半忘 TargetType**：Setter 的 Property 无从校验，报"属性找不到"。TargetType 是免费的安全网。

**BasedOn 链太长**：三四层继承后，改基样式牵动全身且难排查——继承控制在两层内，差异大就平铺两个样式。

**在元素上又写了一遍属性**：`<Button Style="..." Background="Red"/>`——本地值优先级高于样式（第 04 章），样式值全部失效，还以为是样式坏了。

## 7. 实战建议

- 起步阶段"窗口级样式"够用；第二个窗口出现重复样式时，升级到独立字典文件——重构信号明确
- 命名按**角色**不按外观：`PrimaryButtonStyle` 优于 `BlueButtonStyle`——换主题时名字不用改，语义才是稳定的
- 通用色一律 `x:Key` 的画刷资源，XAML 里**禁止裸写色值**（`#3B82F6` 只允许出现在 Colors.xaml）——这是可维护性的分水岭
- 隐式样式慎用：它影响作用域内全部同类控件，全局隐式样式 + 个别特殊按钮 = 排查地狱。批量统一用它，个性化用显式样式

## 自测

1. **资源查找链的顺序？App 级资源的价值？** —— 沿逻辑树向上直到 App.Resources 再到系统主题；全局可用、换主题集中修改。
2. **StaticResource 与 DynamicResource 怎么选？** —— 默认 Static；资源会被运行时替换（换肤/换语言）才 Dynamic。
3. **样式省略 x:Key 会发生什么？** —— 变隐式样式，作用于作用域内所有 TargetType 元素。
4. **样式改不动按钮的悬停外观，为什么？** —— 悬停视觉在控件模板内部，样式只管赋属性值——第 15 章重写模板解决。

---
上一章：[12 命令系统](12-commands.md) ｜ 下一章：[14 触发器](14-triggers.md)
