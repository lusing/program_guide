# 24 · 迷你文本编辑器：TEditWindow 与 gap buffer（全书终章）

> 对应示例：[examples/24_tv_editor.cpp](../examples/24_tv_editor.cpp)

## 24.1 TEditWindow：构造即装盘

```cpp
// ═══ 24.1 一行开一个编辑器窗：fileName 空=新档，非空=装盘 ═══
TEditWindow* TEditorApp::openEditor(const char* fileName)
{
    TRect r = deskTop->getExtent();              // 桌面全幅
    TView* p = validView(new TEditWindow(r, fileName ? fileName : "", wnNoNumber));
    deskTop->insert(p);
    return (TEditWindow*)p;
}

// 构造函数里开一个无名新档并灌入欢迎文本（selftest 也从这里起步）
TEditWindow* w = openEditor(nullptr);
if (w && w->editor)
    w->editor->insertText(kWelcome, (uint)std::strlen(kWelcome), False);
```

TEditWindow(bounds, fileName, number) 是开箱即用的编辑器窗：自带 TFileEditor（编辑器本体）、横竖两条滚动条和行列指示器（TIndicator，边框右上角）。fileName 的分岔全在构造里：空串 = 无名新档；非空则 `fexpand`（补全为绝对路径）+ `loadFile` 直接把盘上内容装进缓冲——不存在"先构造再手动打开"的第二步。`validView` 先给视图做体检（失败会被框架处理掉），再 insert 上桌面。

## 24.2 gap buffer：curPtr 缝隙与 bufChar 跨缝取字

TEditor 的缓冲是 **gap buffer**：一段连续内存，中间留一条"缝隙"（gap）跟着光标走——`curPtr` 就是缝隙位置。插入时字符写进缝的左侧、缝右移；删除时缝左边界回收。好处是光标处编辑 O(1)，代价是**物理下标 ≠ 逻辑下标**：缝隙会把文本劈成两段，直接 `buffer[i]` 摸到的是物理布局。取字必须走 `bufChar(i)`——它帮你跨缝换算成逻辑第 i 字符；`countLines`/`lineStart`/`nextLine` 同理，行分隔 `\r`、`\n`、`\r\n` 通吃。

```cpp
// ═══ 24.2 setCurPtr 同步维护 curPos ═══
e1->setCurPtr(0, 0);                          // 光标回文件头
Log("光标@0 → curPos=(%d,%d)\n", e1->curPos.x, e1->curPos.y);
uint p2 = e1->lineStart(e1->nextLine(0));     // 第二行行首
e1->setCurPtr(p2, 0);
Log("光标@第二行行首(%u) → curPos=(%d,%d)\n", p2, e1->curPos.x, e1->curPos.y);
char head[9];
for (int i = 0; i < 8; ++i) head[i] = e1->bufChar((uint)i);   // 跨 gap 取字符
head[8] = '\0';
```

`setCurPtr(p, 0)` 挪光标的同时同步维护 `curPos`（TPoint：列 x、行 y）——它内部走 setSelect 逐段数行算列，保证逻辑位置与字节偏移永远一致。`insertText(文, 长, allowUndo)` 则在光标处灌文本、推进 curPtr、更新 curPos、置脏标志 modified——四个状态一体维护，不允许"插了字不挪缝"。

## 24.3 存盘：fileName、modified 与脏标志

```cpp
// ═══ 24.3 程序化保存：先填 fileName 再 save ═══
std::strcpy(e1->fileName, "selftest-24-edit.txt");
Boolean saved = e1->save();
Log("save()=%d 存盘后 modified=%d（存盘清脏标志）\n",
    saved ? 1 : 0, e1->modified ? 1 : 0);
```

`save()` 落盘并**清 modified**（标题栏的脏记号随之消失）；`canClear` 关窗时靠 modified 决定要不要问"存不存"。程序化保存有个铁律：**fileName 为空时 save 会转 saveAs 弹出文件对话框**（模态、等输入）——无人值守直接挂死，所以必须先 strcpy 填名再 save（坑位清单第 1 条）。

## 24.4 命令三层接线与 TFileDialog

```cpp
// ═══ 24.4 应用层只接 cmNew/cmOpen，编辑命令留给编辑器 ═══
switch (event.message.command)
{
case cmNew:  openEditor(nullptr); break;
case cmOpen: fileOpen();          break;
default:     return;              // cmSave/cmSaveAs/cmCut... 编辑器自己接
}
clearEvent(event);

// tvedit2.cpp 同款：对话框标准执行包装（含数据双向搬运）
static ushort execDialog(TDialog* d, void* data)
{
    TView* p = TProgram::application->validView(d);
    if (p == 0) return cmCancel;
    if (data != 0) p->setData(data);
    ushort result = TProgram::deskTop->execView(p);
    if (result != cmCancel && data != 0) p->getData(data);
    TObject::destroy(p);
    return result;
}
```

