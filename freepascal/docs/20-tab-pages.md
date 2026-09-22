# 20 · 多页容器：TTabControl 与 TPageControl

"多个页面切着看"有两个长得像的控件，选错就是白写一倍代码：

- **TTabControl**：只有**一排标签头 + 一块共享内容区**。切标签只是换序号，
  内容换不换、怎么换全是你。适合"同一份数据换视图"。
- **TPageControl**：每个标签页是一个 **TTabSheet 容器**，各装各的控件。
  适合"内容分区"（设置对话框、多标签编辑器）。

40 章记事本+ 的多标签文本区 = PageControl + 动态 TTabSheet（每页一个 TMemo）。

## 1. TTabControl：同一数据换视图

```pascal
Tabs := TTabControl.Create(Self);
Tabs.Tabs.Add('文本');                    // Tabs 是 TStrings——全家族方法可用
Tabs.Tabs.Add('十六进制');
Tabs.Tabs.Add('统计');
Tabs.TabIndex := 0;
Tabs.OnChange := @TabsChange;            // 切标签（用户点击）时换渲染
```

OnChange 是唯一要写的东西——switch 到 TabIndex 重画共享区（20a 是一段文本的
文本/十六进制/统计三视图）。Tabs 容器全套可用：

```pascal
Tabs.Tabs.IndexOf('统计');   // → 2
Tabs.Tabs.Delete(2);
Tabs.Tabs[2];                // 回读
```

**实测（重要）**：程序赋值 `TabIndex` **不触发 OnChange**（与 Calendar 同类；
17 章横评表）。两个后果：

1. 程序切页后视图不会自己换——手动调渲染函数；
2. LCL 给了专门开关：`Options + [nboDoChangeOnSetIndex]`，开了它程序赋值
   也走 OnChange。两个行为 20a 的 selftest 都断言过。

## 2. TPageControl：每页一个容器

```pascal
Pages := TPageControl.Create(Self);
Sheet := Pages.AddTabSheet;              // 建页（自动挂进 Pages、追加末尾）
Sheet.Caption := '页 1';
Memo := TMemo.Create(Sheet);             // 内容挂"页"不是挂 PageControl
Memo.Parent := Sheet;

Pages.ActivePage: TTabSheet;             // 当前页（对象）
Pages.ActivePageIndex: Integer;          // 当前页（序号）
Pages.PageCount / Pages.Pages[i]         // 数量 / 按序取页
```

翻页 API 一对：

```pascal
Pages.SelectNextPage(True, True);        // 前/后翻；第二参=True 跳过 TabVisible=False 的页
Pages.FindNextPage(CurPage, GoForward, CheckTabVisible)   // 只找不切
```

## 3. 动态页的生命周期

浏览器式"动态开页/关页"是 PageControl 的招牌戏（20b）：

```pascal
// 开页（新页激活）
Pages.ActivePage := NewPage('页 N');

// 关页：TTabSheet.Free 一步到位——页从 PageControl 摘除、页上子控件全部释放
Pages.ActivePage.Free;
Pages.SelectNextPage(True);              // 关完补一个落点
```

页的容器身份带来两件事：`Sheet.PageControl` 指回宿主（selftest 断言）；
页上的控件 Owner/Parent 关系成立，Free 时连坐释放——不存在悬空。

标签自带关闭按钮是现成选项：

```pascal
Pages.Options := Pages.Options + [nboShowCloseButtons];   // 每页标签带 ×
Pages.OnCloseTabClicked := ...;        // 点 × 的回调（自己决定删不删页）
```

## 4. TabVisible：藏页不是删页

```pascal
Pages.Pages[1].TabVisible := False;     // 标签消失、Pages[] 里还在
```

实测语义：藏页**不减 PageCount**（快照式的 `Pages[i]` 照常可访问——往它上面
读写控件都没问题）；`SelectNextPage(True, True)` 会跳过它；`ActivePageIndex`
语义是"可见序"。设置对话框"高级页"的显隐就靠这个，比建删页便宜且稳。

## 5. Options 全表（TCTabControlOptions，两控件通用）

| 项 | 语义 |
|---|---|
| `nboShowCloseButtons` | 标签带 ×（配 OnCloseTabClicked） |
| `nboDoChangeOnSetIndex` | **程序赋值页序也触发 OnChange**（默认不发） |
| `nboMultiLine` | 标签多行排 |
| `nboKeyboardTabSwitch` | Ctrl+Tab 键盘切页 |
| `nboShowAddTabButton` | 末尾"+"按钮（配 OnShowAddButton? 自绘场景） |
| `nboHidePagePageListPopup`? | 注意：实为 `nboHidePageListPopup`——藏右键页清单 |

另有独立属性：`TabPosition`（tpTop/tpBottom/tpLeft/tpRight，标签放哪边）、
`ShowTabs`（全藏——纯向导式翻页）、`HotTrack`（悬停高亮）、`Images`+页
`ImageIndex`（带图标标签，配 32 章图像列表）。

## 6. 选型决断

| 问题 | 答案 |
|---|---|
| 每页内容结构不同？ | PageControl |
| 同一数据不同呈现？ | TabControl |
| 页数运行时增减？ | PageControl + AddTabSheet/Free |
| 要"下一步"向导？ | PageControl + ShowTabs=False + SelectNextPage |

## 7. 示例与验证

```powershell
pwsh -File build.ps1 -Example 20a_tabcontrol   # 文本三视图（含 hex/统计渲染）
pwsh -File build.ps1 -Example 20b_pagecontrol  # 动态多页：加/关/藏/翻
```

selftest 覆盖：Tabs 容器全家、TabIndex 程序赋值不触发（及开关后触发）、
视图内容与标签一致、AddTabSheet/ActivePage/ActivePageIndex 同步、
TabVisible 藏页不减 PageCount 且 SelectNextPage 跳过、ActivePage.Free 释放、
nboShowCloseButtons 在位。

## 8. 坑位清单（实测）

1. **程序改 TabIndex 默认不发 OnChange**——要发就加 `nboDoChangeOnSetIndex`。
2. 关页用 `Sheet.Free`，没有 `Pages.DeletePage`——Free 连子控件一起释放。
3. 藏页（TabVisible=False）后 `Pages[i]` 序号不变、PageCount 不减。
4. 子控件 Parent 是 **TTabSheet** 不是 TPageControl——挂错直接不显示。
5. `SelectNextPage` 单参重载不跳隐藏页，要跳过得传 `(True, True)`。
6. TTabControl 换标签**不会**自动换内容（它只有标签头）——内容隔离请用
   PageControl。

---
上一章：[19 表格控件](19-grids.md) ｜ 下一章：[21 图像显示](21-image.md) ｜ 返回：[README](../README.md)
