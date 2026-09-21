# 14 · 触发器：条件驱动的界面

> 对应示例：`examples/14_triggers`（四类触发器对照实验）

> **本章你将学会**：属性/多条件/数据/事件四类触发器的写法与选型、触发器与本地值的优先级关系、用 DataTrigger 做"零代码换肤"。
> **前置章节**：[13 资源与样式](13-styles-resources.md)。

## 1. 触发器解决什么问题

样式给的是**静态值**——"按钮是蓝的"。真实界面充满**条件**："聚焦时边框高亮""勾选夜间模式后整个面板变暗""鼠标悬停时按钮加深"。触发器（Trigger）就是**写在样式里的条件赋值**：

```xml
<Style x:Key="FocusHintTextBox" TargetType="TextBox">
    <Setter Property="Padding" Value="6,4"/>                    <!-- 默认值 -->
    <Style.Triggers>
        <Trigger Property="IsKeyboardFocusWithin" Value="True"> <!-- 条件 -->
            <Setter Property="Background" Value="#FFFBEB"/>     <!-- 条件成立时改值 -->
            <Setter Property="BorderBrush" Value="#F59E0B"/>
        </Trigger>
    </Style.Triggers>
</Style>
```

条件成立 → Setter 生效；条件消失 → **自动还原**（不用写"else"）。这个"自动回滚"是触发器相对事件处理的本质优势：`GotFocus`/`LostFocus` 两个事件干的事，一个触发器全包，还没有状态残留。

## 2. 四类触发器选型表

| 触发器 | 条件来源 | 典型用途 |
|---|---|---|
| `Trigger` | **自身依赖属性**的值 | IsMouseOver、IsKeyboardFocusWithin、IsChecked |
| `MultiTrigger` / `MultiDataTrigger` | 多个条件**同时**满足 | "悬停**且**可用" |
| `DataTrigger` | **绑定表达式的值** | ViewModel 状态驱动外观 |
| `EventTrigger` | 事件发生 | 配合动画（第 20 章主场） |

前三类是"状态条件"，第四类是"动作触发"——**EventTrigger 里只能放动画/故事板**，不能放 Setter（想"点击后变色"用属性触发器或代码）。

### MultiTrigger：条件的与运算

```xml
<MultiTrigger>
    <MultiTrigger.Conditions>
        <Condition Property="IsMouseOver" Value="True"/>
        <Condition Property="IsEnabled" Value="True"/>
    </MultiTrigger.Conditions>
    <Setter Property="Background" Value="#1D4ED8"/>
</MultiTrigger>
```

"悬停且可用才加深"——禁用态的按钮悬停不变色，细节就靠这种与条件。`MultiDataTrigger` 同理，条件换成 Binding。

### DataTrigger：数据驱动的零代码换肤

`14_triggers` 示例的第 3 区是最能体现 WPF 威力的一幕：一个 CheckBox 切换"夜间模式"，面板背景和文字颜色两个 DataTrigger 同时响应，**代码后置零行**：

```xml
<CheckBox x:Name="DarkBox" Content="夜间模式"/>

<Border CornerRadius="8" Padding="16">
    <Border.Style>
        <Style TargetType="Border">
            <Setter Property="Background" Value="#F1F5F9"/>     <!-- 默认：浅色 -->
            <Style.Triggers>
                <DataTrigger Binding="{Binding IsChecked, ElementName=DarkBox}" Value="True">
                    <Setter Property="Background" Value="#1E293B"/>   <!-- 夜间：深色 -->
                </DataTrigger>
            </Style.Triggers>
        </Style>
    </Border.Style>
    <!-- 内部 TextBlock 同样用 DataTrigger 切换 Foreground -->
</Border>
```

条件可以是任意绑定：`ElementName`（本例）、ViewModel 属性（MVVM 标配）、甚至转换器加工后的值。**MVVM 的黄金搭档**：VM 只负责暴露 `IsOnline`、`IsDirty` 这样的状态，外观反应全在 XAML 里声明——第 25 章实战用 DataTrigger 把 `IsWordWrap`（bool）映射成 `TextWrapping`（枚举），一个转换器类都省了。

DataTrigger 只做**等值比较**（Value 等于绑定值）。范围判断（"薪水 ≥ 18000 标蓝"）不在触发器能力内——在数据端预加工成派生属性（第 17 章的 `IsHighSalary` 手法）。

