# 17 · 更多控件（⭐）

16 章覆盖"每个界面都要用"的控件；本章补齐**数值、日期、颜色、表格、多页、图片、复用**
七类——过完这章，LCL 常用控件面板的 80% 你都用代码摸过了。

## 1. 数值类：TrackBar / SpinEdit / ProgressBar

```pascal
Track := TTrackBar.Create(Self);        // 滑杆：Min..Max 连续取值
Track.Min := 0; Track.Max := 100;
Track.Position := 30;
Track.OnChange := @TrackChange;         // 拖动/程序赋值都触发（实测 ✓）

Spinner := TSpinEdit.Create(Self);      // 数字输入框（unit Spin）：上下箭头步进
Spinner.MinValue := 0; Spinner.MaxValue := 1000;
Spinner.Value := 42;                    // Integer 类型安全——StrToInt 都省了

Progress := TProgressBar.Create(Self);  // 进度条：Min/Max/Position
Progress.Position := 60;                // 23 章多线程回传进度的标配
```

SpinEdit 直接给 Integer（不用字符串转换）——表单里的数字输入一律用它，
比 TEdit+StrToInt 少一道转换错误。

## 2. 日期类：Calendar（与 DateTimePicker 的取舍）

```pascal
Cal := TCalendar.Create(Self);          // unit Calendar：月历控件
Cal.DateTime := EncodeDate(2026, 9, 19);
// 读取：Cal.DateTime（TDateTime，11 章日期家族）
```

**包依赖知识点**：`TDateTimePicker`（下拉式日期/时间选择）在**独立包 datetimectrls**
里，不在基础 LCL——要用它，.lpi 的 RequiredPackages 得加：

```xml
<RequiredPackages Count="2">
  <Item1><PackageName Value="LCL"/></Item1>
  <Item2><PackageName Value="DateTimeDlgs"/></Item2>   <!-- 实际包名 datetimectrls -->
</RequiredPackages>
```

（IDE 里拖一个控件到窗体，包会被自动加进 .lpi——这是 IDE 相对手写的真实优势。）
本章示例用纯 LCL 的 TCalendar 讲解日期语义，Picker 的 API 几乎同款。

## 3. 颜色类：ColorBox / ColorListBox

```pascal
ColorBox := TColorBox.Create(Self);     // unit ColorBox：系统色下拉（项自绘）
ColorBox.Selected := clRed;             // TColor 类型；ColorToString(clRed) = 'clRed'
```

`TColor` 是 Integer 别名（`clRed=$0000FF` 或 `clRed` 命名常量）；`RGB(r,g,b)` 组色。
自绘颜色下拉不用写一行绘图代码（21 章自绘原理的现成受益者）。

## 4. TStringGrid：表格（本章重头）

```pascal
Grid := TStringGrid.Create(Self);       // unit Grids
Grid.ColCount := 3;
Grid.RowCount := 4;
Grid.FixedRows := 1;                    // 首行表头：灰底、不可编辑、随滚动锁定
Grid.Options := Grid.Options + [goEditing];   // 开编辑（F2/双击进单元格）
Grid.Cells[0, 0] := '姓名';             // Cells[列, 行]——注意是列在前！
Grid.Cells[0, 1] := '张三';
Grid.OnSelectCell := @GridSelectCell;   // 选中事件（var CanSelect 可否决）
```

常用能力速查：

| 需求 | 做法 |
|---|---|
| 表头 | `FixedRows/FixedCols` |
| 可编辑 | Options 加 `goEditing`（可选 `goAlwaysShowEditor`） |
| 动态行列 | `RowCount/ColCount` 直接改（行数据保留） |
| 整行选择 | Options 加 `goRowSelect` |
| 遍历 | 双层 for 访问 `Cells[c, r]` |
| 大数据 | 遇到性能墙时换虚拟模式（OnGetEditText 按需供给）——本教程不展开 |

`Cells[列, 行]` 的列在前是**经典手误点**（与"先行后列"的直觉相反）；3,4 列的小表无妨，
大表建议封一层 `CellText(r, c)`。

## 5. TTabControl vs TPageControl：轻标签 vs 多页容器

