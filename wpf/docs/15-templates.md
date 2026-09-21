# 15 · 模板：ControlTemplate 与 DataTemplate

> 对应示例：`examples/15_templates`（圆角按钮模板 + PersonCard 数据模板三处复用）

> **本章你将学会**：ControlTemplate 重写控件外观、DataTemplate 决定数据长相、TemplateBinding 与 ContentPresenter 的作用、样式与模板的分工。
> **前置章节**：[13 资源与样式](13-styles-resources.md)、[14 触发器](14-triggers.md)。

## 1. 两类模板，两个问题

模板回答两个不同的问题：

| | ControlTemplate | DataTemplate |
|---|---|---|
| 回答 | **控件自己**长什么样 | **数据对象**显示成什么样 |
| 挂在 | Control 的 `Template` 属性 | ItemsControl 的 `ItemTemplate` / ContentControl 的 `ContentTemplate` |
| 例子 | 圆角按钮、自定义滚动条 | Person 显示成"圆点+姓名+年龄"一行 |

第 13 章留了结论"结构在模板里，值在样式里"，本章把两个模板都拆开看。`15_templates` 示例两个实验区正好对应。

## 2. ControlTemplate：重写按钮

默认按钮是"直角灰色矩形 + 系统悬停动效"。想要圆角胶囊按钮，靠改属性永远凑不出来——**外观结构**得整个换掉：

```xml
<ControlTemplate x:Key="RoundButtonTemplate" TargetType="Button">
    <Border x:Name="Chrome" CornerRadius="18"
            Background="{TemplateBinding Background}"
            Padding="{TemplateBinding Padding}">
        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
    </Border>
    <ControlTemplate.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
            <Setter TargetName="Chrome" Property="Opacity" Value="0.85"/>
        </Trigger>
        <Trigger Property="IsPressed" Value="True">
            <Setter TargetName="Chrome" Property="BorderBrush" Value="#0EA5E9"/>
            <Setter TargetName="Chrome" Property="BorderThickness" Value="2"/>
        </Trigger>
        <Trigger Property="IsEnabled" Value="False">
            <Setter TargetName="Chrome" Property="Opacity" Value="0.4"/>
        </Trigger>
    </ControlTemplate.Triggers>
</ControlTemplate>
```

四个零件各自的角色：

| 零件 | 作用 | 少了会怎样 |
|---|---|---|
| `TemplateBinding` | 模板内部引用**控件自身**的属性值（背景、内边距） | 控件上设置的 Background 失效（模板不认识它） |
| `ContentPresenter` | **内容占位符**：Content 在这里渲染 | 按钮文字直接消失（空白按钮第一大原因） |
| 模板触发器 | 悬停/按压/禁用的视觉状态 | 状态反馈全丢 |
| `x:Name` + `TargetName` | 触发器改的是模板内部那个 Border | Setter 不知道改谁 |

**为什么第 13/14 章的 Style 触发器改悬停背景"有时不灵"**：默认按钮模板内部自己画了悬停视觉，Style 层的 Background 被它盖住。重写模板 = 外观主权完全归你——这也解释了第 14 章"样式管值、模板管结构"的分工。

模板通常**装进 Style** 打包复用（结构 + 默认值一起走），示例的两个变体就是"同一模板 + 不同 Background"：

```xml
<Style x:Key="BlueRoundButton" TargetType="Button">
    <Setter Property="Template" Value="{StaticResource RoundButtonTemplate}"/>
    <Setter Property="Background" Value="#3B82F6"/>
    <Setter Property="Foreground" Value="White"/>
    <Setter Property="Padding" Value="20,10"/>
</Style>
<Style x:Key="GreenRoundButton" TargetType="Button" BasedOn="{StaticResource BlueRoundButton}">
    <Setter Property="Background" Value="#10B981"/>   <!-- 只换色，结构复用 -->
</Style>
```

## 3. DataTemplate：数据的长相

第 07 章的伏笔在此兑现：ListBox 绑定一组 `Person`，条目默认显示 `ToString()`。给 `ItemTemplate` 一个 DataTemplate，**每个 Person 按你声明的 UI 渲染**：

```xml
<DataTemplate x:Key="PersonCard">
    <StackPanel Orientation="Horizontal" Margin="0,2">
        <Ellipse Width="10" Height="10">                 <!-- 年龄段圆点 -->
            <Ellipse.Style>
                <Style TargetType="Ellipse">
                    <Setter Property="Fill" Value="#94A3B8"/>
                    <Style.Triggers>
                        <DataTrigger Binding="{Binding AgeGroup}" Value="青年">
                            <Setter Property="Fill" Value="#3B82F6"/>
                        </DataTrigger>
                        <DataTrigger Binding="{Binding AgeGroup}" Value="中年">
                            <Setter Property="Fill" Value="#F59E0B"/>
                        </DataTrigger>
                    </Style.Triggers>
                </Style>
            </Ellipse.Style>
        </Ellipse>
        <TextBlock Text="{Binding Name}" FontWeight="Bold" Margin="8,0,0,0"/>
        <TextBlock Text="{Binding Age, StringFormat='{}（{0} 岁）'}" Foreground="#64748B"/>
        <Border Background="#F1F5F9" CornerRadius="8" Padding="8,1">
            <TextBlock Text="{Binding AgeGroup}" FontSize="11"/>
        </Border>
    </StackPanel>
</DataTemplate>
```

