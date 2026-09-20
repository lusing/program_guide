# FreePascal/Lazarus CHEAT Sheet（FPC 3.2.2 / Lazarus 4.8 实测）

> 配套 [README](README.md) 与 docs/ 24 章；所有坑位来自本仓库示例的实测（每章末
> "坑位清单"的汇总索引）。

## 1. 源码头三件套（每个 .pas/.lpr 第一行）

```pascal
{$mode objfpc}{$codepage utf8}{$H+}
```

| 指令 | 作用 | 不写的后果（实测） |
|---|---|---|
| `{$mode objfpc}` | 方言 | 语法差异（@、泛型） |
| `{$codepage utf8}` | 源码编码声明 | 中文字面量按 GBK 标记：UTF8String 转换双重编码 |
| `{$H+}` | string=AnsiString | string 变 ShortString（255 截断） |

运行环境补第三件：**`chcp 65001`**（WriteLn 跟随活动控制台码页转码，重定向也一样）。

Unix/macOS 补第四件：**`uses` 第一个单元放 `cwstring`**（否则 `DefaultSystemCodePage=0`，
中文字面量全变 `?`；改 `LANG`/`LC_ALL` 无效）：

```pascal
uses
  {$IFDEF UNIX}cwstring,{$ENDIF}   // ★ 必须是 uses 第一个
  SysUtils;
```

## 2. 类型速查（win64 / x86_64-darwin 实测）

```text
Integer=4(恒定)  Int64/QWord=8  NativeInt/PtrInt=8  Pointer=8
Single=4  Double=8  Extended=8(win64, =Double!) / 10(darwin, 真80位)
Boolean=1  Char=1  String=8(指针)  ShortString=256  Variant=24
enum=4  子界按值域(0..9→1字节)  set of 0..15=4字节(32位粒度)
```

## 3. 语法速查

```pascal
var x: Integer = 5;                       // 初始化
s := '中文';                               // Length=6（字节）；Length('中文')=2（字符）！
if c then a else b;                        // else 前禁分号
case n of 90..100: ; 60,65: ; else end;    // 子界+列表；仅序数类型
for i := 1 to 10 / downto 1 do             // 边界只求值一次
for v in arr/s/set/Enum do                 // 四种 for-in
// 参数五修饰
procedure P(n: Integer); const s: string; var m: Integer; out r: string; constref b: TBig;
// 开放数组/万能参数
function Sum(values: array of Integer): Integer;
Format('%s=%d %.2f %x', [s, n, f, 255]);
// 异常
try ... finally ... end;   try ... except on E: EXxx do ... else ... end;
raise EFoo.Create('...');  raise;           // 转发 / 原样重抛
Assert(cond, 'msg');                        // 仅 {$C+}/-Sa 下生效！
// 动态数组/集合
SetLength(a, n);   a := [1,2,3];            // 赋值=共享！
prime := [1..3, 5];  if 7 in prime then;    Include/Exclude
// OOP
constructor Create; destructor Destroy; override;
property X: T read FX write SetX;
virtual; override; abstract;  // is / as / class of / class function / class var
// 泛型（objfpc）
generic TBox<T> = class ... end;
type TIntBox = specialize TBox<Integer>;    // 使用点处处 specialize
// 单元
unit u; interface implementation initialization finalization end.
```

## 4. GUI 速查

```pascal
uses Interfaces, Forms, ...;               // Interfaces 必须第一个 LCL 单元
f := TForm.CreateNew(nil);                  // 纯代码窗体（跳过 lfm）
btn := TButton.Create(Self); btn.Parent := Panel;   // Owner 管 Free，Parent 管显示
btn.OnClick := @BtnClick;                   // objfpc 事件赋值带 @
Align: alTop/alBottom/alLeft/alRight/alClient;  Anchors:=[akTop,akRight];
f.Show / ShowModal=mrOk / Close;
Application.Initialize; Application.Run;    // 消息循环
// Action 三绑定
a := TAction.Create(Self); a.OnExecute := ...;
menuItem.Action := a;  toolBtn.Action := a; // Caption/快捷键/Enabled 单一来源
// 线程
TThread.Create(False); Synchronize(@M)/Queue(@M); CheckSynchronize; Terminate(协作式)
```

