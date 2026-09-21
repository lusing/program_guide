# 06 · 布局实战：自适应、滚动与缩放

> 对应示例：`examples/06_layout_lab`（四个布局实验页）

> **本章你将学会**：SharedSizeGroup 跨网格对齐、ScrollViewer 的滚动策略、Viewbox 整体缩放、窗口与内容的自适应配合。
> **前置章节**：[05 布局系统](05-layout.md)。

## 1. 本章解决什么问题

第 05 章的面板规则背熟了，真实界面还是会有四类"结构性"问题：

1. 界面拆成多个 Grid 后，**标签列对不齐**了
2. 内容比窗口**高/宽**，需要滚动
3. 固定尺寸的图形/面板希望**整体等比缩放**而不是重排
4. 希望窗口**按内容自适应大小**，或内容自适应窗口

这四个问题各有专属工具：`SharedSizeGroup`、`ScrollViewer`、`Viewbox`、`SizeToContent`/`MinWidth`。`06_layout_lab` 示例做成四个实验页（顺便认识 TabControl），拖动窗口大小就能看到每个机制的行为。

## 2. SharedSizeGroup：跨 Grid 的列对齐

多行表单里最烦的事：每行一个 Grid，标签列宽各不相同，输入框参差不齐。`SharedSizeGroup` 让**不同 Grid 里的列共享宽度**：

```xml
<!-- ① 外层声明"共享尺寸作用域" -->
<StackPanel Grid.IsSharedSizeScope="True">
    <!-- ② 行一：标签列加入 shared 组 -->
    <Grid Margin="0,0,0,6">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto" SharedSizeGroup="label"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <TextBlock Text="姓名：" FontWeight="Bold"/>
        <TextBox Grid.Column="1" Text="王小明"/>
    </Grid>
    <!-- ③ 行二、行三同样声明 SharedSizeGroup="label" -->
    <!--    标签列宽度 = 三行里最宽的那个，自动对齐 -->
</StackPanel>
```

要点三条：作用域开关 `Grid.IsSharedSizeScope="True"` 挂在**公共祖先**上；参与共享的列必须 `Width="Auto"`；同名组内取最宽。注意它的对齐只在**声明方向**生效（列宽共享），行高同理换 RowDefinition。

与"一个大 Grid 摊平所有行"的方案对比：SharedSizeGroup 允许每行是独立 Grid（局部可以有自己的 Margin/结构），宏观又保持对齐——组件化界面（UserControl 拼表单）时的标准做法。

## 3. ScrollViewer：滚动的正确姿势

`ScrollViewer` 只做一件事：内容比视口大时提供滚动条。

```xml
<ScrollViewer VerticalScrollBarVisibility="Auto"
              HorizontalScrollBarVisibility="Disabled">
    <WrapPanel x:Name="ChipPanel"/>   <!-- 50 个彩色标签，宽度不够自动折行 -->
</ScrollViewer>
```

`ScrollBarVisibility` 四个值的语义：

| 值 | 行为 |
|---|---|
| `Auto`（默认） | 需要时才显示 |
| `Visible` | 永远显示 |
| `Hidden` | 不显示但**仍可滚**（滚轮/触控） |
| `Disabled` | 不显示且**禁滚**（该方向尺寸被视为无限→子元素按需展开） |

`Disabled` 值得专门理解：横向 Disabled 时，内容被给予**无限宽**，TextBlock 才会按需换行（配 TextWrapping）而不是横向撑爆。WPF 自带的 TextBox、ListBox 内部就各有自己的 ScrollViewer（`ScrollViewer` 是模板零件，第 15 章呼应）。

**StackPanel + ScrollViewer 的组合坑**：竖排 StackPanel 报告的 DesiredHeight 是全部内容之和，套 ScrollViewer 能滚没错；但 StackPanel 里再放 `*` 高度的元素还是不行（第 05 章的无限空间规则不因外层滚动而改变）。需要"滚动 + 内部按比例分配"时，滚动壳里装 Grid。

## 4. Viewbox：整体等比缩放

`Viewbox` 把固定尺寸的子内容当作一张"图片"整体缩放——内容**不重排**，只是变形地放大缩小：

```xml
<Viewbox x:Name="ScaleBox" Stretch="Uniform">
    <StackPanel Width="300" Height="120" Background="AliceBlue">
        <TextBlock Text="我是 300×120 的固定面板" FontSize="16" HorizontalAlignment="Center"/>
    </StackPanel>
</Viewbox>
```

