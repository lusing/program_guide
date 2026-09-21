# 19 · 绘图与变换

> 对应示例：`examples/19_drawing`（Canvas 小场景：Path/形状/渐变画刷 + 变换互动）

> **本章你将学会**：六种 Shape 与 Path 路径语法、三种画刷、RenderTransform 变换与 RenderTransformOrigin。
> **前置章节**：[04 附加属性](04-markup-extensions-dp.md)、[05 Canvas](05-layout.md)。

## 1. Shape 家族：声明式矢量图

WPF 的图形元素都是 `Shape` 的子类，写在 XAML 里就是"画"了——分辨率无关的矢量图，窗口缩放不失真（第 06 章 Viewbox 的绝佳搭档）：

| Shape | 用途 | 关键属性 |
|---|---|---|
| `Rectangle` / `Ellipse` | 矩形/椭圆 | Width/Height、RadiusX/RadiusY（圆角） |
| `Line` | 线段 | X1/Y1/X2/Y2 |
| `Polygon` | 多边形（点序列自动闭合填充） | Points="x1,y1 x2,y2 …" |
| `Polyline` | 折线（不闭合不填充） | Points |
| `Path` | **任意曲线**（贝塞尔/弧/组合） | Data（迷你语言） |

通用属性：`Fill`（填充画刷）、`Stroke`（描边画刷）、`StrokeThickness`（描边粗细）、`StrokeDashArray`（虚线，第 20 章加载圈用它）。

示例在 Canvas 上拼了一张小场景（太阳、渐变房身、多边形屋顶、篱笆）——每种 Shape 至少出场一次，**建议对着示例改坐标玩**，坐标感是画图的第一直觉。

## 2. Path.Data：迷你路径语言

`Path` 的 `Data` 用一串字符描述任意图形——"迷你语言"的命令字母：

| 命令 | 含义 | 示例 |
|---|---|---|
| `M x,y` | 移动到（起点） | `M 10,180` |
| `L x,y` | 连直线到 | `L 100,180` |
| `Q x1,y1 x,y` | 二次贝塞尔（1 个控制点） | `Q 135,130 270,200` |
| `C x1,y1 x2,y2 x,y` | 三次贝塞尔（2 个控制点） | — |
| `A r,r 旋转 方向 弧 终点` | 椭圆弧 | — |
| `Z` | 闭合回到起点 | 山丘的底边 |

示例的山丘就是一条二次贝塞尔 + 镜像 + 闭合：

```xml
<Path Data="M 0,200 Q 135,130 270,200 T 540,200 L 540,230 L 0,230 Z" Fill="#BBF7D0"/>
<!--   起点    └二次贝塞尔┘  └T=镜像上一段控制点┘ └─底部封闭─┘   -->
```

读法：命令字母后跟坐标，空格/逗号随意；大写=绝对坐标，小写=相对坐标。这套语法 SVG 同款——会一个等于会两个。复杂图形可以用 `StreamGeometry`/`PathGeometry` 对象语法（属性元素展开），迷你语言只是它的序列化形式。

## 3. 三种画刷

`Fill`/`Stroke` 收的都是 **Brush**，家族里常用三种（示例第 2 区三块并排）：

```xml
<!-- ① 纯色 -->
<Rectangle Fill="#3B82F6"/>

<!-- ② 线性渐变：沿 StartPoint→EndPoint 方向插值 -->
<Rectangle>
    <Rectangle.Fill>
        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">   <!-- 坐标是 0~1 的相对值 -->
            <GradientStop Color="#3B82F6" Offset="0"/>          <!-- 起点色 -->
            <GradientStop Color="#10B981" Offset="1"/>          <!-- 终点色 -->
        </LinearGradientBrush>
    </Rectangle.Fill>
</Rectangle>

<!-- ③ 径向渐变：从圆心向外插值 -->
<RadialGradientBrush GradientOrigin="0.4,0.4">                  <!-- 高光偏心一点更像球 -->
    <GradientStop Color="#FEF9C3" Offset="0"/>
    <GradientStop Color="#FBBF24" Offset="1"/>
</RadialGradientBrush>
```

要 3 个以上颜色就加 GradientStop（Offset 是 0~1 的位置百分比）。渐变画刷配 Ellipse 一秒出"立体球"，配 Rectangle 出"高级感背景"——UI 的光泽感大多是渐变的功劳。第四种 `ImageBrush`（图片填充）与 `VisualBrush`（控件快照填充）按需查。

画刷是资源系统的常客：把渐变定义成 `x:Key` 资源（第 13 章），多处复用、换肤集中改。

## 4. 变换：RenderTransform

变换（Transform）把渲染结果整体变形——**不参与布局协商**（第 05 章），只改"画出来的样子"：

