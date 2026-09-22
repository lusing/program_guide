# 21 · 列表与树视图

## 1. 三个控件的选择题

| 控件 | 数据形态 | 典型场景 |
|---|---|---|
| `TListBox` | 一列字符串 | 简单清单、选项列表 |
| `TComboBox` | 一列字符串（下拉） | 16 章已讲 |
| `TListView` | 多列 + 图标 + 子项 | 资源管理器式列表、结果表格 |
| `TTreeView` | 层级树 | 目录、大纲、设置分类树 |

## 2. TListBox 进阶：多选

```pascal
Lst.MultiSelect := True;          // 允许多选
Lst.ExtendedSelect := True;       // Ctrl 单加/减、Shift 连选
Lst.Selected[3] := True;          // 程序化选中某行
```

**实测坑**：程序化 `Selected[i] := True` **不联动 `ItemIndex`**（保持 -1/原值）——
多选状态与"当前项"是两套状态。要单选语义用 `ItemIndex := i`（会同步）；
多选时自己维护"哪些行被选"的判断（遍历 `Selected[i]`，见示例 SelectedCount）。

其他有用属性：`Items: TStrings`（16 章老朋友）、`Sorted`（自动排序）、
`Style`（lbStandard/lbOwnerDrawFixed——自绘见 27 章）、`ItemHeight`。

## 3. TListView：报表视图（本章主角）

```pascal
View.ViewStyle := vsReport;        // 四种：vsIcon/vsSmallIcon/vsList/vsReport
View.RowSelect := True;

with View.Columns.Add do begin Caption := '姓名'; Width := 90; end;
with View.Columns.Add do begin Caption := '年龄'; Width := 60; end;

li := View.Items.Add;              // 主项 = 第 0 列
li.Caption := '员工1';             // 第 0 列
li.SubItems.Add('25');             // 第 1 列起全是 SubItems
li.SubItems.Add('城市1');          // 第 2 列
li.Data := TPerson.Create(...);    // 任意对象挂 Data（Pointer）
```

要点：

- **第 0 列叫 Caption，其余全叫 SubItems**——列数没有显式属性，由 Columns 与
  SubItems 的实际数量决定。
- `Data: Pointer` 是列表项与业务对象的桥——挂对象、`TPerson(li.Data)` 取回
  （自测实测往返）。**内存责任在挂的人**：Data 不会被自动 Free，窗体析构时要自己清。
- 选中：`li.Selected := True; View.Selected`（nil=没选）。
- 排序：`View.AlphaSort`（按主项字符串）或 `View.CustomSort(@比较函数)`；
  `SortType := stBoth` 让插入即排序。
- 大数据（万行级）：`OwnerData := True` 虚拟模式——下一节展开。

## 4. ListView 虚拟模式：OwnerData（万行不卡）

普通模式 = 你把 N 个 TListItem **真灌进去**（内存、添加时间都 O(N)）——
一万行就要卡一下。虚拟模式把存储还给你：

```pascal
VList.OwnerData := True;          // ① 开虚拟
VList.Items.Count := 10000;       // ② 只声明行数（不建任何项！）
VList.OnData := @VListData;       // ③ 可见时按需来取
```

```pascal
procedure TDemoForm.VListData(Sender: TObject; Item: TListItem);
begin                             // Item.Index = 数据下标，赋完就显示
  Item.Caption := Employees[Item.Index].Name;
  Item.SubItems.Add(IntToStr(Employees[Item.Index].Age));
end;
```

机制：列表框**永远只构造可见那十几行**的 TListItem 壳，滚到哪问到哪
（OnData），数据一直在你自己的数组/文件/数据库里。实测语义：

- `Items.Count` 是**你说了算的计数器**——设 10000 就显示 10000 行，
  内存占用几乎不变；
- `Items[i]` 访问任意行都合法（内部现调 OnData 装壳）——selftest 就这么验证
  第 9999 行的数据正确；
- 普通 API（Items.Add/Delete）在 OwnerData 下**失效**——增删改发生在你的
  数据层，改完 `Count` 再 `Invalidate` 就是"刷新"。

