{$mode objfpc}{$codepage utf8}{$H+}
program hello_world;
{ 02 · 第一个程序——冒烟版：验证编码纪律三件套与结束标记约定。
  完整教学内容在 docs/02-hello.md（正章版由批次 A 完善）。 }
uses SysUtils;

begin
  WriteLn('你好，Free Pascal！');
  WriteLn('编译器版本：', {$I %FPCVERSION%}, '（编译期内建符号 {$I %FPCVERSION%}）');
  Assert({$I %FPCVERSION%} = '3.2.2', '本教程主线为 FPC 3.2.2');

  WriteLn('整数运算：7 div 2 = ', 7 div 2, '，7 mod 2 = ', 7 mod 2);
  Assert(7 div 2 + 7 mod 2 = 4);

  WriteLn('==== 02 结束 ====');
end.
