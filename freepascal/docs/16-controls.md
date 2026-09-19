# 16 · 基础控件与事件模型（⭐）

## 1. 事件是方法指针——语言篇的最后一根线接上了

08 章讲过 `function(...): ... of object` 的**方法指针**。LCL 事件的全部秘密就是它：

```pascal
TNotifyEvent = procedure(Sender: TObject) of object;
```

```pascal
// 窗体类里声明方法
procedure TPlaygroundForm.BtnClearClick(Sender: TObject);
begin
  Log.Clear;
end;

// 创建控件后把方法挂上去（objfpc 模式赋值带 @——08 章过程类型的 GUI 版）
BtnClear.OnClick := @BtnClearClick;
```

一条链：消息循环（Application.Run）→ 平台事件 → 控件触发 OnClick → 经方法指针调到
你的方法。**没有魔法，只有指针**——理解了 08 章，GUI 事件就是查表。

**Sender**：事件的肇事者。一个处理器服务多个控件时靠它分辦：

```pascal
procedure TPlaygroundForm.AnyClick(Sender: TObject);
begin
  LogLine(Format('[OnClick] Sender=%s', [(Sender as TControl).Caption]));
end;
// 三个按钮都挂 @AnyClick，点谁日志里就是谁——"一拖多"的标准姿势
```

## 2. 纯代码创建控件：五步曲

本章示例不用 .lfm，全部控件代码创建（"每个控件怎么来的"全在眼前）：

```pascal
constructor TPlaygroundForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);         // ① CreateNew：跳过 lfm 流加载（15 章坑）
  Caption := '16 · 控件与事件';        // ② 设窗体属性
  Width := 520; Height := 480;

  BtnClear := TButton.Create(Self);    // ③ Create(Owner)：Owner=Self（窗体销毁时连坐 Free）
  BtnClear.Parent := Panel;            // ④ Parent：显示在哪个容器里（与 Owner 两码事！）
  BtnClear.SetBounds(8, 36, 96, 24);   // ⑤ 位置 + 属性 + 事件
  BtnClear.Caption := '清空日志';
  BtnClear.OnClick := @BtnClearClick;
end;
```

**Owner 与 Parent 的分工**（VCL/LCL 的核心概念对）：

| | Owner | Parent |
|---|---|---|
| 回答的问题 | 谁负责 Free 我 | 我显示在谁里面 |
| 机制 | TComponent 所有权链（12 章） | WinControl 嵌套（坐标相对它） |
| 混淆后果 | 忘设 Owner → 泄漏；忘设 Parent → **控件不显示**（最常见的"按钮去哪了"） |

## 3. 文本类：Label / Edit / Memo

| 控件 | 用途 | 关键属性/事件 |
|---|---|---|
| `TLabel` | 只读文本 | `Caption`（自动按内容变宽；`Alignment` 对齐） |
| `TEdit` | 单行输入 | `Text`、`TextHint`（占位提示）、`PasswordChar`；`OnChange`、`OnKeyDown` |
| `TMemo` | 多行文本 | `Lines: TStrings`（`Add/Clear/Text`）、`ReadOnly`、`ScrollBars` |
| `TLabeledEdit` | 带浮动标签的输入框 | `EditLabel.Caption`——省一排对齐代码 |

`Caption`（按钮/标签/窗体的"标题"）与 `Text`（编辑类的"内容"）**是两个属性名**——
历史如此，记即可。TMemo 是 24 章记事本的主角，`Lines` 是字符串列表（11 章 TStringList
同族）。

## 4. 按钮类：Button / BitBtn / SpeedButton / ToggleBox

| 控件 | 特点 | 什么时候用 |
|---|---|---|
| `TButton` | 标准按钮，占 Tab 顺序 | 默认选择 |
| `TBitBtn` | 带图标的按钮（`Glyph`），可设 `ModalResult`（20 章对话框） | 对话框确定/取消 |
| `TSpeedButton` | **不占 Tab**、可保持按下（`GroupIndex`/`AllowAllUp`） | 工具栏按钮（19 章） |
| `TToggleBox` | 两态按钮（按住/弹起） | 开关 |

