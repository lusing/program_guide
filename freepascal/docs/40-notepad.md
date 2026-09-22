# 40 · 实战：记事本+（⭐）

前 28 章的知识点在这里全部上战场：**多标签文本编辑器**——动态标签页、文件打开/保存
（编码选择）、查找/替换、修改跟踪、状态栏统计、选项持久化。工程结构：

```text
examples/40_notepad_plus/
├── 40_notepad_plus.lpi    工程文件（3 个单元）
├── 40_notepad_plus.lpr    主程序：selftest 分支 + 主窗体启动
├── unotepad.pas           TMainForm + TTabDoc（全部功能，纯代码建窗体）
└── uchecks.pas            迷你断言单元（Check/CheckEqInt/CheckEqStr）
```

## 1. 架构：一个标签页 = 一个文档对象

```pascal
TTabDoc = class
  Sheet: TTabSheet;          // UI 的一半：标签页
  Memo: TMemo;               // UI 的另一半：编辑器（Align=alClient）
  FileName: string;          // 元数据：路径（'' = 未命名）
  Encoding: TDocEncoding;    // 编码（UTF-8 / ANSI）
  Dirty: Boolean;            // 脏标记
  function DisplayName: string;   // '*文件名' —— 标签标题的唯一事实来源
end;
```

**UI 控件与文档元数据绑在一个对象里**——标签标题、关闭确认、保存逻辑全都围绕它。
`DisplayName` 是"标题 = 数据的函数"的落地：改 Dirty/FileName 后重取一次标题，
永远不怕显示与状态脱节。

映射方向（Sheet → Doc）：**TTabSheet 没有 Data 属性**（那是 TTreeNode/TListItem 的），
工程里用 `FDocs: TList` 自管映射，`DocOfSheet` 遍历比对（页数个位数，遍历足够）。

## 2. 多标签：动态建页的生命周期

```pascal
function TMainForm.NewDoc: TTabDoc;
begin
  Result := TTabDoc.Create;
  Result.Sheet := Pages.AddTabSheet;      // 页由 PageControl 管（Owner 链）
  FDocs.Add(Result);                      // Doc 由 FDocs 管
  Result.Memo := TMemo.Create(Result.Sheet);
  Result.Memo.Parent := Result.Sheet;
  Result.Memo.Align := alClient;          // 编辑器吃满整页（23 章）
  ...
end;

function TMainForm.CloseDoc(Doc: TTabDoc): Boolean;
begin
  if not ConfirmCloseDoc(Doc) then Exit;
  FDocs.Remove(Doc);                      // 两边各归各位
  Doc.Sheet.Free;                         // 页没了，Memo 连坐（Owner 链）
  Doc.Free;                               // 元数据对象自己放
end;
```

双重所有权：**Sheet 归 PageControl、TTabDoc 归 FDocs**——释放顺序先 Remove 再 Free，
与 12 章"所有权心智模型"完全对齐。

## 3. 打开与保存：编码是一等公民

```pascal
// 打开：显式 UTF-8（25 章坑：默认按系统 ANSI 读，中文必乱）
Result.Memo.Lines.LoadFromFile(AFileName, TEncoding.UTF8);

// 保存：按文档的编码选择写
if Doc.Encoding = encUtf8 then
  Doc.Memo.Lines.SaveToFile(Doc.FileName, TEncoding.UTF8)
else
  Doc.Memo.Lines.SaveToFile(Doc.FileName, TEncoding.Default);
```

状态栏第三格显示当前编码——**让用户看见编码**是文本编辑器的基本礼貌。
selftest 第 4 节做了完整往返：写临时文件（UTF-8）→ 打开 → 编辑 → 保存 → 重读比对。

## 4. 修改跟踪：脏标记与关闭确认

```pascal
procedure TTabDoc.MarkDirty;         // 程序化修改后显调用（见 §7 坑）
begin
  if not Dirty then begin
    Dirty := True;
    Sheet.Caption := DisplayName;    // '*文件名'
  end;
end;

function TMainForm.ConfirmCloseDoc(Doc: TTabDoc): Boolean;
begin
  if (Doc = nil) or (not Doc.Dirty) then Exit(True);   // 干净直接关
  case AskUser of                                        // mrYes/mrNo/mrCancel
    mrYes: Exit(SaveDoc(Doc, False));
    mrNo:  Exit(True);
  else    Exit(False);                                   // 取消：不关
  end;
end;
```

`ConfirmCloseDoc` 是**纯逻辑核 + 一个提问**——提问用 MessageDlg（真实路径）或
`ConfirmAnswer` 测试钩子（selftest 代答 mrCancel/mrYes）。**把 UI 提问从决策逻辑里
剥出来**，是这段代码可无头测试的全部原因（25 章 ModalResult 的实战收尾）。

