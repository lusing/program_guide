# 05 · 布局系统：面板与尺寸协商

> 对应示例：`examples/05_layout`（三行骨架 + 嵌套拆解）

> **本章你将学会**：WPF 布局的两遍协商机制、六种面板的选型、Grid 的三种尺寸、对齐与边距。
> **前置章节**：[03 XAML 基础](03-xaml-basics.md)、[04 附加属性](04-markup-extensions-dp.md)。

## 1. 布局是协商，不是指令

Win32/MFC 的布局是"父窗口算好子窗口的矩形，`SetWindowPos` 摆过去"——父说一不二。WPF 反过来，**每一帧布局都是一场两遍的协商**：

```text
第一遍 Measure（测量）—— 自下而上
    父面板问每个孩子："给你这么大的可用空间（availableSize），你想要多大？"
    孩子量完自己的内容上报 DesiredSize

第二遍 Arrange（排列）—— 自上而下
    父面板根据孩子申报与自身规则分配最终矩形（finalRect）
    孩子在这个矩形里安置自己（递归对孙辈重复整个过程）
```

窗口尺寸变化 → 布局系统重新跑这两遍 → 所有面板重新协商 → **"窗口拉大时内容自动重排"不需要任何人写 OnSize 代码**。MFC 里手工 `RepositionBars` 那套在 WPF 中不存在，布局面板替你做了。

决定子元素"申报与接受"行为的，是三组通用属性（所有 UIElement 都有）：

