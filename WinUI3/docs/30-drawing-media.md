# 30. 图形与媒体

上一篇：[29 动画](./29-animation.md) ｜ 下一篇：[31 窗口与外壳](./31-window-shell.md)

矢量图形（Shape 家族）、图片（Image）与取色（ColorPicker）是界面的"非控件视觉层"。示例代码来自功能工程 `examples/26-theme-lab/`（主题实验室：预设换肤、自定义控件仪表盘、accent 即改、VSM、动画、Shape 图表）。

## 30.1 Shape：不是控件的图形

```xml
<StackPanel Orientation="Horizontal" Spacing="14">
    <Ellipse Width="60" Height="60" Stroke="{ThemeResource AccentFillColorDefaultBrush}" StrokeThickness="2"/>
    <Rectangle Width="70" Height="60" RadiusX="6" RadiusY="6" Fill="{ThemeResource AccentFillColorSecondaryBrush}"/>
    <Line X1="0" Y1="30" X2="60" Y2="0" Stroke="..." StrokeThickness="2"/>
    <Polygon Points="0,40 30,0 60,40" Fill="..." Stroke="Black" StrokeThickness="1"/>
</StackPanel>
```

- 成员：`Ellipse` / `Rectangle`（RadiusX/Y 圆角）/ `Line`（坐标端点）/ `Polygon`（点集闭合）/ `Polyline`（点集不闭合）/ `Path`（万能）。
- 公共属性：`Stroke`（描边 Brush）/ `StrokeThickness` / `Fill`（填充 Brush）/ `Stretch`（None/Fill/Uniform...）/ `StrokeDashArray`（虚线）。
- **Shape 继承 FrameworkElement 而非 Control**（同 08 章 TextBlock 的道理）：无模板、无 Background、无 IsEnabled。**也没有点击交互**——要可点的图形外面套 Border/Button。

### Path：迷你语法

```xml
<Path Stroke="..." StrokeThickness="3" Fill="..."
      Data="M 10,60 C 30,0 70,0 90,60 Z"/>
```

`Data` 的流式语法：`M` 移动 / `L` 直线 / `C` 三次贝塞尔 / `Q` 二次 / `A` 弧 / `Z` 闭合；逗号分隔坐标、空格分隔指令。图标级矢量（对勾、箭头、波形）一行搞定；复杂图形用工具导出字符串。

## 30.2 Brush：上色的三种笔

| Brush | 用途 |
|-------|------|
| `SolidColorBrush` | 纯色（代码里 `SolidColorBrush(Colors::Red())` 直构） |
| `LinearGradientBrush`/`RadialGradientBrush` | 渐变（GradientStops 集合） |
| `ImageBrush` | 图片平铺填充 |

**颜色别硬编码**：`#FF0000` 在深浅主题里至少一半时间刺眼——主题资源键（`AccentFillColorDefaultBrush` 等，33 章全表）自动适配。本页所有示例走 ThemeResource。

## 30.3 ColorPicker：取色联动

```cpp
void DrawingPage::OnColorChanged(IInspectable const&, ColorChangedEventArgs const& args)
{
    if (!LiveDot() || !StatusText()) return;
    auto color = args.NewColor();
    LiveDot().Fill(SolidColorBrush(color));
    StatusText().Text(L"color = " + to_hstring(color.R) + L"," + to_hstring(color.G) + L"," + to_hstring(color.B));
}
```

`ColorPicker`：色域面板 + 通道滑条 + 预览。关键属性 `IsAlphaEnabled`（透明度通道）、`IsColorPreviewVisible`、`IsColorSliderVisible`；`Color` 属性双向可读写，事件 `ColorChanged` 带 `args.NewColor()`（`Windows::Foundation::Color`——R/G/B/A 各一字节）。典型联动如本页：选色 → 直写旁边图形的 Fill（smoke 实测：点击色板，椭圆即刻变色）。

## 30.4 Image 与媒体

```xml
<Image Source="ms-appx:///Assets/photo.png" Stretch="Uniform"/>
```

- **`Source`**：包内资源用 `ms-appx:///` URI；代码侧 `BitmapImage(Windows::Foundation::Uri(L"ms-appx:///..."))`。
- **`DecodePixelWidth`**：解码即缩放——展示 8000px 相机原图到 200px 框时，先设它再进树，内存从几十 MB 降到几十 KB。这是 Image 最有性价比的属性。
- `Stretch`（None/Fill/Uniform/UniformToFill）与 `NineGrid`（九宫格拉伸，做可伸缩边框）。
- `MediaPlayerElement`：视频/音频播放（Source/PosterSource/AutoPlay）——**运行时验证边界**：需要真实媒体文件与解码路径，本教程未做运行时验证，签名经元数据核对。
- `SwapChainPanel`：高性能自绘（游戏/图表）的接入点，超出本教程范围，知道入口即可。

## 30.5 实测坑位

1. **Shape 不可点**（30.1）——交互需求套容器。
2. **硬编码颜色 vs 主题**：深浅色切换时才发现刺眼，改 ThemeResource。
3. **`Color` 是 `Windows::Foundation::Color`**：与 `Microsoft.UI` 的 Color 类似物按元数据核对——`ColorChangedEventArgs.NewColor()` 返回 WF.Color。
4. **Image 不设 DecodePixelWidth 加载原图**：内存浪费大户。
5. **ms-appx 资源要进 PRI**：vcxproj 里作为 Content/Resource 项登记（09 章 Assets 篇）。

## 30.5 实战：七根柱子的迷你图表（主题实验室）

不引图表库，一周访问量就是七根 Rectangle：

