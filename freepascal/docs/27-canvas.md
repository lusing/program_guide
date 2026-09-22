# 22 · 绘图与自绘（⭐）

## 1. TCanvas：三件套 + 坐标系

每个能画图的东西（窗体、位图、打印机）都有 Canvas。Canvas 的三件套：

| 成员 | 管什么 | 常用属性 |
|---|---|---|
| `Pen` | 线（描边） | Color、Width、Style（psSolid/psDash/psDot） |
| `Brush` | 面（填充） | Color、Style（bsSolid/bsClear=不填） |
| `Font` | 文字 | Color、Size、Name、Style |

坐标是像素、原点左上、Y 向下——GDI 传统。基本原语全家（本章示例全部像素级验证过）：

```pascal
Canvas.Pen.Color := clRed;  Canvas.Pen.Width := 2;
Canvas.Line(10, 10, 100, 60);                 // 线段（两点式）
Canvas.Brush.Color := clYellow;
Canvas.Rectangle(120, 10, 200, 60);           // 矩形（左上、右下；Pen 描边 Brush 填充）
Canvas.Ellipse(220, 10, 300, 60);             // 椭圆（外接矩形）
Canvas.RoundRect(...);  Canvas.Arc(...);  Canvas.Polygon(...);   // 同族
Canvas.Font.Size := 14;
Canvas.TextOut(10, 70, '文字');               // 左上角定位写字
h := Canvas.TextHeight('字'); w := Canvas.TextWidth('字');   // 先测量后布局
```

像素读写：`Canvas.Pixels[x, y]`（读写都行；TColor 是 Integer，`$00BBGGRR` 低字节蓝）。
大量逐像素操作慢——用 `TBitmap.RawImage` 或按行批处理（本教程不展开）。

## 2. OnPaint 与无效区：控件不是画完就留着

LCL 的绘制模型是**被动式**：控件区域"脏"了（被遮挡后露出、尺寸变化、你主动
`Invalidate`），系统投递 OnPaint 事件，你在事件里**把整块区域重画**。

```pascal
procedure TDemoForm.PadPaint(Sender: TObject);
begin
  RenderTo(Pad.Canvas);        // OnPaint 里唯一的活：把离屏缓冲整图拷过来
end;
```

三条纪律：

1. **只在 OnPaint 里画**（画了也会被下次重绘冲掉——21 章 TImage 的坑）。
2. **要重画就 `Invalidate`**，别直接画（Invalidate 合并多次请求，稍后统一 OnPaint）。
3. OnPaint 要**快**且**确定性**（同样的状态画出同样的图——这是双缓冲可行的原因，
   也是 selftest 能像素断言的原因）。

## 3. 双缓冲：闪烁的根治（本章核心）

直接在 OnPaint 里逐笔重画 = 用户看到每一笔的过程 = 闪烁。标准解法：

```text
所有笔迹/图形 → 画到【离屏 TBitmap】（Buffer）
       Invalidate
OnPaint → Canvas.Draw(0, 0, Buffer)     ← 一次整图拷贝，用户只看到成品
```

```pascal
Buffer := TBitmap.Create;
Buffer.SetSize(520, 340);                 // 离屏位图就是"画布本体"

procedure TDemoForm.RenderTo(ACanvas: TCanvas);
begin
  ACanvas.Draw(0, 0, Buffer);             // 合成：与目标无关（窗体/打印/测试通吃）
end;
```

示例把 `RenderTo` 抽成独立方法——**合成逻辑与输出目标解耦**，selftest 直接往
第二张位图上合成再逐像素比对（洋红底 + 黄矩形 + 黑笔迹三重验证），这就是可测试的
绘图代码的样子。窗体级偷懒版：`Form.DoubleBuffered := True`（控件级缓冲），
自绘重场合仍推荐显式离屏位图（可控可测）。

## 4. 鼠标画板：事件流 + 双缓冲的合体

```pascal
procedure TDemoForm.PadMouseDown(...; X, Y: Integer);
begin
  FDrawing := True;  FLast := Point(X, Y);      // 记笔迹起点
end;

procedure TDemoForm.PadMouseMove(...; X, Y: Integer);
begin
  if not FDrawing then Exit;
  Buffer.Canvas.Line(FLast, Point(X, Y));       // 笔迹只写离屏缓冲
  FLast := Point(X, Y);
  Pad.Invalidate;                               // 请求重绘（OnPaint 整图拷出）
end;
```

三事件组：OnMouseDown/OnMouseMove/OnMouseUp；X/Y 已是控件局部坐标；
`Shift` 里读 Ctrl/Alt/左中右键。selftest 直接调这三个处理器模拟"画一笔"，
再验笔迹像素——**交互逻辑照样无头可测**。

## 5. TPaintBox vs TImage vs 自绘控件

| 控件 | 位图 | 何时重画 | 适用 |
|---|---|---|---|
| `TPaintBox` | 无（纯 OnPaint 区域） | 每次 Invalidate 全重画 | 实时图（示波器、画板） |
| `TImage` | 有（Picture） | 控件自己管理 | 静态图/加载文件 |
| 自绘控件 | 看实现 | OnPaint/OnDrawItem | 列表自绘、按钮换肤 |

TPaintBox 的内容**不持久**——最小化再还原就触发 OnPaint 重来（所以状态必须在
离屏缓冲或数据里，绝不能"画在 PaintBox 上就不管"）。TImage 反之，改
`Picture.Bitmap.Canvas` 后 Invalidate 一次即可（21 章）。

## 6. 控件自绘一瞥

ListBox/ListView/ComboBox 都有 OwnerDraw 模式：`Style := lbOwnerDrawFixed` +
`OnDrawItem` 事件里拿到 `(Control, Index, Rect, State)` 自己画——背景色、图标、
进度条单元格全靠它。语法与本章 Canvas 完全同源：`Canvas.FillRect(Rect)`、
`Canvas.TextOut(Rect.Left+2, Rect.Top+2, Items[Index])`。18 章的 TColorBox 就是
现成的自绘下拉。

## 7. 示例与验证

本章示例 `examples/27_paint`：离屏缓冲上预画线/矩形/椭圆/文字 + 鼠标画板 +
RenderTo 合成。selftest 六组像素断言全过（线段中点红、矩形内黄、椭圆心蓝、
文字起墨、笔迹命中、合成保真）。

```powershell
pwsh -File build.ps1 -Example 27_paint
```

## 8. 坑位清单（实测）

1. **在 OnPaint 之外画=白画**（下次重绘冲掉）；要刷新走 `Invalidate`。
2. TPaintBox 内容不持久——状态放离屏位图/数据，OnPaint 只做"整图拷贝"。
3. `clBlack = $00000000`——拿"是不是黑"当"有没有墨"判据时，若底色也是黑就失明
   （示例实测：合成验证底色改洋红）。
4. 笔迹/自绘要快——OnPaint 里做慢活（读盘/网络）必然卡 UI。
5. `out` 是保留字不能做变量名（参数方向修饰符）——示例初版踩过。
6. TextOut 定位在左上角且不裁剪——先 TextWidth/TextHeight 测量再摆。

---
上一章：[26 列表与树视图](26-lists.md) ｜ 下一章：[28 多线程与后台任务](28-threads.md) ｜ 返回：[README](../README.md)