| 属性 | 作用 | 记法 |
|---|---|---|
| `Margin` | 元素**外**的间距 | "我离别人远点" |
| `Padding` | 元素**内**的留白 | "我离自己的内容远点"（注意：Panel 中只有 Border 等少数有） |
| `HorizontalAlignment` / `VerticalAlignment` | 分到的空间比要的大时怎么摆：Left/Center/Right/**Stretch**（默认） | "多出来的空间给谁" |

`Margin` 的四种写法：`Margin="10"`（四边同值）、`"10,20"`（左右、上下）、`"10,20,30,40"`（左、上、右、下）。顺序**永远是左上右下**（顺时针）。

## 2. 面板选型表

WPF 内置六种常用面板，各自一条排布规则：

| 面板 | 排布规则 | 典型用途 |
|---|---|---|
| `Grid` | 行列网格，支持跨行跨列 | **主力**。复杂界面 90% 靠它 |
| `StackPanel` | 单向堆叠（横/竖），**不滚动不折行** | 菜单、按钮列、表单行的内部 |
| `DockPanel` | 按边停靠，最后一个填满剩余 | 工具栏/状态栏/内容区骨架 |
| `WrapPanel` | 流式排列，宽度不够自动换行 | 标签云、缩略图墙 |
| `Canvas` | 绝对坐标定位 | 绘图、拖拽编辑器——**不参与自适应** |
| `UniformGrid` | 均分格子（不用定义行列） | 棋盘、九宫格 |

原则：**从外到内搭骨架用 Grid/DockPanel，局部细节用 StackPanel，Canvas 只给绘图场景**。新手最常见的错误是拿 StackPanel 当万能容器——下一节会看到它在堆叠方向上的"无限空间"特性如何坑人。

## 3. Grid：Auto、星号、固定值

`05_layout` 示例的最外层是标准的三行式骨架（这个骨架值得背下来）：

```xml
<Grid Margin="16">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>   <!-- 行高 = 内容要多高给多高 -->
        <RowDefinition Height="*"/>      <!-- 行高 = 剩余空间全给它 -->
        <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <TextBlock Grid.Row="0" Text="布局示例" FontSize="20" FontWeight="Bold"/>
    <!-- Grid.Row="1" 是主内容区 -->
    <StatusBar Grid.Row="2" Margin="0,12,0,0"> ... </StatusBar>
</Grid>
```

三种行高的语义：

| 写法 | 含义 | 用在 |
|---|---|---|
| `Auto` | 由内容反推（Measure 的结果） | 标题、状态栏、按钮行 |
| `*`、`2*`、`1.5*` | 按**权重比例**瓜分剩余空间 | 主内容区 |
| `220`（像素） | 固定值 | 尽量少用——窗口缩放时会破版 |

经典配方：**标题行 `Auto` + 内容行 `*` + 底部行 `Auto`**。列同理（`Width` 换个方向）。子元素用第 04 章的附加属性申报位置：`Grid.Row="1"`、`Grid.Column="0"`、`Grid.RowSpan="2"`（跨两行）、`Grid.ColumnSpan="2"`（跨两列）。**忘了写 Grid.Row 时默认为 0**——两个控件叠在左上角格子里，表现为"有一个看不见了"，这是新手 top 级 bug。

行列之间可加 `GridSplitter` 让用户拖动调整——资源管理器式的"左树右内容"界面就这么做。

## 4. 示例拆解：嵌套的分工

`05_layout` 的主内容区是"外 Grid 拆列 → 左侧菜单 + 右侧 DockPanel"：

```xml
<Grid Grid.Row="1">
    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="200"/>   <!-- 固定宽度菜单列 -->
        <ColumnDefinition Width="*"/>     <!-- 内容列吃掉剩余 -->
    </Grid.ColumnDefinitions>

    <Border Grid.Column="0" Background="AliceBlue" Padding="12">
        <StackPanel>                      <!-- 纵向菜单按钮：StackPanel 的本职 -->
            <Button Content="首页" Margin="0,0,0,8"/>
            <Button Content="设置" Margin="0,0,0,8"/>
        </StackPanel>
    </Border>

    <DockPanel Grid.Column="1" LastChildFill="True">
        <TextBlock DockPanel.Dock="Top" Text="工作区" FontWeight="Bold" Margin="0,0,0,8"/>
        <TextBox DockPanel.Dock="Bottom" Height="80" AcceptsReturn="True"/>
        <!-- 最后一个子元素自动填充剩余：主编辑区 -->
    </DockPanel>
</Grid>
```

`DockPanel` 的规则值得专门记：**按声明顺序逐个停靠**，`LastChildFill="True"`（默认）时最后一个孩子吃掉全部剩余——所以"底部输入条 + 中间填充区"必须先把 TextBox `Dock="Bottom"`、再写填充元素；顺序写反就互相覆盖。Dock 可取 Top/Bottom/Left/Right。

## 5. 对齐与"Stretch 陷阱"

`VerticalAlignment`/`HorizontalAlignment` 默认是 **Stretch（拉伸填满）**。这一条默认值制造了大量"为什么我的控件被拉高了"的疑惑——放进 Grid 格子的 Button 高度拉满整行，不是 bug，是 Stretch 在工作。想要"内容多高就多高"，改成 `Center`/`Top`。

反过来还有个更隐蔽的陷阱：**StackPanel 在堆叠方向上给孩子"无限大"的可用空间**。竖排 StackPanel 里放一个想拉伸高度的元素（`Height="*"` 或 `VerticalAlignment="Stretch"`）全部失效——孩子申报多高就多高，`*` 无从瓜分，因为**没有"剩余空间"这个概念**。同理，竖排 StackPanel 里的内容超高不会自动滚动（ScrollViewer 才管滚动，第 06 章）。

口诀：**想在某个方向上按比例分配空间，这个方向必须由 Grid 管**。StackPanel 只做"顺次堆叠"这一件事。

## 6. 面板的组合拳

```xml
<!-- 工具栏：横向 StackPanel，按钮间距用 Margin -->
<StackPanel Orientation="Horizontal">
    <Button Content="打开" Margin="0,0,8,0"/>
    <Button Content="保存" Margin="0,0,8,0"/>
</StackPanel>

<!-- 登录卡片：Grid 两列（标签 + 输入框），Auto 让标签列正好包住文字 -->
<Grid>
    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="Auto"/>
        <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>
    <TextBlock Text="用户名：" VerticalAlignment="Center"/>
    <TextBox Grid.Column="1"/>
</Grid>
```

真实界面就是这几种面板的嵌套组合：**Window → Grid（骨架）→ 各区域 → 区域内部再选面板**。写复杂界面前先在纸上画层级图（第 06 章带画一张完整的）。

## 7. 常见坑

**控件重叠**：Grid 里忘写 `Grid.Row`/`Grid.Column`，默认全在 (0,0)——"有个控件看不见"先查这个。

**`Height="*"` 写在元素上**：`*` 是 Grid 行列定义的语法，不是元素属性。`<Button Height="*">` 编译不过；元素端只能用 `VerticalAlignment="Stretch"`（而且还是默认值）。

**StackPanel 里要滚动/拉伸**：两件都不行，第 5 节。换 Grid 或套 ScrollViewer。

**Canvas 当布局容器**：窗口缩放 Canvas 内容纹丝不动（绝对坐标不参与协商）。要自适应就别用 Canvas，它是给绘图场景的（第 19 章）。

**嵌套过深性能差**：每层布局都要 Measure+Arrange 递归；几十层嵌套的列表项模板 × 上千条目就会卡。列表项模板保持浅（第 15 章）。

**在 Measure 阶段读 ActualWidth**：布局还没 Arrange 完，读到的是 0 或旧值。需要实际尺寸挂 `Loaded`/`SizeChanged` 事件。

## 8. 实战建议

- 新窗口一律从三行 Grid（标题 Auto / 内容 `*` / 底部 Auto）起步——第 25 章实战项目就是这个骨架
- 尺寸策略：**文字相关用 Auto，主内容用 `*`，真正固定才写像素**；比例用 `2*`/`1*` 表达
- 布局不对时先画层级图，逐层核对 Alignment/Margin——大多数"控件乱跑"是对默认 Stretch 的误解
- 跨 Grid 的列对齐用 `SharedSizeGroup`，大界面拆分后仍能保持标签列对齐（第 06 章实战演示）

## 自测

1. **Measure 和 Arrange 各自做什么、方向如何？** —— Measure 自下而上收集 DesiredSize；Arrange 自上而下分配最终矩形。
2. **三行骨架的行高怎么写？为什么主内容区用 `*`？** —— Auto / `*` / Auto；`*` 吃掉剩余空间，窗口缩放时只有主区变。
3. **StackPanel 里的元素为什么不能纵向拉伸？** —— 堆叠方向可用空间"无限"，没有剩余可分配。
4. **DockPanel 里"中间填充区"要满足什么条件？** —— 是最后一个子元素（LastChildFill=True 时），停靠元素写在前面。
5. **控件莫名重叠，第一个查什么？** —— 是否漏了 Grid.Row/Grid.Column（默认都是 0）。

---
上一章：[04 标记扩展与依赖属性](04-markup-extensions-dp.md) ｜ 下一章：[06 布局实战](06-layout-lab.md)
