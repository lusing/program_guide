# 04 · 布局系统：Measure/Arrange 两遍测量

> 对应示例：`examples/04_layout`

## 1. 布局是协商，不是指令

Win32/MFC 的布局是"父窗口算好子窗口矩形，SetWindowPos 摆过去"；WPF 反过来——**子元素先申报"我想要多大"（Measure），父面板再分配"你实际占多大"（Arrange）**。整个过程每帧递归执行一遍：

```text
Measure(可用尺寸)   自下而上收集期望值：子元素报 DesiredSize
Arrange(最终矩形)   自上而下定位置：父面板决定每个子元素的最终矩形
```

这个机制让"窗口拉大时内容自动重排"不需要任何人写 OnSize 代码——MFC 第 09 章那种手工 `RepositionBars` 在 WPF 里不存在，布局面板替你做了。

决定子元素"申报与接受"的行为的，是三组通用属性：

| 属性 | 作用 |
|---|---|
| `Margin` | 元素**外**的间距（四元组：左,上,右,下） |
| `Padding` | 元素**内**的留白（多数由 Border/控件模板实现） |
| `HorizontalAlignment` / `VerticalAlignment` | 分到的空间比要的大时，如何靠边/居中/拉伸（默认 Stretch） |

## 2. 面板选型表

| 面板 | 排布规则 | 用途 |
|---|---|---|
| `Grid` | 行列网格，支持跨行跨列 | **主力**。复杂界面 90% 靠它 |
| `StackPanel` | 单向堆叠（横/竖） | 菜单、按钮列、简单列表 |
| `DockPanel` | 按边停靠，最后一个填满 | 工具栏/状态栏/内容区骨架 |
| `WrapPanel` | 流式换行 | 标签云、缩略图墙 |
| `Canvas` | 绝对坐标 | 绘图、拖拽——**不参与自适应** |
| `UniformGrid` | 均分格子 | 棋盘、九宫格 |

原则：**从外到内搭骨架用 Grid/DockPanel，局部细节用 StackPanel，Canvas 只给绘图场景**。

## 3. Grid：Auto、星号、固定值

`04_layout` 示例的最外层就是标准的三行式骨架：

```xml
<Grid Margin="16">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>   <!-- 行高 = 内容要多高给多高 -->
        <RowDefinition Height="*"/>      <!-- 行高 = 剩余空间全给它 -->
        <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <TextBlock Grid.Row="0" Text="布局示例" .../>
    <!-- 主内容 -->
    <StatusBar Grid.Row="2" Margin="0,12,0,0"> ... </StatusBar>
</Grid>
```

三种行高的语义：

| 写法 | 含义 |
|---|---|
| `Auto` | 由内容反推（Measure 的结果） |
| `*`、`2*` | 按**比例**瓜分剩余空间（星号前是权重） |
| `220` | 固定像素（不建议滥用，缩放窗口时会破） |

经典配方就是标题行 `Auto` + 内容行 `*` + 状态栏 `Auto`。子元素用**附加属性**声明自己的位置：`Grid.Row="1"`、`Grid.Column="0"`、`Grid.RowSpan="2"`。附加属性是依赖属性的变体——属性定义在 Grid 上，值挂在子元素上，这正是第 03 章依赖属性"值的存放外包"的体现。

## 4. 示例拆解：三层嵌套

`04_layout` 的主内容区是"外 Grid 拆列 → 左侧菜单列 + 右侧 DockPanel"：

```xml
<Grid Grid.Row="1">
    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="220"/>   <!-- 固定宽度菜单列 -->
        <ColumnDefinition Width="*"/>     <!-- 内容列吃掉剩余 -->
    </Grid.ColumnDefinitions>

    <Border Grid.Column="0" Background="AliceBlue" Padding="12" ...>
        <StackPanel>                      <!-- 纵向菜单按钮 -->
            <Button Content="首页" .../>
        </StackPanel>
    </Border>

    <DockPanel Grid.Column="1" LastChildFill="True">
        <TextBlock DockPanel.Dock="Top" Text="工作区" .../>
        <TextBox DockPanel.Dock="Bottom" Height="90" .../>
        <!-- 最后一个子元素填充剩余 -->
    </DockPanel>
</Grid>
```

`DockPanel` 的规则值得记牢：**按声明顺序逐个停靠，`LastChildFill="True"` 时最后一个孩子吃掉全部剩余**——所以"底部 TextBox + 中间填充区"的写法是先把 TextBox `Dock="Bottom"`，再写填充元素，顺序反了就会互相覆盖。

## 5. 对齐与"Stretch 陷阱"

`VerticalAlignment` 默认是 Stretch，这解释了大量"为什么我的控件被拉高了"。反过来，把 TextBox 放进 `StackPanel` 竖排时，`Height="*"` 或 Horizontal Stretch 都会失效——**StackPanel 在堆叠方向上给孩子的空间是"无限的"**，所以孩子申报多高就多高，`*` 无从瓜分。

想在竖排 StackPanel 里实现"最后一个控件吃掉剩余高度"？这是信号：**你需要换 Grid**，别跟 StackPanel 较劲。

## 6. 常见坑

**嵌套过深性能差**：每层布局都要 Measure+Arrange 递归，十来层 Grid 套 Grid 没问题，几百个嵌套面板的列表项乘以条数就会卡。列表项模板保持浅（第 06 章）。

**Canvas 里的"自适应"**：Canvas 子元素按绝对坐标摆放，窗口缩放时纹丝不动。要自适应就别用 Canvas。

**Grid 里控件重叠**：忘了写 `Grid.Row`/`Grid.Column` 时默认都是 0，两个控件叠在同一个格子里，表现为"其中一个看不见"。

**Margin 负值与 Alignment 冲突**：`HorizontalAlignment=Center` 时 Margin 的左右值仍生效但拉伸语义变了；居中布局调间距优先用外层容器的 Padding。

**两遍测量被滥用**：在 Measure 阶段读取 `ActualWidth`（Arrange 之后才有正确值）得到的永远是 0 或旧值。需要尺寸就挂 `SizeChanged`/`Loaded`。

## 7. 实战建议

- 新窗口从三行 Grid（标题 Auto / 内容 * / 底部 Auto）起步，第 12 章实战项目的窗口就是这个骨架
- 尺寸策略：**文字相关用 Auto，主内容用 `*`，只有真正固定才写像素**
- 布局不对时先画层级图，确认每一层的 Alignment/Margin——大多数"控件乱跑"是对默认 Stretch 的误解
- 复杂行列用 `ColumnDefinition Width="Auto"` 共享列宽（同列控件对齐），或 `SharedSizeGroup`（跨 Grid 对齐）

---
上一章：[03 XAML 语言](03-xaml.md) ｜ 下一章：[05 核心控件与路由事件](05-controls.md)