注意 DataTemplate **内部的绑定不写 Source**——条目的 DataContext 自动是**该条目的数据对象**（第 09 章"DataContext 继承"在列表场景的体现），`{Binding Name}` 绑的是 `person.Name`。

`AgeGroup` 是 Person 上"为显示预加工"的派生属性（`Age < 30 ? "青年" : …`）——DataTrigger 只做等值比较，范围判断提前算好，这是模板触发器的标准配套手法（第 17 章再次用到）。

## 4. 同一模板的三处复用

示例的核心实验：**同一个 PersonCard 用在三个控件上**，行为差异全由控件自身决定，模板毫发未动：

```xml
<ListBox ItemsSource="{Binding People}" SelectedItem="{Binding Selected}"
         ItemTemplate="{StaticResource PersonCard}"/>      <!-- 可选中 -->

<ItemsControl ItemsSource="{Binding People}"
              ItemTemplate="{StaticResource PersonCard}"/> <!-- 纯展示 -->

<ContentControl Content="{Binding Selected}"
                ContentTemplate="{StaticResource PersonCard}"/>  <!-- 单对象 -->
```

选中 ListBox 一行，下面的 ContentControl 立刻显示同一个人——**模板只管长相，数据决定内容，控件决定行为**。这三件套的组合（列表 + 详情）是主从界面的最小范式。

## 5. ItemsPanelTemplate：条目容器也换得了

条目默认竖排（ListBox 内置 StackPanel）。第三种模板 `ItemsPanelTemplate` 换掉它：

```xml
<ListBox ItemsSource="{Binding Tags}">
    <ListBox.ItemsPanel>
        <ItemsPanelTemplate>
            <WrapPanel/>          <!-- 标签云：放不下就换行 -->
        </ItemsPanelTemplate>
    </ListBox.ItemsPanel>
</ListBox>
```

ScrollViewer、边框这些"壳"也在控件模板里——`ListBox` 的完整模板 = ScrollViewer + ItemsPresenter + 边框。理解了这个层级，第 06 章"ListBox 自带滚动"就不神秘了。

## 6. 常见坑

**模板丢了 ContentPresenter/ItemsPresenter**：Content 类控件的内容消失、Items 类控件的条目消失——空白按钮/空列表的第一嫌疑。ContentControl 用 ContentPresenter，ItemsControl 用 ItemsPresenter。

**模板里直接写死颜色**：`<Border Background="#3B82F6">`——控件上设置的 Background 失效（被模板无视）。要透传用 `{TemplateBinding Background}`。

**TemplateBinding 用成了 Binding**：TemplateBinding 是单向、编译期优化的简写；模板深处（非直接子元素）它不可用，换 `{Binding RelativeSource={RelativeSource TemplatedParent}}`（等价但更灵活）。

**重写模板后视觉状态不全**：默认模板管悬停/按压/禁用/焦点框，你的新模板没写就是全没有——键盘用户/无障碍直接受损。上面示例至少补 IsMouseOver/IsPressed/IsEnabled 三态。

**DataTemplate 里绑错层级**：模板内 `{Binding Name}` 绑的是**条目数据**的 Name；想绑 ViewModel 的属性要走 `RelativeSource AncestorType=Window`（第 17 章实战示范）。

## 7. 实战建议

- 改外观的升级路径：样式（改值）→ 模板（改结构）→ 自定义控件（改行为）。**九成需求停在样式层**，真正要重写模板时先抄默认模板再改（VS/Blend 可扒出系统默认模板）
- DataTemplate 复用意识：同一数据类型在项目里的"卡片"形态通常统一（列表、详情、下拉），模板抽到资源字典共享
- 模板触发器的状态尽量齐：悬停、按压、禁用三态是底线
- 列表性能：模板保持浅（第 05 章），条目内少用嵌套 Grid 套 Grid；大数据量配虚拟化（`VirtualizingStackPanel.IsVirtualizing`，第 18 章）

## 自测

1. **ControlTemplate 与 DataTemplate 各回答什么问题？** —— 控件自己长什么样 vs 数据对象显示成什么样。
2. **模板里 `{TemplateBinding Background}` 和 `<ContentPresenter/>` 各干什么？** —— 前者把控件自身属性值透传进模板；后者是内容占位符，Content 在此渲染。
3. **为什么重写模板后必须补悬停/按压效果？** —— 默认视觉状态住在默认模板里，换模板等于全盘接管。
4. **DataTemplate 内部 `{Binding Name}` 的源是谁？** —— 当前条目的数据对象（DataContext 自动切到条目）。

---
上一章：[14 触发器](14-triggers.md) ｜ 下一章：[16 数据验证](16-validation.md)
