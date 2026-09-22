# 19 · 表格控件：TStringGrid 与 TDrawGrid（⭐）

表格是 LCL 控件库里最深的一块。两个控件一个家族（unit Grids）：

- **TStringGrid**：替你存（Cells）、替你编（内置编辑器）、替你画（默认网格线）——
  "数据表"用它。
- **TDrawGrid**：什么都不替你——每格画什么全是你（OnDrawCell 必须实现），
  但换来"格子只是坐标、数据随便放哪"的自由——像素板、棋盘、时间轴用它。

## 1. TStringGrid 基础：Cells[列, 行]

```pascal
Grid := TStringGrid.Create(Self);       // unit Grids
Grid.ColCount := 4;
Grid.RowCount := 5;
Grid.FixedRows := 1;                    // 首行表头：灰底、不随滚动、可点（排序）
Grid.Cells[0, 0] := '姓名';             // Cells[列, 行]——列在前！
Grid.Rows[1].CommaText := '张三,77,84,80.5';    // 整行视图（TStrings）
```

`Cells[列, 行]` 是全 LCL 最经典的下标手误点：与"先行后列"的直觉相反。
第 2 行第 0 列的学生是 `Cells[0, 2]`（19a 工程断言：值='李四'）。

行/列的动态调整有整套现成方法：

```pascal
Grid.InsertRowWithValues(Grid.RowCount, ['新同学', '60', '60', '60.0']);
Grid.DeleteRow(Grid.Row);               // Row/Col = 当前选中格
Grid.ExchangeColRow(True, 0, 1);        // 换列（True）/换行（False）
```

## 2. Options：能力开关集合

默认集是"纯展示"（网格线 + 范围选择）。加什么得什么：

```pascal
Grid.Options := Grid.Options
  + [goEditing, goColSizing, goTabs, goCellEllipsis, goDrawFocusSelected];
```

| 开关 | 语义 |
|---|---|
| `goEditing` | F2/双击进单元格编辑（配 19.3 校验） |
| `goColSizing`/`goRowSizing` | 拖列宽/行高 |
| `goTabs` | Tab/Shift+Tab 在格间跳 |
| `goCellEllipsis` | 放不下的文字显示省略号 |
| `goRowSelect` | 整行选择（与 goEditing 互斥语义） |
| `goRangeSelect` | 拖拽框选区域 |
| `goAlwaysShowEditor` | 编辑器常驻 |
| `goThumbTracking` | 滚动条拖动时实时滚动 |

## 3. 编辑与校验：OnValidateEntry

goEditing 开了以后，用户按回车提交——但"语文成绩输 150"怎么拦？
`OnValidateEntry` 是提交的最后一关：

```pascal
procedure TGridForm.GridValidateEntry(Sender: TObject; ACol, ARow: Integer;
  const OldValue: string; var NewValue: String);
begin
  if ACol in [1, 2] then
    if not TryStrToInt(NewValue, V) or (V < 0) or (V > 100) then
      NewValue := OldValue;      // 拒绝 = 把 var NewValue 改回旧值（没有别的通道）
end;
```

**要点**：事件没有"取消"返回值，拒绝的唯一方式是把 `var NewValue` 写回
`OldValue`。直呼这个处理器可以模拟一次提交（19a 的 selftest 就这么测的）。

`OnSelectCell(Sender, ACol, ARow, var CanSelect)` 是选中前的一关——
`CanSelect := False` 可以禁止选中某些格（比如合计行）。

## 4. 逐格换笔：OnPrepareCanvas（比全自绘轻）

"不及格标红"不需要自己画格子——每格绘制**前**网格会问一次笔怎么配：

```pascal
procedure TGridForm.GridPrepareCanvas(Sender: TObject; ACol, ARow: Integer;
  AState: TGridDrawState);
begin
  if ARow = 0 then
    Grid.Canvas.Font.Bold := True                    // 表头加粗
  else if (ACol in [1, 2]) and TryStrToInt(Grid.Cells[ACol, ARow], V) and (V < 60) then
    Grid.Canvas.Font.Color := clRed;                 // 不及格红字
end;
```

分工：改字体/颜色/画笔 → OnPrepareCanvas（其余照默认画）；连背景、边框都要
自己来 → OnDrawCell（全自绘）。90% 的"美化"需求 OnPrepareCanvas 就够。

## 5. 排序：内建与自管，两条路

**坑（实测）**：LCL 网格**默认就有点表头自动排序**（`ColumnClickSorts`）。
如果你又在 OnHeaderClick 里自己排一次——排序做两遍、方向翻两次，
**净效果等于没排**（19a 首轮实测：降序变升序）。先决定谁管排序。

路 A——内建（点表头即排，零代码维护）：

