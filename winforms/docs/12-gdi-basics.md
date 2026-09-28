# 12 · GDI+ 绘图基础：Paint、Pen、Brush、双缓冲

> 对应示例：`examples/12_gdi_basics`（自绘画布：七种基本图形 + 笔刷家族 + 手写笔迹 + 抗锯齿开关）

> **本章你将学会**：OnPaint/Graphics、Pen 与 Brush 家族、失效-重绘模型、双缓冲、抗锯齿。
> **前置章节**：[04 布局](04-layout.md)。

## 1. 一切绘制都在 OnPaint 里

控件的外观不是"设置"出来的，是**画**出来的。自绘控件 = 继承 + 重写 `OnPaint`：

```csharp
internal class Canvas : Panel
{
    public Canvas()
    {
        // 自绘控件标准四开关
        SetStyle(ControlStyles.AllPaintingInWmPaint |   // 擦背景不走 WM_ERASEBKGND（防闪一半）
                 ControlStyles.UserPaint |              // 全部内容自己画
                 ControlStyles.OptimizedDoubleBuffer |  // 双缓冲：先画内存位图再上屏
                 ControlStyles.ResizeRedraw,            // 尺寸一变整面重画
                 true);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        Graphics g = e.Graphics;               // 只在这块剪辑区里画（脏矩形机制）
        …
    }
}
```

也可以不继承、订阅 `Paint` 事件——小改动够用，成体系自绘用继承。

## 2. Pen 与 Brush 家族

```csharp
using var pen = new Pen(Color.SteelBlue, 3f);                    // 线：颜色+宽度
g.DrawLine(pen, 20, 20, 180, 60);

using var dash = new Pen(Color.OrangeRed, 2f) { DashStyle = DashStyle.Dash };   // 虚线
g.DrawRectangle(dash, 20, 80, 160, 70);

using var thick = new Pen(Color.FromArgb(120, 30, 144), 6f)
{
    StartCap = LineCap.Round,                  // 圆头
    EndCap = LineCap.ArrowAnchor,              // 箭头：流程图老朋友
};
```

```csharp
using (var solid = new SolidBrush(Color.FromArgb(140, Color.MediumSeaGreen)))   // 半透明 140/255
    g.FillEllipse(solid, 220, 20, 140, 70);

using (var hatch = new HatchBrush(HatchStyle.DiagonalCross, Color.Gray, Color.WhiteSmoke))   // 影线
    g.FillRectangle(hatch, 20, 170, 160, 70);

var rect = new Rectangle(220, 140, 160, 80);
using (var grad = new LinearGradientBrush(rect, Color.RoyalBlue, Color.White, LinearGradientMode.Vertical))
    g.FillEllipse(grad, rect);                 // 渐变
```

**Pen 描边（Draw*）、Brush 填充（Fill*）是两族方法**——椭圆要又描又填就调两次。`System.Drawing.Drawing2D` 命名空间装着 DashStyle/HatchBrush/LinearGradientBrush 这些进阶货。

**`Brushes.DimGray` 这类静态刷子是共享缓存——不能 Dispose**（`using` 它会把系统缓存搞坏），自己 `new` 的才要释放。

## 3. 失效-重绘模型（本章灵魂）

**鼠标事件里绝不直接画**——只改数据 + `Invalidate()`：

```csharp
public List<Point> Stroke = new();             // 笔迹数据

protected override void OnMouseDown(MouseEventArgs e)
{
    Stroke.Clear();
    Stroke.Add(e.Location);
    Invalidate();                              // 请求重画
}

protected override void OnMouseMove(MouseEventArgs e)
{
    if (e.Button == MouseButtons.Left && Stroke.Count > 0)
    {
        Stroke.Add(e.Location);
        Invalidate();                          // 系统稍后调 OnPaint（可能合并请求）
    }
}

// OnPaint 里全量重画：
if (Stroke.Count > 1)
    using (var ink = new Pen(Color.Black, 2f))
        g.DrawLines(ink, Stroke.ToArray());
```

为什么？①窗口被遮挡再露出时系统要重画，你画在别处的东西**没了**；②Invalidate 会合并高频事件，不闪；③双缓冲配合才成立。**数据在内存、渲染在 OnPaint**——这是所有自绘界面的第一定律（WPF/WinUI 换了形式但定律不变）。

## 4. 抗锯齿

```csharp
g.SmoothingMode = SmoothingMode.AntiAlias;                        // 图形边缘
g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;         // 文本
```

12 示例的开关按钮实时对比：圆弧和斜线的锯齿在开关间肉眼可见。

## 5. 文本也是画的

```csharp
g.DrawString("这段字是 DrawString 画的", Font, Brushes.DimGray, 20, 250);
```

`Graphics.MeasureString` 先量后画可以做居中（13 章验证码用它把字画正）。

## 6. 三语言差异

**F#**——自绘控件用类 + `override`，注意 float 重载没有隐式转换：

```fsharp
override this.OnPaint(e: PaintEventArgs) =
    base.OnPaint e
    let g = e.Graphics
    if smooth then g.SmoothingMode <- SmoothingMode.AntiAlias
    use pen = new Pen(Color.SteelBlue, 3f)
    g.DrawLine(pen, 20, 20, 180, 60)                 // int 重载 OK
    g.DrawBezier(pen, 420.0f, 180.0f, 470.0f, 20.0f, 500.0f, 220.0f, 560.0f, 120.0f)
    //                ★ float 重载必须 420.0f——F# 无隐式数值转换，int 会 FS0001
```

**C++/CLI**——栈语义自动 Dispose（`using` 的等价物）：

```cpp
Pen pen(Color::SteelBlue, 3.0f);        // 栈语义：作用域结束自动 Dispose
g->DrawLine(%pen, 20, 20, 180, 60);     // 句柄化的 this 用 % 取
```

`%pen`（整个对象取句柄 pin）是把栈语义对象传给要句柄的 API 的写法。注意 **Graphics 不能用栈语义**从位图造（C3673 无拷贝构造），用 `Graphics::FromImage(bmp)` + `delete`（13 章）。

## 坑位清单

1. 在 MouseMove 里直接 `CreateGraphics()` 画 → 遮挡回来就消失（数据不在内存里）。
2. `using Brushes.Black` → Dispose 了共享缓存；静态刷子不能释放。
3. 不开 `OptimizedDoubleBuffer` 的自绘 = 闪烁重灾区（四开关一起上）。
4. F# float 重载传 int → FS0001（无隐式转换）。
5. C++/CLI 用 `Graphics g(bmp)` 栈语义 → C3673；改 `Graphics::FromImage`。

## 自测

1. `Draw*` 与 `Fill*` 两族方法的分工？
2. 失效-重绘模型的第一定律？直接 `CreateGraphics` 画为什么"会消失"？
3. 双缓冲四开关分别治什么病？
4. `Brushes.Red` 与 `new SolidBrush(Color.Red)` 在生命周期上的区别？
5. Invalidate 之后 OnPaint 一定立刻执行吗？