编辑器命令分三层接线：`cmSave`/`cmSaveAs` 由 TFileEditor::handleEvent **自接**；`cmCut`/`cmCopy`/`cmPaste`/`cmUndo` 由 TEditor 自接，且随选区/撤销栈**自动启停**；`cmNew`/`cmOpen` 是"开哪个文件"的应用级决策，落到应用层。菜单只是入口，应用层别越位重复处理。构造期还有一步兜底：

```cpp
// ═══ 24.4（续）先全禁编辑类命令，解禁权交回编辑器 ═══
TCommandSet ts;
ts.enableCmd(cmSave);
ts.enableCmd(cmSaveAs);
ts.enableCmd(cmCut);
ts.enableCmd(cmCopy);
ts.enableCmd(cmPaste);
ts.enableCmd(cmUndo);
disableCommands(ts);
```

构造期把六个编辑命令**全部禁掉**，之后 TEditor 的 updateCommands 会在选区/撤销栈变化时逐个解禁——命令启停的**权威在编辑器**，应用层只负责一开始按下总闸（tvedit1.cpp 原样套路）。打开文件一侧用 TFileDialog 配 execDialog 包装：

```cpp
// ═══ 24.4（续）TFileDialog 五参与打开流程 ═══
void TEditorApp::fileOpen()
{
    char fileName[MAXPATH];
    std::strcpy(fileName, "*.txt;*.md;*.cpp");    // 预放通配符当输入起点
    if (execDialog(new TFileDialog("*.txt;*.md;*.cpp", "Open file",
                                   "~N~ame", fdOpenButton, 100),
                   fileName) != cmCancel)
        openEditor(fileName);
}
```

TFileDialog 五参：通配符、标题、输入框标签、`fdOpenButton`（Open 语义的按钮组）、历史 id（100——同一 id 共享一份输入历史）。fileName 缓冲先放通配符是有用意的：execDialog 的 setData 会把它灌进对话框输入框当起点，回车即按它过滤；取消则原样返回 cmCancel，不开窗。菜单则把命令亮出来但一行处理器都不写：

```cpp
// ═══ 24.4（续）菜单只是入口：F2/F3 直指命令，处理器在别处 ═══
TSubMenu& fileMenu =
    *new TSubMenu("~F~ile", kbAltF) +
      *new TMenuItem("~N~ew", cmNew, kbNoKey) +
      *new TMenuItem("~O~pen...", cmOpen, kbF3, hcNoContext, "F3") +
       newLine() +
      *new TMenuItem("~S~ave", cmSave, kbF2, hcNoContext, "F2") +
      *new TMenuItem("S~a~ve as...", cmSaveAs, kbNoKey) +
       newLine() +
      *new TMenuItem("E~x~it", cmQuit, kbAltX, hcNoContext, "Alt-X");

TSubMenu& editMenu =
    *new TSubMenu("~E~dit", kbAltE) +
      *new TMenuItem("~U~ndo", cmUndo, kbNoKey) +
       newLine() +
      *new TMenuItem("Cu~t~", cmCut, kbNoKey) +
      *new TMenuItem("~C~opy", cmCopy, kbNoKey) +
      *new TMenuItem("~P~aste", cmPaste, kbNoKey);
```

F2 直指 cmSave、F3 直指 cmOpen，而 cmSave 的处理器在 TFileEditor、cmCut 一族在 TEditor——应用层 handleEvent 的 `default: return` 就是给它们让路。Edit 菜单五项全无加速键，启停全凭 updateCommands 的选区判断，禁用时菜单项自动变灰。

## 24.5 selftest 全链路与输出

selftest 探针把编辑器从灌文到双窗的全链路走了一遍：活动窗口取 `deskTop->current`（即构造期开的那个无名档）→ 验 bufLen 与脏标志 → 挪光标验 curPos → bufChar 取头 8 字节 → 填名存盘 → 二进制回读剥 `\r` 比对 → 第二窗 loadFile 同一文件验等长。