```pascal
// TTabControl：只有一排标签头——"同一块内容换视图"
Tabs.Tabs.Add('标签 A');
Tabs.TabIndex := 0;                     // 换标签时 OnChange 里你自己切内容

// TPageControl：每页一个 TTabSheet 容器（各装各的控件）
page := Pages.AddTabSheet;              // 动态加页
page.Caption := '页 1';
Label.Parent := page;                   // 控件挂到页上
Pages.PageCount;                        // 页数
Pages.Pages[i]                          // 取第 i 页（TTabSheet）
Pages.ActivePage                        // 当前页
```

选择：**视图切换**（同一数据不同呈现）用 TabControl 轻量；**内容分区**（每页独立控件）
用 PageControl——24 章记事本+ 的多标签就是 PageControl + 动态 TTabSheet（每页一个 TMemo）。

## 6. TImage：图片位（程序画也行）

```pascal
Img.Picture.Bitmap.SetSize(120, 90);            // 直接操作位图
Img.Picture.Bitmap.Canvas.Brush.Color := clSkyBlue;
Img.Picture.Bitmap.Canvas.FillRect(0, 0, 120, 90);
Img.Picture.Bitmap.Canvas.Ellipse(20, 15, 100, 75);
```

- 加载文件：`Img.Picture.LoadFromFile('x.png')`（TPicture 按扩展名分发格式）。
- 程序画图直接拿 `Picture.Bitmap.Canvas`（21 章 Canvas 全章细讲；本章 selftest
  就用像素验证：椭圆中心必须是黄色、角落必须是背景色——位图离屏可查，`Pixels[x,y]`）。
- `Stretch/Proportional/AutoSize` 控制缩放行为。

## 7. TFrame：复用的控件组合板

TFrame = "可嵌入窗体的迷你窗体"：一组控件打包、多次使用（例如"地址块""页头"）。

**实测要点**：Frame 与 .lfm **天生配对**——`TFrame.Create` 会找同名流资源；
没有 .lfm 就报 `Resource THeaderFrame not found`（纯代码建窗体的 `CreateNew` 对
Frame **不存在**）。所以 Frame 的标准形态是独立单元：

```text
uheaderframe.pas   类声明 + {$R *.lfm} + 事件方法
uheaderframe.lfm   控件描述（与窗体 lfm 同一种格式）
```

使用处只要两行：

```pascal
FrameA := THeaderFrame.Create(Self);   // 流加载发生在 Create 里
FrameA.Parent := SomePanel;            // 挂进任意容器——复用达成
```

自带的 `ClickCount`/`LblTitle` 证明：Frame 是真类——加公共字段/方法、写子事件，
和窗体一模一样（selftest 实测事件计数与标题更新）。

## 8. 控件地图：本教程 GUI 篇的剩余章节

| 还缺什么 | 在哪章 |
|---|---|
| 菜单/工具栏/Action 统一命令 | 19 |
| 对话框（打开/保存/字体/查找） | 20 |
| ListView/TreeView（真列表视图） | 21 |
| 自绘（Canvas 全解） | 22 |
| 多线程进度回传 | 23 |

## 9. 示例与验证

本章示例 `examples/17_more_controls`（三文件工程：lpr + frame 单元对）：数值/日期/
颜色/表格/双标签控件/Image/TFrame 全家，selftest 含位图像素级断言。

```powershell
pwsh -File build.ps1 -Example 17_more_controls
```

## 10. 坑位清单（实测）

1. `TFrame` 没有 `CreateNew`——Create 必须找到同名 lfm 资源，缺了报
   `Resource xxx not found`（与 15 章纯代码窗体正好相反）。
2. `TDateTimePicker` 在独立包 datetimectrls——.lpi 加包或用 IDE 拖（本章用 TCalendar）。
3. `StringGrid.Cells[列, 行]`——**列在前**，与直觉相反。
4. TSpinEdit 属 `unit Spin`、TColorBox 属 `unit ColorBox`、TCalendar 属 `unit Calendar`——
   各有独立 uses，漏引报 Identifier not found。
5. TImage 画图改的是 `Picture.Bitmap.Canvas`；直接 `Img.Canvas` 画会被下次重绘冲掉。
6. TTabControl 换页**不会**自动换内容（它只有标签头）；要内容隔离用 TPageControl。

---
上一章：[16 基础控件与事件模型](16-controls.md) ｜ 下一章：[18 布局与高 DPI](18-layout.md) ｜ 返回：[README](../README.md)