`Stretch` 三种模式：`Uniform`（等比，留白）、`Fill`（拉伸填满，会变形）、`None`（不缩放，超出被裁剪）。示例里用三个 RadioButton 切换对比。

适用场景：仪表盘、K线图、固定版式的看板——设计稿是 800×600，屏幕可大可小，整体缩放保比例。**不适用**：文字为主的表单/列表——字体忽大忽小的观感很差，这类界面要的是重排（Grid/`*`），不是缩放。

顺带认识 `StretchDirection="UpOnly"`（只放大不缩小）等属性，按需查手册即可。

## 5. 窗口自适应内容：SizeToContent

默认窗口尺寸由 `Width/Height` 写死。改成"按内容收放"：

```xml
<Window SizeToContent="WidthAndHeight" ...>   <!-- 也取 Width / Height -->
```

对话框（消息框类）常用 `Width`：高度按内容、宽度固定，避免文字长时窗口被撑成一条横幅。配合 `MaxWidth` 防止内容异常时窗口爆屏。

反向的"内容自适应窗口"就是第 05 章的 `*` 与 Stretch 体系——两个方向都掌握后，窗口与内容的尺寸关系就全在你手里了。

示例第 4 页还演示了 `MinWidth`/`MinWidth` 加在 ColumnDefinition 上的效果：`1*` 的列有下限，窗口过窄时不再继续压缩，星号分配到 0 也不塌陷。

## 6. 布局调试心法

布局不对时的排查顺序（经验值，按命中率排）：

1. **画层级图**：Window → 面板 → 面板 → 控件，逐层写清楚每层的对齐/边距——一半问题在画图时就暴露了
2. 查**默认 Stretch**：谁被拉高/拉宽了，基本是它
3. 查**Grid.Row/Column 是否漏写**（默认 0，叠加）
4. 查**StackPanel 无限空间**：拉伸失效、不滚动，都是它
5. 临时给面板加 `Background` 上色——**看不见的容器一眼现形**，层级结构立刻清晰（调试完记得删）

第 5 招是布局调试第一神器：`Background="Red"` 一下，谁占多大地方清清楚楚。

## 7. 常见坑

**SharedSizeGroup 不生效**：三查——祖先是否挂了 `Grid.IsSharedSizeScope="True"`；列是否 `Width="Auto"`；组名拼写是否一致（大小写敏感，静默失败）。

**ScrollViewer 套在窗口最外层导致菜单也滚走**：滚动区应该只包"内容区"，别把整个窗口骨架（菜单/状态栏）都滚进去。骨架用 Grid 分行，只有内容行滚动。

**Viewbox 里的文字模糊/巨大**：Viewbox 缩的是整个渲染结果，不是字体——版式类界面改用重排；模糊是极度放大位图化的观感，正常。

**SizeToContent 窗口闪跳**：内容异步加载（图片/数据）到达时窗口被撑大跳动。加载完成前给内容固定 MinHeight 占位。

**ScrollbarVisibility=Hidden 想裁剪**：Hidden 仍可滚不裁剪；要"裁掉且不可滚"用 Disabled + 固定容器尺寸（或 ClipToBounds）。

## 8. 实战建议

- 表单类界面：外层 Grid 分行，每行一个"标签 + 输入"小 Grid，标签列 SharedSizeGroup——三种工具各司其职
- 内容区滚动做成骨架的一部分：`<ScrollViewer Grid.Row="1">`，让标题和状态栏钉死
- Viewbox 只给"图形化、固定版式"的内容；文字流界面永远走重排路线
- 上线前把窗口拉到极小（200×100）和极大（2560 宽）各过一遍——MinWidth/MinHeight 是给极端尺寸兜底的，别裸奔

## 自测

1. **SharedSizeGroup 需要哪三个条件才生效？** —— 祖先 IsSharedSizeScope=True、列 Width=Auto、组名一致。
2. **ScrollBarVisibility 的 Hidden 与 Disabled 差在哪？** —— Hidden 隐藏但可滚；Disabled 禁滚且该方向可用尺寸无限。
3. **Viewbox 和 Grid 的 `*` 都能"自适应"，本质区别？** —— Viewbox 是整体等比缩放（不重排）；Grid 是重新协商布局（内容重排）。
4. **对话框想让高度随内容、宽度固定，怎么写？** —— `SizeToContent="Height"` + `Width="固定值"`。

---
上一章：[05 布局系统](05-layout.md) ｜ 下一章：[07 核心控件一览](07-controls.md)
