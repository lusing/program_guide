# 15 · DataGridView：能编辑的表格

> 对应示例：`examples/15_datagrid`（订单表：手工列 + 组合框/复选框/按钮列 + 校验 + 条件着色 + 主从联动）

> **本章你将学会**：自动生成 vs 手工列、三种特殊列、CellValidating 校验、CellFormatting 条件着色、主从联动。
> **前置章节**：[14 绑定](14-binding.md)。

## 1. 自动生成 vs 手工列

```csharp
_grid.AutoGenerateColumns = false;              // ★ 关掉自动生成，精确定义
_grid.DataSource = _source;

_grid.Columns.Add(new DataGridViewTextBoxColumn
{
    HeaderText = "单号", DataPropertyName = "Id",   // 绑到 Order.Id
    FillWeight = 10, ReadOnly = true,
});
```

自动生成（默认）适合"快速看数据"；**正式界面一律手工列**——列序、宽度（`FillWeight` 按 `AutoSizeColumnsMode.Fill` 的比例）、只读、格式全在掌握。

## 2. 三种特殊列

```csharp
// 组合框列：下拉选值
var productCol = new DataGridViewComboBoxColumn { HeaderText = "商品", DataPropertyName = "Product" };
productCol.DataSource = new List<string> { "键盘", "鼠标", "显示器", "内存条", "U盘" };

// 复选框列
new DataGridViewCheckBoxColumn { HeaderText = "已付", DataPropertyName = "Paid" };

// 按钮列：每行一个按钮，点击在 CellContentClick 里认列处理
new DataGridViewButtonColumn { HeaderText = "操作", Text = "删除", UseColumnTextForButtonValue = true };
```

```csharp
_grid.CellContentClick += (s, e) =>
{
    if (_grid.Columns[e.ColumnIndex] is DataGridViewButtonColumn &&
        _grid.Rows[e.RowIndex].DataBoundItem is Order doomed)
        _orders.Remove(doomed);           // 从数据删，表格自动跟着变（BindingList 通知）
};
```

单元格格式（货币、右对齐）走 `DefaultCellStyle`：

```csharp
new DataGridViewTextBoxColumn { …, DefaultCellStyle = new DataGridViewCellStyle
    { Format = "C", Alignment = DataGridViewContentAlignment.MiddleRight } }
```

## 3. 校验：CellValidating 困住非法值

```csharp
_grid.CellValidating += (s, e) =>
{
    if (_grid.Columns[e.ColumnIndex].DataPropertyName != "Qty") return;
    if (!int.TryParse(e.FormattedValue?.ToString(), out int qty) || qty < 1 || qty > 99)
    {
        e.Cancel = true;                                  // ★ 光标困在单元格里，出不去
        _grid.Rows[e.RowIndex].ErrorText = "数量必须是 1~99 的整数";   // 行头红感叹号
    }
};
_grid.CellEndEdit += (s, e) => _grid.Rows[e.RowIndex].ErrorText = null;   // 改完清掉
```

`e.Cancel = true` 是"别想离开这个格子"——比事后 MessageBox 的体验好（错误就地显示）。

## 4. 条件着色：CellFormatting

```csharp
_grid.CellFormatting += (s, e) =>
{
    if (e.RowIndex < 0 || _grid.Rows[e.RowIndex].DataBoundItem is not Order row) return;
    e.CellStyle.BackColor = row.Total >= 1000 ? Color.MistyRose : Color.White;   // ★ 反例也要显式设
};
```

两个要点：**从行的 `DataBoundItem` 拿绑定对象**（过滤/排序后行索引对不上你的列表）；**else 分支必须恢复白色**——不恢复，滚动重绘时着色残留。

## 5. 主从联动

```csharp
_customer.SelectedIndexChanged += (s, e) => ApplyFilter();

private void ApplyFilter()
{
    var view = new BindingList<Order>(_orders.Where(o => o.Customer == (string)_customer.SelectedItem).ToList());
    _source.DataSource = view;               // 换一个只装匹配项的视图列表
}
```

`BindingList<T>` **不支持 Filter 字符串**（那是 DataTable/DataView 的特性）——朴素的替代就是重建视图列表（15 示例实测可靠）。要"真过滤器"上 DataTable + `BindingSource.Filter`。

## 6. 三语言差异

**F#**——列的构造与列后回读：

```fsharp
let textCol header prop weight =
    let c = new DataGridViewTextBoxColumn(HeaderText = header, DataPropertyName = prop, FillWeight = weight)
    grid.Columns.Add c |> ignore
textCol "合计" "Total" 14f
grid.Columns.[grid.Columns.Count - 1].ReadOnly <- true      // 加完最后一列改属性
```

校验的 TryParse 模式：

```fsharp
grid.CellValidating.Add(fun e ->
    if grid.Columns.[e.ColumnIndex].DataPropertyName = "Qty" then
        match Int32.TryParse(string e.FormattedValue) with
        | true, qty when qty >= 1 && qty <= 99 -> ()
        | _ -> e.Cancel <- true; grid.Rows.[e.RowIndex].ErrorText <- "数量必须是 1~99 的整数")
```

**C++/CLI**——泛型句柄别忘 `^`：

```cpp
auto view = safe_cast<BindingList<Order^>^>(_source->DataSource);   // 漏 ^ 报 C3149 一串
```

特殊事件有专用委托类型：`DataGridViewCellValidatingEventHandler`、`DataGridViewCellEventHandler`、`DataGridViewCellFormattingEventHandler`。

## 坑位清单

1. 忘了 `AutoGenerateColumns = false` → 手工列和自动列**同时出现**（双份列）。
2. `e.RowIndex` 直接当业务列表索引 → 过滤/排序后错位；用 `DataBoundItem`。
3. CellFormatting 只设真分支 → 滚动后着色残留；反例显式恢复默认色。
4. 按钮列的点击写在 `CellClick` → 点到别处也触发；用 `CellContentClick` 且判列类型。
5. C++/CLI `safe_cast<BindingList<Order^>>`（漏 ^）→ C3149/C3073 连环错。

## 自测

1. `AutoGenerateColumns = false` + `DataPropertyName` 的组合解决什么问题？
2. `CellValidating` 的 `e.Cancel = true` 对用户意味着什么？ErrorText 显示在哪？
3. 为什么 CellFormatting 里要拿 `DataBoundItem` 而不是用行索引查列表？
4. 组合框列的候选值从哪来？和 06 章的 ComboBox 有什么异同？
5. BindingList 的 Filter 缺失，本章的替代方案是什么？

---

上一章：[14 数据绑定](14-binding.md) · 下一章：[16 UI 线程模型](16-threading.md)