## 5. 查找与替换：算法独立成函数

```pascal
function TMainForm.FindNext(Doc: TTabDoc; const AText: string; FromPos: Integer): Integer;
// 找到返回 0 基位置并选中（SelStart/SelLength），找不到 -1——不碰任何对话框

procedure TMainForm.ReplaceAll(Doc: TTabDoc; const AFind, ARepl: string; out Count: Integer);
// 字符串级替换 + Count 出参——同样不碰 UI
```

对话框（TFindDialog/TReplaceDialog 的 OnFind/OnReplace）只做"取输入 → 调函数 →
报结果"。**算法可测、UI 薄壳**——selftest 第 5 节直接调 FindNext/ReplaceAll 断言
命中/未中/替换计数。

## 6. 状态栏：行列换算自己算

```pascal
// SelStart → 行列：从左往右数 #10（必须从左往右！见 §8 坑）
for cnt := 1 to Doc.Memo.SelStart do
  if Doc.Memo.Text[cnt] = #10 then begin Inc(line); col := 1; end
  else Inc(col);
```

不依赖 `CaretPos`（控件集间行为不一）——SelStart 是最稳的锚。字符数按
`Length(Text)`（字节数，中文 3 字节/字——07 章语义，状态栏如实显示）。

## 7. 本工程实测坑合集（每条都让 selftest 红过一次）

1. **`Length('中文字面量')` 按字符（9），文件读回按字节（27）**——期望值先赋给
   `string` 变量再取 Length（07 章重定型坑在收官工程的最后一次回响）。
2. **`Memo.Lines.Add` 与 `Memo.Text :=` 都不触发 OnChange**（TEdit 才触发）——
   程序化修改一律显式 `MarkDirty`；OnChange 只信任键入路径。
3. **行列换算必须从左往右扫**——从右往左会把已换行的前缀又加进列号（行 2 列 4 之坑）。
4. TTabSheet 无 Data 属性——Sheet→Doc 映射自管。
5. property 读的字段必须在属性声明**之前**可见（objfpc 类内无前向引用）。
6. 关闭标签后 PageIndex 越界：`PageIndex := Min(idx, PageCount-1)`。

## 8. uchecks：30 行的测试框架

```pascal
procedure Check(Cond: Boolean; const Msg: string);        // 不满足 → 抛异常
procedure CheckEqInt(Got, Want: Int64; const Msg: string);
procedure CheckEqStr(const Got, Want: string; const Msg: string);
function CheckSummary: string;                            // "断言 N 通过 / M 失败"
```

为什么不用 Assert？三个理由：selftest 构建（lazbuild）没开 `-Sa`，Assert 不可靠；
GUI 程序 Assert 失败弹 LCL 框（无头挂死，15 章之坑）；Check 失败抛的异常被 .lpr
外层捕获写日志——**错误信息落进 selftest.log 而不是弹窗**。这就是"自制测试框架"
的全部：计数器 + 比较函数 + 失败通道。fpcunit（FPC 自带的 xUnit）是它的工业版，
思路完全相同。

跑法与判定：

```powershell
pwsh -File build.ps1 -Example 40_notepad_plus
# lazbuild → exe --selftest → selftest.log 四条判定（含 ==== 40 selftest OK ====）
```

日志尾巴：`断言 29 通过 / 0 失败`。

## 9. 从 selftest 到 CI：lazbuild 一行流

```powershell
# 全部 23 个示例（13 CLI 双通道 + 10 GUI selftest）一条命令回归：
pwsh -File build.ps1 -All
# 任何脚本失败 → 退出码 1 —— CI（GitHub Actions/GitLab CI）里就是一行 pwsh 调用
```

把本章套路（功能抽成可测函数 + --selftest 分支 + 日志判定）搬到你自己的项目，
就得到了**持续可验证的 GUI 开发流程**——这正是本教程"每章示例全部机器验证"的
方法论收编。

## 10. 可以继续做的事

1. 撤销/重做（TMemo 自带一级 Undo；完整版用自管理命令栈）
2. 多编码自动探测（BOM/启发式）与状态栏点击切换编码
3. 行号栏（自绘，27 章 OnPaint + 滚动同步）
4. 打开最近文件（INI 的 history 节）
5. 拖放打开文件（DragAcceptFiles，Windows API 侧）
6. SQLdb/SQLite 通讯录——数据库桌面应用的入门下一站（本教程非目标，正好接）

---
上一章：[23 多线程与后台任务](23-threads.md) ｜ 返回：[README](../README.md)