| 变换 | 效果 | 关键属性 |
|---|---|---|
| `RotateTransform` | 旋转 | Angle（度）、CenterX/CenterY |
| `ScaleTransform` | 缩放 | ScaleX/ScaleY |
| `TranslateTransform` | 平移 | X/Y（第 20 章动画的主角） |
| `SkewTransform` | 斜切 | AngleX/AngleY |
| `TransformGroup` | 组合多个 | 按声明顺序应用 |

示例第 3 区：五角星套上"旋转 + 缩放"的组合变换，两个按钮直接改变换对象的属性：

```xml
<Polygon x:Name="Star" Points="60,20 69,47 …"
         RenderTransformOrigin="0.5,0.5">      <!-- ★ 变换中心：元素自身的 0.5,0.5 = 中心点 -->
    <Polygon.RenderTransform>
        <TransformGroup>
            <RotateTransform x:Name="StarRotate"/>
            <ScaleTransform x:Name="StarScale"/>
        </TransformGroup>
    </Polygon.RenderTransform>
</Polygon>
```

```csharp
private void Rotate_Click(object sender, RoutedEventArgs e) => StarRotate.Angle += 30;
private void ScaleUp_Click(object sender, RoutedEventArgs e)
{
    StarScale.ScaleX *= 1.2;
    StarScale.ScaleY *= 1.2;
}
```

`RenderTransformOrigin` 是 0~1 的**相对坐标**（0.5,0.5 = 元素中心）——不设它，旋转会绕左上角转（最常见的"转飞了"）。变换对象能 `x:Name` 后被代码直接改属性，是第 20 章动画的入口（动画驱动的就是这些属性）。

**RenderTransform vs LayoutTransform**：前者只改渲染（不影响布局，其他元素不动）、性能好；后者影响布局（占位变大、邻居被推开）。动画与特效一律 RenderTransform，LayoutTransform 留给"真要改变布局占位"的场景。

## 5. Canvas 定位回顾

第 05 章说过 Canvas 是绝对坐标定位（附加属性 `Canvas.Left/Top`），绘图场景的绝配——图形的坐标本来就是设计出来的，不需要协商。两个配套习惯：

- 给 Canvas 定宽高（`Width="540" Height="230"`），图形按设计稿坐标摆
- 套 Viewbox 整体缩放（第 06 章）——固定版式的图形界面"一套设计适配所有窗口"

代码画图也完全可行：`Canvas.Children.Add(new Ellipse { ... })`——XAML 与 C# 的老对应关系（第 03 章）在图形区同样成立。

## 6. 常见坑

**旋转绕错了轴**：没设 RenderTransformOrigin（默认 0,0 = 左上角）。绕中心转写 `0.5,0.5`。

**Points 格式错**：`"60,20 69,47"` 逗号分 xy、空格分点；写成 `"60,20,69,47"` 解析成另一个图形（不报错）。

**迷你语言大小写混用**：M/m、L/l 是绝对/相对之别，混着用图形"漂移"。入门统一用大写（绝对坐标）。

**渐变坐标用了像素值**：StartPoint/EndPoint/Offset 都是 0~1 相对量——"1,0" 是"整个宽度"，不是 1 像素。

**TransformGroup 顺序不对**：先缩放后旋转 ≠ 先旋转后缩放（矩阵乘法不交换）。想"边自转边公转"的用组合并想清顺序。

**Shape 不设 Fill/Stroke 看不见**：默认都是 null/透明。形状"消失"先查这两个。

## 7. 实战建议

- 图标类小图形用 Shape/Path 手写（颜色随主题、无限缩放）；照片类用 Image；两者别混
- 复杂插画导出 SVG 后转 XAML Path（社区有转换器），"迷你语言"当阅读技能就够，不必手写
- 画刷、Geometry 都适合注册成资源复用——一组图标共用一套渐变
- 特效/动效永远 RenderTransform；需要占位变化的（如真把按钮放大推开周围）才 LayoutTransform
- 本章 + 第 20 章 = WPF 的"动效基础"，自定义控件库的视觉几乎全靠这两章的机制

## 自测

1. **Path 迷你语言里 M/Q/Z 各是什么？** —— M 移动起点、Q 二次贝塞尔、Z 闭合。
2. **三种常用画刷的差异？渐变坐标是什么单位？** —— 纯色/线性/径向；0~1 相对量。
3. **RenderTransformOrigin 不设会怎样？设 0.5,0.5 呢？** —— 默认绕左上角变换；0.5,0.5 绕元素中心。
4. **RenderTransform 与 LayoutTransform 的选择？** —— 特效动画用 Render（不扰布局）；要真实改变占位才 Layout。

---
上一章：[18 TreeView 与层级数据](18-treeview.md) ｜ 下一章：[20 动画](20-animation.md)
