# 20 · 对话框与文件

## 1. 两类对话框：模态组件与非模态对话框

LCL 的"对话框"分两类，心智模型完全不同：

| 类 | 代表 | 用法 |
|---|---|---|
| **组件型（模态）** | TOpenDialog/TSaveDialog/TFontDialog/TColorDialog | 拖到窗体 → `if Dlg.Execute then 用 Dlg.结果` |
| **消息型（函数直调）** | MessageDlg/ShowMessage/InputBox | 一行调用，返回用户选择 |
| **非模态对话框** | TFindDialog/TReplaceDialog | `Dlg.Execute` 只显示不阻塞，回调驱动 |

## 2. TOpenDialog / TSaveDialog：文件选择

```pascal
OpenDlg := TOpenDialog.Create(Self);
OpenDlg.Title := '选择要打开的文本文件';
OpenDlg.Filter := '文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*';   // 名称|模式 逐组竖线分隔
OpenDlg.FilterIndex := 1;                  // 默认第几组
OpenDlg.Options := OpenDlg.Options + [ofFileMustExist, ofAllowMultiSelect];

if OpenDlg.Execute then                   // 模态：阻塞到用户关掉，True=选了文件
begin
  ShowMessage(OpenDlg.FileName);          // 单选：完整路径
  // 多选时：OpenDlg.Files[i]（TStrings）
end;
```

常用 Options：`ofFileMustExist`（打开侧：文件必须存在）、`ofOverwritePrompt`
（保存侧：覆盖确认）、`ofAllowMultiSelect`（多选）、`ofHideReadOnly`、
`ofPathMustExist`。保存对话框另有 `DefaultExt := 'txt'`（用户没打扩展名时自动补）。

**过滤器语法**是新手第一坑：`'名称|*.扩展名'` 一组，多组继续用 `|` 连；
`*.txt;*.log` 分号并列多个模式。写错不会报错——下拉框里直接显示乱串。

## 3. ShowModal 与 ModalResult：模态的底层

`Execute` 的本质是窗体的 **ShowModal + ModalResult** 协议（自己写对话框时直接用这层）：

```pascal
// 主调方
Dlg := TInputForm.Create(nil);
try
  if Dlg.ShowModal = mrOk then          // 阻塞；用户关窗时读它设的 ModalResult
    用(Dlg.某字段);
finally
  Dlg.Free;
end;

// 对话框窗体里的按钮
btnOk.ModalResult := mrOk;              // 点击自动关窗并"返回" mrOk——不用写一行代码
btnCancel.ModalResult := mrCancel;
```

ModalResult 常量（实测值）：`mrNone=0 mrOk=1 mrCancel=2 mrAbort=3 mrRetry=4
mrIgnore=5 mrYes=6 mrNo=7 mrClose=8`。**按钮的 ModalResult 属性是免费午餐**：
设了它，点击即关窗返回，OnClick 都不用写。ESC 键自动回 mrCancel（窗体 CancelButton）。

## 4. MessageDlg 家族：问一句

```pascal
ShowMessage('就这么多');                                     // 只有一个 OK
MessageDlg('未保存，保存吗？', mtConfirmation, [mbYes, mbNo, mbCancel], 0);
//   返回 TModalResult（mrYes/mrNo/mrCancel...）
MessageDlg('出错了：' + E.Message, mtError, [mbOk], 0);
if MessageDlg('确认删除？', mtWarning, mbYesNo, 0) = mrYes then 删除;
```

类型 `mtWarning/mtError/mtInformation/mtConfirmation` 决定图标；
按钮集合 `[mbYes, mbNo]` 决定按钮。`InputBox('标题', '提示', 默认值)` 带输入框
返回字符串；`InputQuery` 返回 Boolean + out 参数（改不改由你）。

## 5. TFontDialog / TColorDialog

```pascal
FontDlg.Font.Name := '微软雅黑';        // 预设当前值
FontDlg.Font.Size := 12;
if FontDlg.Execute then
  Memo.Font.Assign(FontDlg.Font);      // TFont 整体赋值
```

对话框的 Font/Color 属性是"进出两用"的：进去前设初值，回来后读用户选择。
`Assign` 整体拷贝（逐属性抄容易漏 Style）。

## 6. TFindDialog / TReplaceDialog：非模态回调驱动

```pascal
FindDlg := TFindDialog.Create(Self);
FindDlg.OnFind := @FindDlgFind;                     // 用户点"查找下一个"时回调
FindDlg.Options := FindDlg.Options + [frDown, frMatchCase];
FindDlg.Execute;                                    // 显示后立即返回（不阻塞）

procedure TDemoForm.FindDlgFind(Sender: TObject);
begin
  // FindDlg.FindText 是要找的词；Options 里读方向/大小写勾选
  // 真实现：在 Memo 里定位下一个；演示只记日志
end;
```

** Execute 只负责显示**，之后全靠回调（OnFind/OnReplace）驱动——与模态的
"阻塞拿结果"完全两套写法。TReplaceDialog 多一个 OnReplace 和 ReplaceText 属性。
40 章记事本+ 的查找替换就用这一对。

## 7. 文件读写整合：LoadFromFile / SaveToStringFile

选到文件名之后，常用的读写姿势（11 章文件 IO 的 GUI 速查版）：

```pascal
Memo.Lines.LoadFromFile(OpenDlg.FileName);          // TStrings 一行读文本
Memo.Lines.SaveToFile(SaveDlg.FileName);            // 一行写
```

编码注意：`TStrings.LoadFromFile` 有 `FileEncoding` 参数/属性（默认系统 ANSI！）
——UTF-8 文件要显式 `LoadFromFile(name, TEncoding.UTF8)`，否则中文乱码
（11 章 INI/TextFile 同族坑的 GUI 版）。40 章的编码选择功能就是围绕它做的。

## 8. 示例与验证

本章示例 `examples/25_dialogs`：两个文件对话框（过滤器/选项全配置）、
FindDialog 回调、FontDialog 属性、ConfirmClose 纯逻辑函数、ModalResult 常量表。
selftest 全部走**无 UI 依赖路径**（属性 + 回调 + 纯函数）——弹窗类的 Execute
留给正常路径人工体验。

```powershell
pwsh -File build.ps1 -Example 25_dialogs
```

## 9. 坑位清单（实测）

1. **模态与非模态 Execute 语义相反**：文件/字体对话框 Execute=阻塞拿结果；
   Find/Replace 的 Execute=显示立即返回。
2. 过滤器写错不报错（显示乱串）——`'名称|*.ext'` 逐组竖线，多组分号并列。
3. `TStrings.LoadFromFile` 默认按系统 ANSI 读——UTF-8 文件中文必乱，
   显式传 `TEncoding.UTF8`。
4. 按钮设 `ModalResult` 即免费获得"点击关窗返回"——很多教程绕远路写 OnClose。
5. MessageDlg 的按钮集合返回值要逐个核对常量（mrYes=6/mrNo=7 不是 1/2）。
6. 对话框组件放窗体上（Owner=窗体）比临时 Create 划算——过滤器等配置只设一次。

---
上一章：[24 菜单与 Action](24-menus.md) ｜ 下一章：[26 列表与树视图](26-lists.md) ｜ 返回：[README](../README.md)