```cpp
void MainWindow::BuildChart()
{
    static const double week[7] = { 42, 68, 55, 81, 74, 96, 88 };
    auto columns = Grid().ColumnDefinitions();
    for (int i = 0; i < 7; ++i)
    {
        ColumnDefinition column;
        column.Width(GridLength(1.0, GridUnitType::Star));
        columns.Append(column);
    }

    double chartHeight = 190.0;
    double max = *std::max_element(week, week + 7);
    for (int i = 0; i < 7; ++i)
    {
        double barHeight = chartHeight * week[i] / max;

        StackPanel column;
        column.VerticalAlignment(VerticalAlignment::Bottom);
        column.Spacing(2);

        Microsoft::UI::Xaml::Shapes::Rectangle bar;
        bar.Height(barHeight);
        bar.RadiusX(4); bar.RadiusY(4);
        bar.Margin({ 10, 0, 10, 0 });
        m_bars.push_back(bar);   // 登记：accent 变了全量重刷（26.6）

        TextBlock label;
        label.Text(std::wstring(L"MTWTFSS").substr(i, 1));
        label.HorizontalAlignment(HorizontalAlignment::Center);
        label.Opacity(0.6);

        column.Children().Append(bar);
        column.Children().Append(label);
        Chart().Children().Append(column);
        Chart().SetColumn(column, i);
    }
}
```

**这段代码的六个要点**：

1. **Grid 当图表画布**：七列等宽（Star）就是柱位；`SetColumn(column, i)` 把每根柱的容器钉进列——Shape 没有布局语义，布局由容器给。
2. **高度即数据**：`barHeight = 190 × value / max`——归一化到像素。**记得除以最大值**，直接拿原始值当高度，42 和 96 的比例就错了（除非数据恰好满量程）。
3. **VerticalAlignment=Bottom 是柱状图的灵魂**：默认顶对齐的话柱子从天花板往下长。装柱的 StackPanel 沉底，标签跟在柱子下面。
4. **RadiusX/Y=4 圆角柱顶**——纯审美但成本两行；Margin(10,0) 留柱间距，**间距用 Margin 不用列间距**，列宽保持严格等分。
5. **`Rectangle` 裸名会被遮蔽**（同 Style 家族的坑）：全限定 `Microsoft::UI::Xaml::Shapes::Rectangle`。
6. **星期标签从字符串切片**：`L"MTWTFSS".substr(i, 1)`——比七个分支诚实。

### 30.5.1 填色与主题联动

柱子的 Fill 没写在 BuildChart 里，而是登记进 `m_bars`、由 ApplyAccent 统一刷（26.6.3 的结论：代码造的元素跟 accent 走，只能手动重刷）——`.smoke/26-theme-lab/preset/chart.png` 里七根红柱就是 Sunset 预设的 ApplyAccent 干的活。**柱状图与 ColorPicker 的联动是这套 UI 的"主题证据"**：你改的不是某个控件的属性，是整个视觉系统。

### 30.5.2 Shape 家族速查与选型

| Shape | 本图用途 | 别的用途 |
|---|---|---|
| Rectangle | 柱 | 进度条底/填充、色块 |
| Ellipse | — | 圆点（DataExplorer 色板可用它） |
| Line | — | 网格线、连接线 |
| Path | — | 任意曲线（贝塞尔），图标级矢量 |

**Shape 是最低层的绘图原语**：没有命中测试的便利（IsHitTestVisible 有，但语义不如控件）、没有模板化。数据可视化到"交互图表"（hover 提示、点击钻取）就该上控件层或第三方了——本节的七根柱子恰好停在"展示"与"交互"的分界线上，这个停顿本身就是教学。

### 30.5.3 图表的下一步：坐标轴与多系列

七根柱子到"真图表"还差三件事：**Y 轴刻度**（几条 Line + TextBlock，按 25/50/75/100 摆高——与柱子同用 max 归一化公式）、**多系列**（每列变 StackPanel 竖排两根 Rectangle，图例一小块）、**负值**（零线居中，柱子方向翻转）。都在本节机制的延长线上——Grid 打底、归一化算高、TextBlock 标注。再往上（hover 十字线、动画过渡、缩放）就该考虑图表库了——**自制的价值边界在读得懂机制，不在复刻产品**。

### 30.5.4 Image 与位图的差异

Shape 之外本章的另两块：`Image`（位图，Source 接 BitmapImage/WriteableBitmap）与 `ImageBrush`（当填充用）。位图没有矢量的事——尺寸固定，缩放即插值（DecodePixelWidth 提前解码到目标尺寸省内存）。**图表为什么不用位图**：柱高是数据函数，运行时要变（accent 换色、数据更新）——Shape 是活对象改属性即重绘，位图是死像素要重画整张。判据：**内容跟数据走用矢量，内容跟照片走用位图**。

## 30.6 小结

| 需求 | API |
|------|-----|
| 简单矢量 | Ellipse/Rectangle/Line/Polygon |
| 任意路径 | Path + Data 迷你语法 |
| 上色 | Brush 家族 + ThemeResource 键 |
| 取色 | ColorPicker + ColorChanged(NewColor) |
| 图片 | Image + Source(ms-appx) + DecodePixelWidth |
| 视频 | MediaPlayerElement（边界见 30.4） |

运行时证据：`.smoke/26-theme-lab/preset/chart.png`——七根 Rectangle 按 [42,68,55,81,74,96,88] 立高（Height=190×值/最大值）、RadiusX/Y 圆角、底部 TextBlock 星期标签，填充色随 ApplyAccent 全量重刷（预设变红、ColorPicker 变什么都跟着走）；同工程 ColorPicker 在底部实时改全局 accent。

---

上一篇：[29 动画](./29-animation.md) ｜ 下一篇：[31 窗口与外壳](./31-window-shell.md) ｜ 返回 [目录](../README.md)