## 3. 最重要的规则：触发器输给本地值

第 04 章的值优先级表在此兑现——**触发器（样式层）的优先级低于本地值**：

```xml
<!-- ✘ 反例：本地值压死触发器，悬停永远不变色 -->
<TextBox Background="White" Style="{StaticResource FocusHintTextBox}"/>

<!-- ✓ 正解：默认值写进 Style 的 Setter，触发器才管得动 -->
<TextBox Style="{StaticResource FocusHintTextBox}"/>
```

推论一句话：**想让触发器管的属性，它的"默认值"必须住在 Style 里，不能写在元素上**。这也是示例把 Border 底色写在 `Border.Style` 内部的原因——写在 Border 特性上，DataTrigger 立刻失效（还是静默的）。

## 4. EnterActions/ExitActions 与模板触发器

触发器还有两处进阶用法，认识即可：

- **EnterActions / ExitActions**：条件成立/消失时执行的动作（多为动画）——比 EventTrigger 多了"消失时"的钩子
- **模板触发器**：`ControlTemplate.Triggers` 写在模板内部（第 15 章示例用它做按钮的悬停/按压效果），能力与样式触发器相同，作用域是模板内部元素（可以 `TargetName` 指到模板里的 Border）

复杂控件的视觉状态（悬停、按压、禁用、选中）官方方案是 **VisualStateManager**（状态 + 过渡动画），WinUI/MAUI 已全面采用；WPF 里模板触发器仍是主流写法。知道两条路线的存在即可，跟教程走触发器。

## 5. 触发器 vs 转换器 vs 代码

同一个需求三条路（"bool → 颜色"）：

| 方案 | 写法 | 适用 |
|---|---|---|
| DataTrigger | XAML 声明 | 值是**离散**的（true/false、几个枚举） |
| 转换器 | C# 类 | 需要计算/格式化（第 10 章） |
| 代码 | 事件/命令里改属性 | 有副作用的联动（改了 A 还要触发 B 的动作） |

优先级从上到下：**能声明就不写类，能写类就不写代码**。声明式方案可逆、可组合、没有状态残留。

## 6. 常见坑

**触发器不生效，属性被本地值压住**：第一大坑，第 3 节。判据：触发器"条件明明成立但外观没变"——查该属性是否被元素特性直写过。

**DataTrigger 比较方向误解**：`Value` 是"期待值"，绑定值**等于**它才成立。想比较大小/包含，回数据端加工。

**Trigger 的 Property 必须是依赖属性**：自定义类的普通属性放 `Trigger Property=` 无效；DataTrigger 走绑定倒是能绑普通属性（要 INPC）。

**EventTrigger 里写 Setter**：直接编译错误——EventTrigger 只收动作（BeginStoryboard 等）。

**多触发器互相打架**：两个 Trigger 都改 Background 且条件同时成立——按声明顺序后者胜。别让条件区间重叠，或显式排好顺序。

## 7. 实战建议

- 表单的聚焦高亮、悬停反馈、禁用置灰这类"控件状态 → 外观"一律 Trigger；"数据状态 → 外观"一律 DataTrigger
- 主题配色类的"模式切换"照抄示例第 3 区的结构：一个状态源 + N 个 DataTrigger，零代码后置
- 触发器条件超过 3 个、或需要链式联动时，改写代码——声明式也有复杂度上限
- XAML 改外观卡住时先画"值从哪来"的优先级链（本地值 → 触发器 → Setter → 继承 → 默认），九成问题在链上

## 自测

1. **触发器相对事件处理的核心优势？** —— 条件消失自动还原（无 else、无状态残留），且声明在 XAML。
2. **想让触发器管的属性，默认值应该写在哪？为什么？** —— Style 的 Setter 里；本地值优先级高于触发器，写在元素上会压死触发器。
3. **DataTrigger 的条件是绑定的 bool 值，想按数值范围变色怎么办？** —— DataTrigger 只做等值比较；数据端预加工派生属性（bool）再触发。
4. **EventTrigger 与其他三类的本质区别？** —— 它是"事件发生"触发动作（动画），不是"状态条件"改值，不能放 Setter。

---
上一章：[13 资源与样式](13-styles-resources.md) ｜ 下一章：[15 模板](15-templates.md)
