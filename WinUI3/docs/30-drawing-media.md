# 30. 图形与媒体

上一篇：[29 动画](./29-animation.md) ｜ 下一篇：[31 窗口与外壳](./31-window-shell.md)

矢量图形（Shape 家族）、图片（Image）与取色（ColorPicker）是界面的"非控件视觉层"。示例来自画廊工程的 `DrawingPage`（导航 **Drawing** 项）。

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

## 30.6 小结

| 需求 | API |
|------|-----|
| 简单矢量 | Ellipse/Rectangle/Line/Polygon |
| 任意路径 | Path + Data 迷你语法 |
| 上色 | Brush 家族 + ThemeResource 键 |
| 取色 | ColorPicker + ColorChanged(NewColor) |
| 图片 | Image + Source(ms-appx) + DecodePixelWidth |
| 视频 | MediaPlayerElement（边界见 30.4） |

画廊 `DrawingPage` 运行时证据：`.smoke/26-customization/drawing/click-2.png`——点击 ColorPicker 色板，LiveDot 椭圆变为所选蓝，状态行 **"color = 43,172,255"**；顶部 Shape 行与 Path 曲线同帧可见。

---

上一篇：[29 动画](./29-animation.md) ｜ 下一篇：[31 窗口与外壳](./31-window-shell.md) ｜ 返回 [目录](../README.md)