```pascal
Grid.ColumnClickSorts := True;
Grid.OnCompareCells := @GridCompareCells;    // 不设 = 纯字符串比较
```

比较器里做数值语义（默认字符串序会把 "9" 排在 "80" 后面——经典坑）：

```pascal
procedure TGridForm.GridCompareCells(Sender: TObject; ACol, ARow, BCol, BRow: Integer;
  var Result: Integer);
begin
  if (ACol in [1, 2]) and TryStrToInt(Grid.Cells[ACol, ARow], A)
    and TryStrToInt(Grid.Cells[BCol, BRow], B) then
    Result := A - B                          // 数值列：负 = A 在前
  else
    Result := AnsiCompareText(Grid.Cells[ACol, ARow], Grid.Cells[BCol, BRow]);
end;
```

路 B——自管（要程序化触发、要稳定序、要跨列联动时）：

```pascal
Grid.ColumnClickSorts := False;      // 关掉内建，OnHeaderClick 只记账
// SortByCol：快照数据行 → 自己排序 → 写回（19a 的 SortByCol 全文可查）
```

自管排序的骨架是"快照-排序-回写"：把 `Cells` 抽进二维动态数组、排序、
再写回去——顺带获得稳定性和多列联动的控制权。

## 6. TDrawGrid：格子只是坐标

DrawGrid 没有 Cells（TCustomGrid 的存储层整个砍掉），OnDrawCell **必须**
实现，否则白板：

```pascal
Grid := TDrawGrid.Create(Self);
Grid.ColCount := 8;  Grid.RowCount := 8;
Grid.FixedRows := 0;  Grid.FixedCols := 0;      // 无表头形态（StringGrid 少见）
Grid.DefaultColWidth := 40;  Grid.DefaultRowHeight := 40;

procedure TPixelForm.GridDrawCell(Sender: TObject; ACol, ARow: Integer;
  aRect: TRect; aState: TGridDrawState);
begin
  Grid.Canvas.Brush.Color := Cells[CellIndex(ACol, ARow)];   // 数据在自己的数组里
  Grid.Canvas.FillRect(aRect);
end;
```

鼠标点格换色：`OnMouseDown` 里 `Grid.MouseToCell(X, Y, C, R)` 把像素坐标
翻成格坐标。19b 是 8×8 像素画板：模型（`array[0..63] of TColor`）与视图
（DrawGrid）完全解耦——**改模型 → Invalidate**，画板逻辑可以无句柄测试。

模型寻址注意：事件给你 `(列, 行)`，数组按行主序存 `[行*N+列]`——两套坐标
换算别搞反（CellIndex 函数就干这一件事，selftest 断言 CellIndex(3,5)=43）。

## 7. 选型表

| 场景 | 用 |
|---|---|
| 可编辑数据表（成绩/清单） | TStringGrid + goEditing + OnValidateEntry |
| 只读报表（美化） | TStringGrid + OnPrepareCanvas |
| 棋盘/画板/日历格 | TDrawGrid + 自管模型 |
| 大数据量（万行） | TDrawGrid 或 ListView OwnerData（26 章） |

## 8. 示例与验证

```powershell
pwsh -File build.ps1 -Example 19a_stringgrid   # 成绩表：编辑/校验/红字/排序
pwsh -File build.ps1 -Example 19b_drawgrid     # 8×8 像素画板：模型视图分离
```

selftest 覆盖：Cells[列,行] 语义、Rows[] 视图、OnValidateEntry 直呼模拟提交
（150 退回旧值、88 放行）、自管排序升降序（含数值序防 "9>80"）、
InsertRowWithValues/DeleteRow、DrawGrid 无固定行列形态、CellIndex 换算、
调色循环、固定种子随机可复现。

## 9. 坑位清单（实测）

1. **双重排序**：ColumnClickSorts 默认路径 + OnHeaderClick 里再排 = 方向翻两次，
   实测净效果等于没排——自己管就先 `ColumnClickSorts := False`。
2. 默认排序是**字符串序**：数值列必须挂 OnCompareCells（"9" > "80"）。
3. `Cells[列, 行]` 列在前——全 LCL 头号下标手误。
4. OnValidateEntry 拒绝 = `NewValue := OldValue`（没有取消通道）。
5. OnPrepareCanvas 里改的是**共享 Canvas 的当前笔**——每次都会被重置，别缓存。
6. DrawGrid 不实现 OnDrawCell 就是白板（没有任何默认绘制）。
7. MouseToCell 给的坐标与自管数组下标是两套体系，换算函数单独写。
8. 计数器/数组等非类字段别放类声明默认区（published 只收类类型），显式 public。

---
上一章：[18 选择器控件](18-picker-controls.md) ｜ 下一章：[20 多页容器](20-tab-pages.md) ｜ 返回：[README](../README.md)
