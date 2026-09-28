# 13 · GDI+ 应用：柱形图、验证码、坐标变换

> 对应示例：`examples/13_gdi_apps`（随机数据柱形图 + 图片验证码 + 旋转文字动画）

> **本章你将学会**：把 GDI+ 用成生产力——统计图表、验证码生成、Transform 坐标系、位图上的 Graphics。
> **前置章节**：[12 GDI+ 基础](12-gdi-basics.md)。

## 1. 柱形图控件（书的 9.4.1 现代版）

```csharp
public class BarChart : Control
{
    private int[] _values = { 42, 68, 55, 90, 73, 61 };

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        var plot = new Rectangle(40, 16, Width - 60, Height - 50);   // 留出轴和标签的边距
        int max = 100;                          // 纵轴固定 0..100，好对比
        float slot = plot.Width / (float)_values.Length;              // 每根柱的槽位
        float barW = slot * 0.6f;                                    // 柱宽 = 槽位 60%

        // 轴与刻度
        g.DrawLine(axis, plot.Left, plot.Top, plot.Left, plot.Bottom);
        for (int tick = 0; tick <= 4; tick++) …                    // 0/25/50/75/100

        // 柱子：值 → 高度 → 倒扣着定位（GDI+ y 轴向下！）
        for (int i = 0; i < _values.Length; i++)
        {
            float h = plot.Height * _values[i] / (float)max;
            var bar = new RectangleF(plot.Left + i * slot + (slot - barW) / 2,
                                     plot.Bottom - h, barW, h);     // ★ y = 底边 - 高
            g.FillRectangle(brush, bar);
            g.DrawString(_values[i].ToString(), Font, Brushes.Black, bar.X, bar.Y - Font.Height);
        }
    }

    public void Randomize(Random rng) { …; Invalidate(); }          // 改数据 → 失效重绘
}
```

**y 轴向下**是 GDI+ 坐标系的头号常识：画"从底往上"的柱子 = `y = 底边 - 高`。改数据记得 `Invalidate()`（12 章的定律）。

## 2. 图片验证码（书的 9.4.2 现代版）

核心三板斧：**随机字符 + 每字旋转 + 干扰线**，画进 Bitmap 给 PictureBox：

```csharp
const string pool = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";   // 去掉易混字符 I1O0
char[] chars = new char[4];
for (int i = 0; i < 4; i++) chars[i] = pool[_rng.Next(pool.Length)];

var bmp = new Bitmap(160, 48);
using (var g = Graphics.FromImage(bmp))       // ★ 位图上的 Graphics（与 OnPaint 无关的画布）
{
    g.Clear(Color.AliceBlue);
    using var font = new Font("Consolas", 20F, FontStyle.Bold);
    for (int i = 0; i < 4; i++)
    {
        g.TranslateTransform(20 + i * 34, 24);            // 挪到每个字的格心
        g.RotateTransform(_rng.Next(-25, 26));            // 每字随机歪 ±25°
        var size = g.MeasureString(_code[i].ToString(), font);
        g.DrawString(_code[i].ToString(), font, inkBrush,
                     -size.Width / 2, -size.Height / 2);  // 以格心为中心
        g.ResetTransform();                               // ★ 画完一个必须复位
    }
    for (int i = 0; i < 6; i++)                           // 干扰线
        g.DrawLine(pen, _rng.Next(160), _rng.Next(48), _rng.Next(160), _rng.Next(48));
}
_captcha.Image = bmp;
```

## 3. 坐标变换：Translate + Rotate

`Graphics` 自带可累积的坐标变换矩阵：

| 调用 | 作用 |
|---|---|
| `TranslateTransform(dx, dy)` | 坐标系平移（原点挪走） |
| `RotateTransform(deg)` | 坐标系旋转（度，顺时针） |
| `ScaleTransform(sx, sy)` | 坐标系缩放 |
| `ResetTransform()` | 复位回恒等 |

**"先挪原点再旋转再画"** 是套路中的套路——旋转文字（13 示例的动画区）：

```csharp
g.TranslateTransform(bmp.Width / 2f, bmp.Height / 2f);   // 原点搬到中心
g.RotateTransform(_angle);                               // 旋转坐标系
var size = g.MeasureString(text, font);
g.DrawString(text, font, Brushes.RoyalBlue, -size.Width / 2, -size.Height / 2);
//                                                    ★ 以新原点为中心对称画 = 绕中心转
```

变换是**状态**——`ResetTransform()` 不调，下一个字 inherits 上一个字的歪（验证码示例的实测提醒）。

## 4. 位图的生老病死

动画每帧 new 一个 Bitmap，旧的不放 = 内存狂涨：

```csharp
var old = _spin.BackgroundImage;
_spin.BackgroundImage = bmp;
old?.Dispose();                       // 旧位图手动释放
```

PictureBox.Image 同理。Bitmap/Pen/Brush/Font 都是 IDisposable——高频生成场景必须换旧。

## 5. 三语言差异

**F#**——验证码函数是"纯生产者"（返回 `(code, bmp)` 二元组），UI 侧只管贴：

```fsharp
let makeCaptcha (rng: Random) =
    let code = String.init 4 (fun _ -> string pool.[rng.Next pool.Length])
    let bmp = new Bitmap(160, 48)
    use g = Graphics.FromImage bmp
    …
    code, bmp
```

旧位图判空释放没有 `?.`，用模式匹配：

```fsharp
match captcha.Image with
| null -> ()
| old -> old.Dispose()
```

**C++/CLI**——`Random` 的负数参数直接写（`_rng->Next(-25, 26)` 没问题），但**两个 Random 类名撞车**（`System` 与 `System::Drawing`? 不——是 F# 版本才有的坑），C++ 版的注意点是句柄穿透：

```cpp
String^ one = _code->Substring(i, 1);
auto size = g->MeasureString(one, %font);     // %：栈语义对象传给要句柄的调用
```

## 坑位清单

1. 柱子画成"从顶往下长"——忘了 y 轴向下，`y = 底边 - 高` 才对。
2. `RotateTransform` 后忘 `ResetTransform`——下一个字 inherit 歪斜，越画越斜。
3. 动画每帧 new Bitmap 不 Dispose 旧的 → 内存一路涨（任务管理器肉眼可见）。
4. 验证码字符池没去 I/1/O/0 → 用户骂娘（分不清就是你的锅）。
5. `Random` 实例每帧重建 → 种子相近，"随机"图样重复（一个 `Random` 字段用到底）。

## 自测

1. 柱形图纵轴固定 0..100 而不是跟随数据的最大值，好处是什么？
2. 验证码"以格心为中心画字"用了哪两个变换 + 什么坐标偏移？
3. `Graphics.FromImage` 与 `e.Graphics` 的来源区别？
4. 变换矩阵为什么是"状态"？忘记复位会怎样？
5. 高频动画场景位图的生命周期规矩？