```cpp
// ═══ 24.5 探针骨架：current 取焦点窗，第二窗 loadFile 收口 ═══
TEditWindow* w1 = (TEditWindow*)deskTop->current;    // 即构造期开的无名档
TFileEditor* e1 = w1->editor;
Log("插入后 bufLen=%u（strlen=%u） modified=%d\n",
    e1->bufLen, (unsigned)std::strlen(kWelcome), e1->modified ? 1 : 0);
...
TEditWindow* w2 = openEditor("selftest-24-edit.txt");  // 构造即 loadFile
if (w2 && w2->editor)
    Log("第二窗 loadFile 后 bufLen=%u（第一窗 %u） modified=%d\n", ...);
```

起点是 `deskTop->current`——构造期最后插入的窗口即焦点窗，正是那个灌了欢迎文本的无名档；终点是第二窗 openEditor 同一文件，两窗 bufLen 相互印证写读回路闭合。

```bash
cd cppgui
pwsh build.ps1 -Example 24_tv_editor
```

sidecar（`build/docs-ref/24_tv_editor.sidecar`）：

```text
==== 24 tvision 编辑器 开始 ====
插入后 bufLen=188（strlen=185） modified=1
光标@0 → curPos=(0,0)
光标@第二行行首(31) → curPos=(0,1)
bufChar(0..7)='== tvisi'
save()=1 存盘后 modified=0（存盘清脏标志）
回读 188 字节，剥 \r 后 185 字节，与插入文本一致=1
第二窗 loadFile 后 bufLen=188（第一窗 188） modified=0
==== 24 tvision 编辑器 结束 ====
```

逐行解读：**bufLen=188 vs strlen=185**——欢迎文本 185 字节、3 个 `\n`，落缓冲时每个扩成 `\r\n`，多出正好 3 字节；modified=1 是 insertText 置的脏。**光标@0 → (0,0)**、**@(31) → (0,1)**——第二行行首的字节偏移 31 可手算：首行 "== tvision 迷你编辑器 ==" 共 29 字节（CJK 按 UTF-8 每字 3 字节，5 字 = 15 字节）+ CRLF 2 字节 = 31；curPos 从 (0,0) 变 (0,1)，列恒 0 因为行首。**bufChar(0..7)='== tvisi'**——缝隙在文本尾部（刚插入完），从文件头取 8 字节恰好跨过缝的语义验证。**save()=1 存盘后 modified=0**——落盘成功且脏标志被清。**回读 188 字节，剥 \r 后 185，一致=1**——盘上是 CRLF 版，剥掉 \r 与插入文本逐字节相等，写读回路闭合。**第二窗 loadFile 后 bufLen=188（第一窗 188）**——从盘上装回的缓冲与第一窗等长，loadFile 与 save 是同一套行分隔约定的两端。

至此，tvision 五章把菜单、对话框、窗口、调色板、编辑器走完，也把全书四种 GUI/TUI 范式的最后一站走完。

## 坑位清单

- **save() 前必须先填 fileName**：空文件名的 save 转 saveAs 弹文件对话框（模态、等键盘）——无人值守直接挂死；程序化保存先 `strcpy(e->fileName, ...)` 再 save。
- **缓冲行分隔是 \r\n，bufLen ≠ strlen**：insertText 灌入 `\n` 文本每个换行落缓冲变 `\r\n`——185 字节进、bufLen=188 出；回读比对必须剥 `\r`（sidecar：188→185、一致=1）。
- **命令接线分三层，应用层别越位**：cmSave/cmSaveAs 归 TFileEditor，cmCut/cmCopy/cmPaste/cmUndo 归 TEditor（随选区启停），应用层只管 cmNew/cmOpen——在应用层重复处理 cmSave 会双份执行。
- **构造期先全禁编辑类命令**：tvedit1.cpp 的兜底——disableCommands 六连禁，让 updateCommands 随选区/撤销栈自动解禁；不先禁，无选区时菜单里 Cut/Copy 是"活的"点了没反应。
- **别直接摸 buffer，取字走 bufChar**：gap buffer 的缝隙随编辑漂移（curPtr 即缝位），物理下标 ≠ 逻辑下标；bufChar(i) 跨缝换算（sidecar 的 '== tvisi' 即其产物），curPos 由 setCurPtr 同步维护。
- **execDialog 是标准包装**：validView → setData → execView → getData → destroy 五步不可缺——漏 destroy 泄漏，漏"取消不取数"会把半截数据当结果（tvedit2.cpp 原样套路）。

---

上一章：[23 · 三级间接调色板、表单校验与滑块拼图](23-tv-colors-forms.md) ｜ 返回：[README](../README.md) —— 全书 24 章完
