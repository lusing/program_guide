# 06 · 选择类控件：RadioButton、ComboBox、CheckedListBox、DateTimePicker、TrackBar

> 对应示例：`examples/06_selection`（两组互斥单选 + 城市下拉 + 兴趣勾选 + 日期 + 音量滑块 + 汇总）

> **本章你将学会**：RadioButton 的互斥范围、ComboBox 三种风格、CheckedListBox、DateTimePicker、TrackBar。
> **前置章节**：[04 布局](04-layout.md)、[05 文本控件](05-controls-text.md)。

## 1. RadioButton：互斥范围 = 直接容器

**同一容器内的 RadioButton 自动互斥**。想要两组各自互斥，就分装进两个 GroupBox：

```csharp
var deptBox = new GroupBox { Text = " 部门（互斥组 A）", … };   // 研发/测试/设计
var typeBox = new GroupBox { Text = " 用工类型（互斥组 B）", … }; // 全职/实习
```

不分组全塞一个 Panel 里，六个按钮只能选一个——新手第一大坑。默认选中要显式设：

```csharp
((RadioButton)_deptFlow.Controls[0]).Checked = true;
```

注意 `CheckedChanged` 在**取消勾选时也触发**，读状态要判 `Checked`：

```csharp
rb.CheckedChanged += (s, e) => { if (rb.Checked) _status.Text = $"  部门 → {rb.Text}"; };
```

## 2. ComboBox：三种 DropDownStyle

| 风格 | 能输入吗 | 典型用途 |
|---|---|---|
| `DropDown`（默认） | 能 | 可输入的联想选择 |
| `DropDownList` | 不能 | **枚举值选择（最常用）** |
| `Simple` | 能，列表常驻 | 少见 |

```csharp
_city.DropDownStyle = ComboBoxStyle.DropDownList;
_city.Items.AddRange(new object[] { "北京", "上海", … });
_city.SelectedIndex = 0;                       // 默认选中第一项
_city.SelectedIndexChanged += (s, e) => …;    // SelectedItem / SelectedIndex
```

## 3. CheckedListBox：勾选列表

```csharp
_hobbies.CheckOnClick = true;                  // 点一次就勾上（默认要点两下！）
foreach (int i in _hobbies.CheckedIndices)     // 汇总读法
    hobbies.Add((string)_hobbies.Items[i]);
```

`CheckOnClick = true` 几乎总是要设的——默认行为是第一下选中、第二下才勾，用户会以为坏了。

## 4. DateTimePicker 与 TrackBar

```csharp
_date.Format = DateTimePickerFormat.Long;      // Long/Short/Time/Custom（配 CustomFormat）
_date.Value = DateTime.Today;
_date.ValueChanged += (s, e) => …;             // Value 是 DateTime

_volume.Minimum = 0; _volume.Maximum = 100;
_volume.TickFrequency = 10;                    // 刻度密度
_volume.Scroll += (s, e) => …;                 // 拖动时连续触发（ValueChanged 只在停点触发）
```

## 5. 汇总：读控件的姿势

06 示例的"汇总我的选择"把五种控件一起读：

```csharp
private string DescribeSelections()
{
    var hobbies = new List<string>();
    foreach (int i in _hobbies.CheckedIndices)
        hobbies.Add((string)_hobbies.Items[i]);
    return $"部门：{CheckedText(_deptFlow)}\n用工：{CheckedText(_typeFlow)}\n" +
           $"城市：{_city.SelectedItem}\n入职：{_date.Value:yyyy-MM-dd}\n音量：{_volume.Value}\n" +
           $"兴趣：{(hobbies.Count == 0 ? "（无）" : string.Join("、", hobbies))}";
}
```

遍历找选中项的写法（C# 模式匹配版）：

```csharp
foreach (Control c in flow.Controls)
    if (c is RadioButton { Checked: true } rb)
        return rb.Text;
```

## 6. 三语言差异

**F#**——找选中项用 `Seq` 更顺：

```fsharp
let checkedText (flow: FlowLayoutPanel) =
    flow.Controls
    |> Seq.cast<Control>
    |> Seq.tryPick (fun c ->
        match c with
        | :? RadioButton as rb when rb.Checked -> Some rb.Text
        | _ -> None)
    |> Option.defaultValue "（未选）"
```

汇总勾选项：

```fsharp
let picked = [ for i in hobbies.CheckedIndices -> string hobbies.Items.[int i] ]
```

**C++/CLI**——单选按钮的处理器里，`sender` 就是那个 RadioButton：

```cpp
void OnDeptChanged(Object^ s, EventArgs^ e)
{
    auto rb = safe_cast<RadioButton^>(s);
    if (rb->Checked)
        _status->Text = String::Format(L"  部门 → {0}", rb->Tag);
}
```

汇总勾选项用 `CheckedItems` 直接遍历（比按索引取省事）：

```cpp
for each (Object^ o in _hobbies->CheckedItems) { … }
```

## 坑位清单

1. 两批 RadioButton 没分组 → 全体互斥只剩一个能选中。
2. `CheckedChanged` 忽略了"取消也触发"→ 状态闪变（判 `Checked` 再干活）。
3. CheckedListBox 没设 `CheckOnClick = true` → 用户点一下以为没反应。
4. ComboBox 用默认 `DropDown` 又没做校验 → 用户输入了列表外的值（`SelectedItem` 为 null 的来源）。
5. F# 枚举成员当实参：`Directory.GetFiles(path, "*.txt", SearchOption.TopDirectoryOnly)` 里点取的枚举会报 FS0691（解析成命名参数）——括号包住调用或先 let。

## 自测

1. 为什么 RadioButton 分组靠容器而不是属性？
2. `DropDownList` 与 `DropDown` 的本质区别？各适合什么场景？
3. `Scroll` 与 `ValueChanged`（TrackBar）触发时机的差别？
4. `CheckedIndices` 和 `CheckedItems` 各返回什么？
5. `CheckedChanged` 里不判 `Checked` 会看到什么现象？