## 5. 编译/验证命令

```powershell
pwsh -File build.ps1 -All              # 23 示例全量（CLI 双通道 + GUI selftest）
pwsh -File build.ps1 -Example 07_strings
pwsh -File build.ps1 -Gui              # 只跑 GUI 工程
pwsh -File build.ps1 -Clean
./run-all.sh                           # Git Bash 等价入口
fpc -MObjFPC -Cr -Co -Ci -Sa -B xx.pas # 检查通道（手工版）
fpc -gh xx.pas                          # heaptrc 泄漏排查（stderr）
lazbuild project.lpi                    # GUI 工程（只认 .lpi）
```

## 6. 坑位总索引（实测，按主题）

**编码（02/07/11/24 章）**
1. 无 `{$codepage utf8}`：字面量按 GBK 标记 → UTF8String 转换双重编码；裸字节直通
   仅在 GBK 控制台"碰巧"正常。
   1b. **Unix 不引 `cwstring`**：`DefaultSystemCodePage=0`，`WriteLn` 的中文字面量被逐
   字节转成 `?`（**只中招字面量**，赋过值的 `string` 变量正常——半对半的怪象是本坑指纹）；
   `LANG`/`LC_ALL` 改不动它，只能在 `uses` 第一个位置引单元。LCL 工程不用加。
2. `Length('中文')`=2（字面量在无类型上下文按 UnicodeString）/ `Length(s)`=6（变量按
   字节）——for-in 同裂（4 次 vs 8 次）。**要字节先入 string 变量**。
3. 同串三坐标：Length 字节 / Pos 字符（UTF-8 特例）/ Copy 字节。
4. 赋值保留字面量码页（StringCodePage=65001 非 936）；标记比字节重要
   （SetCodePage(raw,936,False) 乱码实验）。
5. TextFile 默认按系统码页标记读写——AssignFile 后立即 `SetTextCodePage(f,65001)`。
6. TIniFile 走 Windows ANSI API：中文节/键按 GBK 落盘且键查不到——节/键一律 ASCII。
7. TStrings.LoadFromFile 默认 ANSI 读——UTF-8 文件显式 `TEncoding.UTF8`。

**类型/运算（03/04 章）**
8. 枚举成员叫 Low/High 遮蔽内建 → 全程序 `Low(..)` 报 `")" expected but "(" found`。
9. `1.0/3.0` 常量折叠消除舍入差——演示 Single/Double 损耗用变量做除法。
10. Round 银行家舍入（2.5→2）；Trunc 向零截断。
11. `/` 恒为实数除；div/mod 商零截、余随被除数。
12. 常量除零是**编译期**错误（除数常量 0）。
13. objfpc 无 `and then/or else`（仅 MacPas）——默认 `{$B-}` 短路，`{$B+}` 完全求值。
14. `[1..5]` 是集合构造器不是数组。

**数组/字符串/指针（06/08 章）**
15. 动态数组赋值=共享；SetLength 才分离；record 赋值=深拷贝（语义相反）。
16. 集合 SizeOf 按 32 位粒度（set of 0..15=4 字节）；Include 常量越界=编译期错误。
17. record 方法需 `{$modeswitch advancedrecords}`；class 不能重载运算符。
18. `{$POINTERMATH ON}` 后 `p+n` 按**元素宽度**。
19. objfpc 传函数地址必须 `@`；cdecl/stdcall 用错=玄学崩溃；`varargs` 调用直接罗列参数。
   19b. `external` 的库名是平台相关的：Windows `msvcrt` / Unix `c`——库名必须是编译期
   字面量，只能 `{$IFDEF}` 分叉两条声明，不能写成变量。
   19c. C 的 `printf` 与 Pascal 的 `Output` 是两套缓冲：不先 `Flush(Output)`，
   两边退出时各刷一次，顺序不定 → 双通道输出比对随机失败。
20. `-gh` 报告走 stderr（零泄漏也打）。

**单元/工程（09 章）**
21. uses 是**段级**的：实现段用 Format 没引 SysUtils → Identifier not found。
22. `{$DEFINE}` 放 const 段报 `"identifier" expected but "BEGIN"`。