## 5. 选择类：CheckBox / RadioButton / RadioGroup / ComboBox

```pascal
ChkBold.Checked := True;                 // 复选：独立开关
RadioLang.Items.Add('Pascal');           // 单选组：Items 填选项
RadioLang.ItemIndex := 0;                // 互斥：只能选一
ComboFruit.ItemIndex := -1;              // 下拉：-1 = 未选；csDropDownList 不可输入
```

- `TRadioGroup` 自带边框和标题（`Caption`），选项用 `Items`——单选的省心封装；
  裸 `TRadioButton` 需要自己管分组（放同一个 Parent 里即一组）。
- `TComboBox.Style`：`csDropDown`（可输入）/`csDropDownList`（只能选）——
  数据校验场景用后者。

## 6. 容器类：GroupBox / Panel / ScrollBox

- `TGroupBox`：带标题的分组框（视觉分区 + 单选天然成组）。
- `TPanel`：无标题容器——布局的乐高（17 章 Align/Anchors 的主角）。
- `TScrollBox`：内容超界自动出滚动条。

容器嵌套 = UI 树：`Self → Panel → EdName`。`Parent` 链决定坐标与裁剪；
`Controls[]`/`ControlCount` 可遍历子控件。

## 7. 事件触发实测：程序化赋值因控件而异

想"代码里替用户操作"时必读（selftest 实测矩阵）：

| 赋值 | 触发的事件 |
|---|---|
| `Edit.Text := 'x'` | `OnChange` ✓ |
| `CheckBox.Checked := True` | `OnClick` ✓ |
| `RadioGroup.ItemIndex := 1` | `OnSelectionChanged` ✓ |
| `ComboBox.ItemIndex := 2` | `OnChange` ✗（**不触发**） |

不触发的场景要么显式调处理器方法，要么用控件自己的 `Click()`/`SelectAll()` 类命令方法。
**别赌触发行为**——跨控件集（win32/gtk2）还可能有差异，selftest 里对确定行为断言、
对不确定行为显式调用。

## 8. 键盘与焦点

```pascal
procedure TPlaygroundForm.EdNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 13 then ...          // 13 = Enter；命名常量 VK_RETURN 在 LCLType 单元
end;
```

- 三连：`OnKeyDown`（键码，`var Key` 可改可清零吞键）→ `OnKeyPress`（字符）→ `OnKeyUp`。
- Tab 顺序 = 控件创建顺序（`TabOrder` 可改）；`SetFocus` 程序内给焦点；
  `ActiveControl` 是当前焦点控件。
- `Enabled := False` 灰掉不响应；`Visible := False` 直接不显示（占位还在布局计算里）。

## 9. 示例与验证

本章示例 `examples/16_controls`：事件日志窗体（纯代码创建全部控件），覆盖
OnClick/OnChange/OnKeyDown/OnSelectionChanged + Sender 一拖多 + 上面的事件触发矩阵。

```powershell
pwsh -File build.ps1 -Example 16_controls      # lazbuild + 无头 selftest（含事件断言）
```

正常路径双击 exe：输入框打字看 OnChange 计字节、点各控件看事件日志滚动。

## 10. 坑位清单（实测）

1. **忘设 Parent 控件不显示**（Owner 管 Free、Parent 管显示——两码事）。
2. 程序化赋值触发事件**因控件而异**：ComboBox.ItemIndex 不触发 OnChange（§7 矩阵）。
3. objfpc 模式事件赋值带 `@`（`OnClick := @Click`）——Delphi 模式不带，老代码两版混看。
4. OnKeyDown 的 `Key` 是 `var` 参数——想吞键把它置 0；测试里调它也得传变量不能传字面量。
5. `Caption` 与 `Text` 分属两族控件——写错属性名是编译错误，好事。
6. `TForm.CreateNew` 只属于 TForm；纯代码窗体用它避开 lfm 流加载（15 章）。

---
上一章：[15 Lazarus 入门](15-lazarus.md) ｜ 下一章：[17 更多控件](17-more-controls.md) ｜ 返回：[README](../README.md)