| 模式 | 存储 | 添加 1 万行 | 适合 |
|---|---|---|---|
| 普通 | Items 里 | 真灌（慢、吃内存） | 几百行内、要频繁 Items 操作 |
| OwnerData | 你的数组 | Count := 10000（瞬间） | 万行级、数据本在别处 |

（同一思路在 19 章 TDrawGrid"模型视图分离"里已见过：控件只是视口，
数据主权在你。）

## 5. TTreeView：层级树

```pascal
Tree.Items.AddChild(nil, '公司');                        // nil = 根节点
Tree.Items.AddChild(Tree.Items[0], '研发部');            // 指定父节点
with Tree.Items.AddChild(Tree.Items[1], 'Pascal 组') do  // 返回 TTreeNode
  Data := TPerson.Create('组长', 35);                    // Data 就在返回值上挂
Tree.Items[0].Expanded := True;                          // 展开（默认收起）
```

**本章头号坑（实测）**：`Items[]` 的顺序是**深度优先（DFS）线性化**，不是插入顺序：

```text
建树顺序：公司 → 研发部 → 市场部 → Pascal组(研发部下)
Items[] 实际：[0]公司 [1]研发部 [2]Pascal组 [3]市场部   ← 子节点紧跟父节点！
```

后果一：按"插入序"索引节点会张冠李戴（实测：给 Items[3] 挂 Data 挂到了"市场部"头上，
读回时 AV）。**正确姿势：AddChild 的返回值当场挂数据**，别事后按索引找。
后果二：遍历 `for i := 0 to Items.Count-1` 得到的是 DFS 序（`Level` 属性配合判断深度）。

节点操作速查：`node.HasChildren`、`node.GetFirstChild/GetNextSibling`、
`node.DeleteChildren`、`Tree.Selected`、`Tree.FullExpand`。
拖拽（DragDrop）与编辑（OnChange/OnEdited）真实项目常用，API 同族。

## 6. Items/Data 的内存责任表

| 控件 | Items 存的 | Data 上的对象谁释放 |
|---|---|---|
| TListBox | 字符串（TStrings 管） | 你挂的你清（窗体析构遍历） |
| TListView | TListItem（控件管） | 同上 |
| TTreeView | TTreeNode（控件管） | 同上 |

或者干脆用 14 章的 `TObjectList<T>` 持有对象、Data 只放指针——集中释放最省心
（40 章记事本+ 的做法）。

## 7. 示例与验证

本章示例 `examples/26_lists_trees`：ListBox 多选、ListView 报表（列/子项/Data/
AlphaSort/选中）、TreeView 建树/DFS 遍历/Data。selftest 把上面每条坑都断言了一遍
（含 DFS 序、Selected 不联动 ItemIndex）。

```powershell
pwsh -File build.ps1 -Example 26_lists_trees
```

## 8. 坑位清单（实测）

1. **TreeView Items[] 是 DFS 序**，不是插入顺序——挂数据用 AddChild 返回值，
   别事后按索引回填（挂错节点 + 读取 AV 双重坑）。
2. 程序化 `ListBox.Selected[i] := True` 不联动 ItemIndex——两套状态。
3. ListView 第 0 列是 Caption、其余才是 SubItems——列数对不上时先查这里。
4. Data 上的对象不自动释放——挂的人负责清（或用 TObjectList 统一持有）。
5. ListView 大数据用 OwnerData 虚拟模式（OnData 按需给行），别硬灌 Items。
6. OwnerData 下 Items.Add/Delete 失效——增删改在数据层做，改完 Invalidate。
7. LCL 没有 VCL 的逐行 `UpdateItems`——虚拟列表刷新就是整体 Invalidate。
8. `Items[i]` 在虚拟模式下合法（现调 OnData 装壳），但把它当缓存用会踩坑——
   同一行的两次访问都是现取的。

---
上一章：[25 对话框与文件](25-dialogs.md) ｜ 下一章：[27 绘图与自绘](27-canvas.md) ｜ 返回：[README](../README.md)
