# 02 · 第一个程序与编码纪律

## 1. 从命令行开始：不装 IDE 也能学会语言

Lazarus IDE 很好用，但**学语言阶段最好远离它**——IDE 会替你做太多决定（工程文件、编译参数、
编码），出了问题你不知道是语言的坑还是工具的坑。本教程语言篇（02–14 章）只用一条命令：

```powershell
# fpc 一发完成编译+链接，产出同名 exe（本教程主线工具链见 README）
fpc examples\02_hello\02_hello.pas
.\02_hello.exe
```

本目录 `build.ps1 -Example 02_hello` 做的就是这件事的严格版：同一份源码编两遍
（检查通道 `-Cr -Co -Ci -Sa -B`、发布通道 `-O2`），各跑一次，比对输出逐字节一致。
为什么编两遍？因为 Pascal 的运行期检查（越界、溢出、断言）**由编译开关决定**——
发布通道不检查断言，检查通道全查。两条通道都绿，才算真的对。

## 2. 程序的骨架

```pascal
{$mode objfpc}{$codepage utf8}{$H+}     // 编译指令：方言、源码编码、长字符串（下文详述）
program hello_world;                    { 程序头：名字必须是合法标识符，可以与文件名不同 }
uses SysUtils;                          { 引入标准工具单元：IntToStr、Assert 等都住在这里 }

begin                                   { 主程序体从 begin 开始 }
  WriteLn('你好，Free Pascal！');
end.                                    { 主程序以句点 end. 收尾——全文件唯一一个句点 }
```

四条铁律：

1. **先声明后使用**：Pascal 是单遍编译的语言，任何东西（变量、过程、类型）都必须先声明再用。
   这不是缺陷，是 1970 年代编译器就敢做全程序类型检查的底气——你写的每一行都在被检查。
2. **语句以分号分隔**（不是结束）：`分号` 是语句之间的分隔符，`end` 前的最后一个分号可省。
3. **大小写不敏感**：`begin`、`Begin`、`BEGIN` 是同一个词。社区惯例：关键字小写、
   标识符首字母大写（`WriteLn`、`TSuit`）。
4. **program 名 ≠ 文件名**：文件叫 `02_hello.pas`，program 叫 `hello_world`——标识符不能以
   数字开头，所以本教程所有示例文件名带章号、program 名另取，exe 名由编译器 `-o` 参数决定。

## 3. 三种注释与一个自关闭陷阱

```pascal
{ 花括号注释：可跨多行，里面可以有 // 行注释 }
(* 圆括号-星号注释：与花括号完全等价 *)
// 行注释：到行尾
```

花括号与圆括号-星号**不互相嵌套**：`{ ... (* ... *) ... }` 里那个 `*)` 不结束外层注释；
反过来 `(* ... } ... *)` 里的 `}` 也不结束。真正会咬人的是另一件事（实测坑）：

> **圆括号-星号注释的文字里出现"星号+右括号"会被当作注释结束符**。本教程示例初版写了
> `(* 说明文字里提到 (*) 这个符号 *)`——注释在中间的 `*)` 提前收口，后半句中文全部变成
> "illegal character"编译错误。中文注释里出现括号很常见，写注释时留意。

## 4. Write 与 WriteLn

```pascal
Write('不换行，');
Write('拼接');
WriteLn;                        // 只输出换行
WriteLn('整数：', 42, '  实数：', 3.5:0:2, '  布尔：', True);
```

- 多参数用逗号拼接，类型自动转字符串——不需要格式串（要格式化用第 7 章的 `Format`）。
- `3.5:0:2` 是老 Pascal 的**宽度:小数位**写法：总宽 0（不补空格）、保留 2 位小数。
- 布尔输出是大写 `TRUE`/`FALSE`（Delphi 传统）——想要 `true` 得自己转。

## 5. 编码纪律（本教程最重要的三件套）

**Windows 中文环境 + 中文注释/输出，必须遵守前三条**（第 4 条只在 Unix 上生效），缺一不可：

| # | 规则 | 原因（实测） |
|---|---|---|
| 1 | 源码存 **UTF-8 无 BOM** | BOM 会被某些老工具链当乱码；无 BOM 是本仓库统一纪律 |
| 2 | 程序头加 **`{$codepage utf8}`** | 告诉 FPC 源码是 UTF-8——否则中文字面量按系统码页（GBK）标记 |
| 3 | 运行前 **`chcp 65001`** | FPC 3.2.2 的 `WriteLn` 跟随**活动控制台代码页**做输出转换（重定向也一样） |
| 4 | **Unix/macOS：`uses` 的第一个单元放 `cwstring`** | 不引它 `DefaultSystemCodePage` 是 0（CP_ACP），中文字面量会被逐字节转成 `?`——见 5.1 节 |

为什么第 2 条能救命？看实测矩阵（'中文测试' 6 个汉字、12 个 UTF-8 字节）：

| 源码形态 | `u: UTF8String := s` | WriteLn 中文（GBK 控制台） | WriteLn 中文（65001 控制台） |
|---|---|---|---|
| 无指令（字面量按 GBK 标记） | **乱码**：12 个 UTF-8 字节被当 GBK 再转 UTF-8，变 18 字节 | "碰巧"正常（字节原样直通） | **双重编码乱码** |
| `{$codepage utf8}` | **正确**：无转换，12 字节直通 | 正常（自动转 GBK 显示） | 正常（UTF-8 直通） |

