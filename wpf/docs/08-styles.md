# 08 · 样式、触发器与模板

> 对应示例：`examples/05_styles`

## 1. 资源系统：样式的存放地

WPF 里"可复用的对象"都放**资源字典**（`Resources`），按键查找。查找链沿逻辑树向上：

```text
元素自己的 Resources → 父元素 → …… → Window.Resources → App.Resources → 系统主题
```

所以窗口级定义、全窗口可用；App 级定义、全程序可用。取用有两种，区别值得背下来：

| | StaticResource | DynamicResource |
|---|---|---|
| 解析时机 | 加载时查一次，值定死 | 保留引用，资源变了跟着变 |
| 性能 | 快 | 略慢（维护引用） |
| 前向引用 | 不允许（先定义后使用） | 允许 |
| 典型场景 | 样式、画刷 | 运行时换主题/换语言 |

## 2. Style：一组 Setter 的打包

`05_styles` 示例定义了一个按钮样式：

```xml
<Window.Resources>
    <Style x:Key="PrimaryButtonStyle" TargetType="Button">
        <Setter Property="Background" Value="#3B82F6"/>
        <Setter Property="Foreground" Value="White"/>
        <Setter Property="FontWeight" Value="Bold"/>
        <Setter Property="Padding" Value="14,8"/>
        <Setter Property="Margin" Value="0,0,12,0"/>
    </Style>
</Window.Resources>

<Button Content="保存" Style="{StaticResource PrimaryButtonStyle}"/>
```

三个要点：

- **TargetType 必写**：Setter 的属性名按它校验，写错编译期就能发现
- **隐式样式**：`x:Key` 省略时，样式自动作用于该窗口内**所有** TargetType 元素——批量统一外观用这招
- **BasedOn**：`BasedOn="{StaticResource 基样式}"` 继承扩展，代替复制粘贴

## 3. Trigger：条件样式

样式只能设静态值，"鼠标悬停变深"要靠触发器：

```xml
<Style.Triggers>
    <Trigger Property="IsMouseOver" Value="True">
        <Setter Property="Background" Value="#2563EB"/>
    </Trigger>
</Style.Triggers>
```

| 触发器 | 条件 | 典型用途 |
|---|---|---|
| `Trigger` | 依赖属性的值 | IsMouseOver、IsChecked |
| `DataTrigger` | **绑定表达式的值** | ViewModel 状态驱动外观 |
| `MultiDataTrigger` | 多个绑定条件同时满足 | 组合条件 |
| `EventTrigger` | 事件发生 | 配合动画 |

`DataTrigger` 是 MVVM 的好搭档——**ViewModel 只给状态，外观反应全在 XAML**。第 12 章实战项目用它把 `IsWordWrap`（bool 状态）映射成 TextBox 的 `TextWrapping`（枚举），不用写转换器：

```xml
<Style.Triggers>
    <DataTrigger Binding="{Binding IsWordWrap}" Value="True">
        <Setter Property="TextWrapping" Value="Wrap"/>
    </DataTrigger>
</Style.Triggers>
```

一个重要规则：触发器优先级**低于本地值**。XAML 里直接写了 `Background="Red"`，任何 Trigger 都改不动它——触发器要生效，这个属性必须由样式管辖。

## 4. ControlTemplate：控件外观的整个重写

样式改属性，模板**重写控件的视觉结构**。示例里把按钮改成圆角：

```xml
<Setter Property="Template">
    <Setter.Value>
        <ControlTemplate TargetType="Button">
            <Border Background="{TemplateBinding Background}"
                    CornerRadius="6" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Center"
                                  VerticalAlignment="Center"/>
            </Border>
        </ControlTemplate>
    </Setter.Value>
</Setter>
```

拆开看四个零件：

| 零件 | 作用 |
|---|---|
| `TemplateBinding` | 从模板内部引用控件自身的属性值（Background、Padding） |
| `ContentPresenter` | **内容占位**：Content（含上面的例子里的 UI 子树）在这里渲染 |
| 触发器 | 模板里也可以带 Triggers（模板触发器） |
| 视觉状态 | 复杂控件用 VisualStateManager 管理状态动画 |

**为什么默认按钮的悬停变色必须进模板**：默认 Button 的背景色其实是模板内部 Border 画的，Style 改 Button.Background 悬停时被模板内部的默认视觉覆盖——这正是模板与样式的分工：**结构在模板里，值在样式里**。示例把 Template 放进 Style 的 Setter 里，就是"值 + 结构"一起打包复用。

## 5. 样式 vs 模板 vs DataTemplate

| | 解决什么 | 键 |
|---|---|---|
| Style | 一组属性值 + 条件改值 | `x:Key` / 隐式 |
| ControlTemplate | 控件**自己**长什么样 | 通常装在 Style 里 |
| DataTemplate | **数据对象**显示成什么样 | 用于 ItemsSource 条目 |

第 05 章埋的伏笔在这兑现：`ListBox` 绑定一组 `Person` 时，条目默认显示 ToString；给 `ItemTemplate` 一个 DataTemplate，每个 Person 就按你声明的 UI 渲染——**数据不变，外观任写**，这是"内容是任意对象"的完整闭环。

## 6. 常见坑

**StaticResource 找不到**：查找链走不到（定义在使用点之后/别的字典里），报运行时异常。App 级通用资源放 App.Resources。

**模板丢了 ContentPresenter**：内容直接消失——模板里没写 `ContentPresenter`，Content 无处渲染。空白按钮多半是它。

**触发器被本地值压制**：第 3 节的规则。想要"默认值 + 触发器改值"，默认值写进 Style 的 Setter，**别写在元素上**。

**样式写一半忘 TargetType**：Setter 属性名报"找不到"。

**过度模板化**：只改圆角和颜色用 Style 就够；重写模板意味着**自己负责所有视觉状态**（悬停、按下、禁用），工作量大增。

## 7. 实战建议

- 通用外观抽到 App.Resources 或独立 ResourceDictionary（`App.xaml` 里 `MergedDictionaries` 合并），窗口内一次性外观留在窗口
- 命名样式按"角色"不按外观：`PrimaryButtonStyle` 优于 `BlueButtonStyle`——换主题时名字不用改
- MVVM 项目里，显示逻辑优先级：`StringFormat` → DataTrigger → 转换器（第 06 章）；能用触发器就别写转换器类
- 第 12 章实战项目的界面只有几十行 XAML，靠 DataTrigger 和隐式样式撑起全部外观，可以作为"样式够用论"的参照

---
上一章：[07 MVVM 与命令](07-mvvm-commands.md) ｜ 下一章：[09 异步与后台任务](09-async.md)
