# 33 · 剪贴板与拖放

进程内传值用变量；跨应用、跨控件传值靠两条系统通道：**剪贴板**（复制粘贴）
与**拖放**（拖过去松手）。本章四块：文本剪贴板、控件间拖放、Explorer 文件
拖入、以及这些系统交互的**无头测试法**。

## 1. 剪贴板：Clipboard 全局对象

```pascal
uses Clipbrd;

Clipboard.AsText := '内容';               // 写
S := Clipboard.AsText;                     // 读
if Clipboard.HasFormat(CF_TEXT) then ...   // 问格式（读之前先问）
```

`AsText` 只是便捷通道——剪贴板本质是**格式化数据的多路复用器**
（CF_TEXT/CF_BITMAP/CF_UNICODETEXT/自定义格式），HasFormat 查、按格式取。
"读之前先问"是真规矩：用户可能刚截图（无文本格式），直接读 AsText 得空串
倒不炸，但语义上你该知道自己在读什么。

**测试公德（selftest 的写法）**：剪贴板是**系统共享资源**——写测试值前先
`Saved := AsText` 存底，断言完**还原**。不留垃圾在用户剪贴板里，是 GUI
测试的基本礼貌（32 章托盘同理：测毕即收）。

## 2. 控件间拖放：三个事件一个模式

拖放的完整流程（发起 → 悬停判定 → 松手落地）：

```pascal
SrcList.DragMode := dmAutomatic;          // ① 按住即拖（dmManual=代码 BeginDrag）

procedure TDemoForm.DstDragOver(...; var Accept: Boolean);   // ② 悬停：收不收
begin
  Accept := (Source = SrcList);           // Source=发起拖的控件（身份判定）
end;

procedure TDemoForm.DstDragDrop(Sender, Source: TObject; X, Y: Integer);  // ③ 落地
var I: Integer;
begin
  if Source = SrcList then
    for I := 0 to SrcList.Items.Count - 1 do
      if SrcList.Selected[I] then
        DstList.Items.Add(SrcList.Items[I]);
end;
```

要点：

- **OnDragOver 高频触发**（拖动经过的每个位置）——里面只做廉价的 Accept 判定，
  别干重活；
- **Source 是 TObject**——习惯上 `Source = 某控件` 或 `is` 判型，决定收谁；
- OnDragDrop 里做真正的数据搬运（X/Y 是落点坐标——插入位置定位用）。

**坑（实测）**：多选拖要 `MultiSelect := True`——默认单选语义下
`Selected[2] := True` 会**清掉** `Selected[0]`（设一个清前一个），拖出来
只剩一项还以为代码错了。

## 3. Explorer 文件拖入：OnDropFiles

从资源管理器拖文件到窗体——`TForm.OnDropFiles`（窗体级，`AcceptFiles`
默认开）：

```pascal
OnDropFiles := @FormDropFiles;

procedure TDemoForm.FormDropFiles(Sender: TObject; const FileNames: array of string);
var I: Integer;
begin
  for I := 0 to High(FileNames) do
    Log(Format('[文件] %s', [FileNames[I]));    // 绝对路径数组
end;
```

这是文件打开类应用的入口（拖 .txt 进记事本+ 就是它）。`const FileNames:
array of string` 开放数组参数——**天然可测**（见 §4）。

## 4. 无头测试法：直呼处理器

拖放/文件拖入的真实交互需要鼠标与系统拖拽会话——selftest 测不了"真拖"，
但**逻辑全在处理器里**，直呼即测：

```pascal
St := dsDragEnter;
f.DstDragOver(f.DstList, f.SrcList, 10, 10, St, Accept);   // var Accept 回读
if not Accept then raise ...;

f.SrcList.Selected[0] := True;   // 布置选中态
f.DstDragDrop(f.DstList, f.SrcList, 5, 5);                 // 松手语义
if f.DstList.Items.Count <> 2 then raise ...;

f.FormDropFiles(f, ['G:\a.txt', 'G:\b\c.pas']);            // 开放数组直呼
```

与 31 章键盘链同款策略：**机制层（消息泵）留给人工，逻辑层（处理器）全部
无头覆盖**。var 参数照 31 章的语言坑：先赋变量再传。

## 5. 数据该搬家还是复制？

拖放语义自选：搬运（源删目标加）还是复制（只加不删）——OnDragDrop 里自己
决定，控件不预设。跨窗体/跨应用拖放同一套事件（Source 判身份即可）；
拖到**外部程序**（拖文本到 Word）是另一套（OLE 拖出），LCL 下超出本教程
边界，知道有这条边界即可。

## 6. 示例与验证

```powershell
pwsh -File build.ps1 -Example 33_clipboard_dnd
```

selftest 覆盖：剪贴板写入/读回/HasFormat/还原、OnDragOver 身份判定
（收 SrcList 拒 Memo）、OnDragDrop 多项搬运、OnDropFiles 开放数组、
DragMode 回环。

## 7. 坑位清单（实测）

1. **剪贴板测试必须保存/还原**——系统共享资源，别拿用户的剪贴板当便签。
2. MultiSelect 默认 False：`Selected[i] := True` 会清前一个（单选语义）。
3. OnDragOver 里别干重活（高频触发）；判定越便宜越好。
4. Source 是 TObject——`=` 比控件引用、`is` 比类型，先想清楚收谁。
5. OnDropFiles 挂在**窗体**上（不是某个控件）；文件落在控件上要自己用
   坐标分诊。
6. 直呼带 var 参数的处理器：常量（含 'x'、[]）编译不过——变量先行
   （31 章语言坑）。

---
上一章：[32 工具栏、图像列表与系统托盘](32-toolbar-tray.md) ｜ 下一章：[34 自定义控件与组件开发](34-custom-controls.md) ｜ 返回：[README](../README.md)
