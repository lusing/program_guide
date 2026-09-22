# 24 · 菜单与 Action

## 1. 问题：一个"新建"命令要出现在三个地方

菜单里一项、工具栏一个按钮、快捷键 Ctrl+N——**三处必须是同一个命令**（同一图标、
同一可用状态、同一处理器）。没有统一机制时这叫三处复制粘贴；LCL 的答案是
**TActionList/TAction**：命令做成 Action（单一事实来源），三个 UI 挂点都绑它。

```text
            ┌─→ 主菜单项（自动获得 Caption/快捷键）
TAction ────┼─→ 工具栏按钮（自动获得 Caption/Hint/图标/Enabled）
 "新建"     └─→ Ctrl+N（ActionList 收到快捷键直接执行）
```

## 2. 先造 Action

```pascal
Actions := TActionList.Create(Self);

ActNew := TAction.Create(Self);
ActNew.ActionList := Actions;
ActNew.Caption := '新建(&N)';                            // &N = Alt 加速键
ActNew.Hint := '新建文档';                               // 状态栏提示/悬浮提示
ActNew.ShortCut := ShortCut(Ord('N'), [ssCtrl]);         // Ctrl=N；别写魔数
ActNew.OnExecute := @ActNewExecute;                      // 命令本体
```

- `Caption` 里的 `&N`：紧跟的字母成为菜单的 Alt 加速键（显示为下划线）。
- `ShortCut()` 函数组合键值（`ssCtrl/ssShift/ssAlt`），别硬编码数字——
  `ShortCutToText` 反向转文本。
- 其他常用属性：`Enabled`（灰掉）、`Checked`（打勾）、`ImageIndex`（图标）、
  `Category`（分组）。

## 3. 三个挂点

**菜单**（TMainMenu → TMenuItem 树，挂法是"包一层"）：

```pascal
MenuBar := TMainMenu.Create(Self);
mFile := MakeMenu('文件(&F)', [ActNew, ActOpen]);
MenuBar.Items.Add(mFile);
```

**坑（实测）**：`MenuItem.Add` 只收 TMenuItem——不能直接塞 Action，要
`item := TMenuItem.Create(...); item.Action := ActNew; parent.Add(item);`
（示例里的 AddActionItem/MakeMenu 辅助函数就是干这个的）。
分隔线是 `Caption := '-'` 的菜单项。

**工具栏**（TToolBar 本身 32 章细讲——本节只关心 Action 怎么挂）：

```pascal
Toolbar := TToolBar.Create(Self);
ToolNew := TToolButton.Create(Self);
ToolNew.Parent := Toolbar;
ToolNew.Action := ActNew;      // Caption/Hint/OnClick 全由 Action 供给——改一处全生效
```

**快捷键**：Action 挂在 ActionList 上、菜单可见时，ShortCut 自动生效。

**弹出菜单**（右键）：`TPopupMenu` 同样包 MenuItem 挂 Action；
`SomeControl.PopupMenu := Popup` 绑到控件上。

## 4. OnUpdate：状态同步的集中地

```pascal
Actions.OnUpdate := @ActionsUpdate;

procedure TDemoForm.ActionsUpdate(AAction: TBasicAction; var Handled: Boolean);
begin
  if AAction = ActOpen then
    ActOpen.Enabled := NewCount > 0;    // "打开"只有新建过才可用
  Handled := False;
end;
```

应用空闲时 ActionList 轮询 OnUpdate——**所有"能不能用/勾不勾"的逻辑集中一处**，
绑定的菜单项/按钮自动跟着变灰/点亮（selftest 实测：改 Enabled 后按钮 Caption/状态
统一由 Action 供给）。比起在每个菜单点开事件里手刷状态，这是数量级的解耦。

## 5. TStatusBar：状态栏与窗格

```pascal
Status := TStatusBar.Create(Self);
Status.Align := alBottom;
Status.SimplePanel := False;            // 多窗格模式（True=单条文本）
Status.Panels.Add.Width := 200;         // 窗格 0 宽 200
Status.Panels.Add;                      // 窗格 1 吃剩余
Status.Panels[0].Text := '就绪';
```

窗格（TPanel... 不对，是 `TStatusPanel`）可设 Width/Text/Alignment；
`SimpleText` 属性在 SimplePanel=True 时用。40 章记事本+ 的行列号/字数统计就住这里。

## 6. 标准对话框的菜单命令化

真实程序里 ActOpen 的 OnExecute 大概长这样（25 章的预告）：

```pascal
procedure TMainForm.ActOpenExecute(Sender: TObject);
begin
  if OpenDlg.Execute then               // 模态弹出；OK 返回 True
    LoadFile(OpenDlg.FileName);
end;
```

`Execute` 返回 Boolean（用户确定/取消）——对话框与 Action 的标准接口。

## 7. 示例与验证

本章示例 `examples/24_menus_actions`：三 Action + 主菜单 + 弹出菜单 + 工具栏三绑定 +
状态栏三窗格 + OnUpdate 状态同步。selftest 验证：菜单结构、Action 共享
（Popup[0].Action = ActNew）、`ActNew.Execute` 等效点击、OnUpdate 开关 Enabled、
按钮 Caption 随 Action。

```powershell
pwsh -File build.ps1 -Example 24_menus_actions
```

正常路径：Ctrl+N 两次 → 状态栏变"新建了 2 个" → "打开"从灰变亮（OnUpdate）。

## 8. 坑位清单（实测）

1. 窗体字段**别叫 `Menu`**——TForm.Menu 是现成属性，撞名报 Duplicate identifier。
2. `MenuItem.Add` 只收 TMenuItem；挂 Action 必须包一层菜单项（AddActionItem 辅助函数）。
3. `with X do ... Add(Self)` 里的 Self 还是**窗体**不是 with 变量——别玩花活，老实用临时变量。
4. 快捷键用 `ShortCut(Ord('N'), [ssCtrl])` 组合；魔数 16462 无人能读。
5. 自己的辅助函数别叫 `NewItem`——Menus 单元已有同名函数（撞名报错）。
6. OnUpdate 是空闲轮询（每秒可能几十次）——别放重活；重计算用脏标志。

---
上一章：[23 布局与锚定](23-layout.md) ｜ 下一章：[25 对话框与文件](25-dialogs.md) ｜ 返回：[README](../README.md)