关键结论：**无指令的"裸字节直通"只在 GBK 控制台下碰巧正常**——换个环境（比如
`chcp 65001` 的 CI、Linux）立刻乱码。加了 `{$codepage utf8}`，FPC 的文本输出会按
目标控制台代码页自动转换，**在哪种控制台都显示正确**，管道里抓到的字节也一致。
本教程 `build.ps1`/`run-all.sh` 都先 `chcp 65001` 再跑，就是为了让输出字节可判定。

### 5.1 Unix/macOS 上的第四件套：`cwstring`

Windows 靠 `chcp 65001` 把"活动控制台代码页"设成 UTF-8；Unix 上没有这个开关，
FPC 改由 `cwstring` 单元在初始化时把 `DefaultSystemCodePage` 设成 65001
（RTL 源码 `rtl/objpas/fpwidestring.pp`：`DefaultSystemCodePage:=GetSystemCodepage;`，
而 `GetSystemCodepage` 在 darwin/linux 上默认就返回 `CP_UTF8`）。**少了它**：

```text
不引 cwstring（macOS 12.7 / FPC 3.2.2 实测）    引 cwstring（同环境实测）
DefaultSystemCodePage = 0                        DefaultSystemCodePage = 65001
GetTextCodePage(Output) = 0                      GetTextCodePage(Output) = 65001
WriteLn('你好')  ->  ??                          WriteLn('你好')  ->  你好
```

三条要点：

1. **`cwstring` 必须是 `uses` 的第一个单元**——它装的是 widestring 管理器，
   初始化晚于其它单元就轮不到它定码页。
2. **改 `LANG`/`LC_ALL` 没用**（实测 `en_US.UTF-8`、`zh_CN.UTF-8`、不设，三种都照样变 `?`）——
   别指望运行环境救你，只能在源码里引单元。
3. **只有字面量中招**：`WriteLn` 直接吃字面量时，字面量被定型成 `UnicodeString`
   （二进制里存的是 UTF-16，见第 7 章"字面量重定型"），写出时要按 `TextRec(Output).CodePage`
   转一次；而 `string` 变量是带 65001 标记的 `AnsiString`，码页相同就直接写字节、不转换。
   **"变量正常、字面量变 ?"这种一半对一半的怪象，正是本坑的指纹**——
   所以第 4 条躲不掉，也不能靠"都先赋给变量"绕过。

```pascal
uses
  {$IFDEF UNIX}cwstring,{$ENDIF}   // ★ Unix：必须是 uses 第一个
  SysUtils;
```

> LCL（GUI）工程不用加：`Interfaces` 单元自己就把码页设好了（第 15 章示例在
> macOS/cocoa 下无头 selftest 的中文日志正常）。

还有一条更隐蔽的（第 7 章展开，这里先记现象）：

> 同一个中文字面量，**赋给 string 变量后 `Length` 按字节算（'中文' = 6）**；
> **直接放进表达式（`Length('中文')`）会被重新定型，按字符算（= 2）**。
> 想按字节计数，先存进 `string` 变量再用。

## 6. 编译期内建符号

`{$I %名字%}` 在编译期展开成字符串，比宏安全（有拼写检查）：

```pascal
WriteLn('FPC 版本：', {$I %FPCVERSION%});        // 3.2.2
WriteLn('目标平台：', {$I %FPCTARGETCPU%}, '-', {$I %FPCTARGETOS%});  // x86_64-Win64 / x86_64-Darwin
```

常用符号：`%FPCVERSION%`、`%FPCTARGETOS%`、`%FPCTARGETCPU%`、`%DATE%`、`%LINENUM%`。

> 坑（实测）：编译器版本符号是 **`%FPCVERSION%`**——写成 `%FPVERSION%` 不报错、展开为空，
> 静默产出错误逻辑。平台串是驼峰 `Win64`（`fpc -iTO` 命令行打印的却是小写 `win64`，
> 两种大小写并存，写断言时以实际展开值为准）。它是编译期常量，**跨平台只能断言"属于
> 实测过的平台集合"**——写成 `= 'Win64'` 到 macOS 上必挂（本章示例因此改成集合断言）。

## 7. 示例与验证

本章示例 `examples/02_hello`：三种注释、Write/WriteLn、编码三件套、内建符号。
验证：

```powershell
pwsh -File build.ps1 -Example 02_hello     # check + release 双通道 + 输出一致性
```

示例约定（全书一致）：关键断言 `Assert(...)` 自检（只在检查通道生效）、末行
`==== 02 结束 ====` 结束标记供脚本判定。

## 8. 坑位清单（实测）

1. `(*` 注释文字里的 `*)` 提前收口，后半段中文全成"非法字符"。
2. 无 `{$codepage utf8}` 的中文串：`String→UTF8String` 转换双重编码乱码；
   裸字节直通只在 GBK 控制台"碰巧"正常。
3. WriteLn 的输出跟随**活动控制台代码页**（重定向也一样），验证脚本必须先 `chcp 65001`。
4. 中文**字面量**直接进表达式与先存 `string` 变量行为不同（Length 6 vs 2）。
5. `%FPVERSION%` 不存在（正确是 `%FPCVERSION%`），不报错、展开为空。
6. 断言 `Assert` 只在 `-Sa`（或 `{$C+}`）下编进代码——发布通道静默跳过，错误的断言
   在 `-O2` 下发现不了。**这就是双通道验证存在的理由**。

---
上一章：[01 全景与工具链](01-overview.md) ｜ 下一章：[03 类型与变量](03-types.md) ｜ 返回：[README](../README.md)
