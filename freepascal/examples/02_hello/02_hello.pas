{$mode objfpc}{$codepage utf8}{$H+}
program hello_world;
{ 02 · 第一个程序：program 结构、Write/WriteLn、编码纪律、编译期内建符号。
  正文见 docs/02-hello.md；本示例按 ═══ 2.M 分节与正文小节对应。 }
uses
  {$IFDEF UNIX}cwstring,{$ENDIF}   // ★ Unix：必须是 uses 第一个——否则 WriteLn 中文字面量全变 ?（见 02 章 2.3）
  SysUtils;

var
  s: string;

// ═══ 2.1 三种注释：花括号、圆括号-星号、// 行注释
{ 块注释：可跨多行，
  里面还能有 // 行注释 }
(* 圆括号-星号块注释，与花括号等价 *)
// 坑（实测）：圆括号-星号注释的文字里别再出现星号-右括号这对字符，
// 它会被当作注释结束符提前收口，剩下的中文文字全变成"非法字符"——本示例初版就踩过

// ═══ 2.2 Write 与 WriteLn：WriteLn 末尾追加换行，多个参数用逗号拼接
begin
  WriteLn('你好，Free Pascal！');
  Write('Write 不换行，');
  Write('两个 Write 拼成一行');
  WriteLn;                          // 无参数形式：只输出换行
  WriteLn('整数：', 42, '  实数：', 3.5:0:2, '  布尔：', True);
  // 3.5:0:2 是"宽度:小数位"格式化——古老的 Pascal 写法，第 7 章换成 Format

  // ═══ 2.3 编码纪律：源码 UTF-8 无 BOM + {$codepage utf8}，运行环境 chcp 65001
  WriteLn('中文输出正常 = 编码三件套就位（详见正文 2.3 节实测）');
  s := '中文';                     // 赋给 string 变量：UTF-8 字节原样保留
  Assert(Length(s) = 6, 'AnsiString 按字节计长：两个汉字 6 个 UTF-8 字节');
  // 坑（实测）：同一字面量直接放进表达式（不经 string 变量）会被重新定型，
  // Length('中文') = 2（按"字符"而非字节）——第 7 章专讲

  // ═══ 2.4 编译期内建符号：{$I %名字%} 在编译期展开成字符串
  WriteLn('FPC 版本：', {$I %FPCVERSION%});
  WriteLn('目标平台：', {$I %FPCTARGETCPU%}, '-', {$I %FPCTARGETOS%});
  Assert({$I %FPCVERSION%} = '3.2.2', '本教程主线为 FPC 3.2.2');
  // 坑（实测）：内建符号展开的是驼峰平台串（Win64 / Darwin / Linux），与
  // fpc -iTO 打印的 win64 / darwin / linux 大小写不同。它是编译期常量，
  // 跨平台**不能**断言固定值——只能断言"属于实测过的平台集合"。
  // （2026-09 macOS 实测：这里拿到 'Darwin' 而 fpc -iTO 打印 darwin。）
  Assert(({$I %FPCTARGETOS%} = 'Win64') or ({$I %FPCTARGETOS%} = 'Darwin'),
         '本示例在 Win64 与 Darwin 两个平台上实测过');

  // ═══ 2.5 自检与结束标记
  Assert(7 div 2 + 7 mod 2 = 4);
  WriteLn('==== 02 结束 ====');
end.