**OOP/泛型（12–14 章）**
23. private 是单元级不是类级（同单元随便摸）。
24. 类引用构造按基类签名（除非 virtual）——LCL TComponent 流机制根源。
25. 对象引用+接口引用混用=双重释放。
26. objfpc 泛型使用点处处 `specialize`；3.2.2 无独立泛型函数（包进泛型类）。
27. `TDictionary<string,...>` 中文键查不到（比较器码页敏感）——键用 UTF8String。

**GUI（15–24 章）**
28. `Interfaces` 必须 uses 第一；lazbuild 只认 .lpi；exe 落 `lib/<CPU>-<OS>/`。
29. lfm 字段须默认可见性（published）才被流填充；OnClick 方法名错=运行时错。
30. GUI 未捕获异常弹 LCL 框——无头挂死；selftest 必须 try-except 自捕获
    （脚本另有 60s 超时击杀双保险）。
31. TFrame 无 CreateNew、Create 必须配 .lfm（Resource not found）。
32. TDateTimePicker 在独立包 datetimectrls。
33. 程序化赋值触发事件因控件而异：Edit.Text ✓ / CheckBox.Checked ✓ /
    RadioGroup.ItemIndex ✓ / ComboBox.ItemIndex ✗ / **Memo.Lines.Add 与 Text:= ✗**。
34. 忘设 Parent 控件不显示（Owner 管 Free / Parent 管显示）。
35. TForm 字段撞内建属性名（Menu）→ Duplicate identifier；with 块内 Self 仍指窗体。
36. MenuItem.Add 只收 TMenuItem——挂 Action 包一层。
37. Splitter.ResizeControl 在 LCL 不保真（就近自动关联）。
38. TreeView Items[] 是 **DFS 序**非插入序——挂数据用 AddChild 返回值。
39. OnPaint 之外画=白画；TPaintBox 内容不持久；clBlack=$00000000 与黑底判据失明。
40. 线程：非主线程禁碰控件（Synchronize/Queue 唯一通道）；无消息循环手动
    CheckSynchronize；非 TPersistent 类不能进 TForm 默认（published）段。
41. TTabSheet 无 Data 属性；行列换算从 SelStart **从左往右**扫 #10。

**工具链（01 章/脚本）**
42. scoop 独立 freepascal 包只有 i386——解析顺序错=静默 32 位 exe。
43. `-FE/-FU/-o` 相对路径按**源文件目录**解析——给绝对路径。
44. `%FPVERSION%` 不存在（正确 `%FPCVERSION%`）；平台串驼峰 `Win64`/`Darwin`
   （`fpc -iTO` 打印的是小写）——跨平台断言只能写"属于实测集合"。
45. Git Bash 传参：`cygpath -m` + `MSYS2_ARG_CONV_EXCL='*'`。
46. 断言仅 `-Sa` 生效——错误的断言在 -O2 下静默通过（双通道验证的理由）。
47. macOS：`SizeOf(Extended)=10`（win64 是 8）——断言宽度会挂，只能写 `>= SizeOf(Double)`。
48. macOS：`Extract*` 三件套照样认反斜杠（实测返回 `demo.txt`），但
   `DirectorySeparator='/'`、`PathSep=':'`、`Length(LineEnding)=1`。
49. macOS：LCL 控件集是 **cocoa**（系统只预编译了 cocoa 与 nogui）；lazbuild 首次会
   把 LCL 编进 `~/.lazarus/lib/`；产物是 `lib/x86_64-darwin/<名>` + `<名>.app`——
   定位 exe 只查 `lib/*/` 一层，否则会捞到 `.app` 包里的另一份同名可执行文件。
50. macOS：`FormatDateTime('dddd')` 打 `Saturday`（随 locale），别断言。
   50b. **Unix 漏 `cthreads`**：编译链接全过，运行才 `Runtime error 232
   "no thread support compiled in"`——用了 `TThread`/`SyncObjs` 的工程必须在 uses
   第一行写 `{$IFDEF UNIX}cthreads,{$ENDIF}`（向导的 `{IFDEF UseCThreads}` 默认不展开）。
51. **验证脚本自己**：`why="${why:+$why；}..."` 这种拼接在 bash 5.3 下会把全角分号的
   首字节吞进变量名（`why?: unbound variable`），且只在失败分支真被展开时才炸——
   原因一律用数组收集。
