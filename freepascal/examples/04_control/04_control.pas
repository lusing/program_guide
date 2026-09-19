{$mode objfpc}{$codepage utf8}{$H+}
program control_demo;
{ 04 · 运算符与控制流：/ 与 div、if/case、三种循环、for-in、循环控制语句、短路布尔。
  正文见 docs/04-control.md。 }
uses SysUtils;

type
  TSuit = (Club, Diamond, Heart, Spade);

// ═══ 4.1 运算符：/ 永远是实数除，div/mod 才是整数世界
procedure ShowOperators;
begin
  WriteLn('7 / 2   = ', 7 / 2:0:6, '（Real 结果）');
  WriteLn('7 div 2 = ', 7 div 2, '（截断整数商）');
  WriteLn('7 mod 2 = ', 7 mod 2, '（余数符号跟被除数）');
  WriteLn('-7 div 2 = ', -7 div 2, '  -7 mod 2 = ', -7 mod 2);
  Assert((-7 div 2) = -3);
  Assert((-7 mod 2) = -1, 'mod 的符号跟随被除数（跟 C 的 % 一致，跟数学定义不同）');
  Assert(7 mod -2 = 1);
  // shl/shr 位运算、not/and/or/xor 整数按位——Pascal 用英文单词，不用符号
  WriteLn('1 shl 10 = ', 1 shl 10, '  255 and 15 = ', 255 and 15, '  not 0 = ', not 0);
  Assert((1 shl 10) = 1024);
end;

// ═══ 4.2 if/then/else：分号陷阱与悬垂 else
procedure ShowIf;
var
  score: Integer;
begin
  score := 87;
  if score >= 90 then
    WriteLn('优秀')
  else if score >= 60 then
    WriteLn('及格，分数=', score)
  else
    WriteLn('不及格');

  // 坑：else 前不能加分号——"if ... then 语句;" 后接 else 是语法错误
  if score > 0 then
    if score > 85 then WriteLn('  嵌套：>85')
    else WriteLn('  嵌套：0<score<=85')   // else 属于最近的 if
  else WriteLn('  外层：score<=0');
  Assert(score in [60..100]);
end;

// ═══ 4.3 case：子界、列表、逗号组合，比 switch 灵活
procedure ShowCase(score: Integer);
begin
  case score of
    90..100:     WriteLn('A');
    80..89:      WriteLn('B');
    60, 65, 70..79: WriteLn('C（列表与子界混用）');
  else
    WriteLn('F');
  end;
end;

// ═══ 4.4 while 与 repeat：先判断与后判断（repeat 至少执行一次）
procedure ShowWhileRepeat;
var
  n, sum: Integer;
begin
  n := 1; sum := 0;
  while n <= 10 do
  begin
    sum += n;                          // += 是 FPC 扩展（等价 sum := sum + n）
    Inc(n);
  end;
  Assert(sum = 55);

  n := 10;
  repeat
    Dec(n);
  until n = 0;                         // until 条件为真时结束
  Assert(n = 0);
  WriteLn('while 求 1..10 和=', sum, '；repeat 倒数到 ', n);

  // repeat 至少执行一次的经典差异：
  n := 0;
  while n <> 0 do WriteLn('永不执行');
  repeat WriteLn('repeat 块执行了一次（n=0 也先进门）'); until True;
end;

// ═══ 4.5 for/downto：循环边界只求值一次
procedure ShowFor;
var
  i, total: Integer;
  limit: Integer;
begin
  total := 0;
  for i := 1 to 10 do
    total += i * i;
  Assert(total = 385);

  for i := 10 downto 1 do               // downto 倒数
    if i = 1 then WriteLn('for 倒数到达 ', i);

  limit := 3;
  for i := 1 to limit do
  begin
    Write(' ', i);
    limit := 100;                       // 坑：改上限不影响本轮循环——边界只在进入时求值一次
  end;
  WriteLn;
  Assert(i = 3, '循环结束后 i 停在终值（退出后仍可读，但别依赖它）');
end;

// ═══ 4.6 for-in：遍历数组、字符串、集合
procedure ShowForIn;
var
  names: array[0..2] of string = ('甲', '乙', '丙');
  s: string;
  ch: Char;
  cnt: Integer;
  suit: TSuit;
  digits: set of 0..9;
  d: Integer;
begin
  for s in names do
    Write(' [', s, ']');
  WriteLn;

  s := 'ab中文';
  cnt := 0;
  for ch in s do                        // string 变量的 for-in 按字节迭代
    Inc(cnt);
  WriteLn('变量 ''ab中文'' 按字节迭代次数=', cnt, '（a,b + 6 个 UTF-8 字节）');
  Assert(cnt = 8);

  cnt := 0;
  for ch in 'ab中文' do                 // 坑（实测）：直接写字面量按"字符"迭代——
    Inc(cnt);                           // 4 次（a,b,中,文），与变量行为不同！
  WriteLn('字面量 ''ab中文'' 迭代次数=', cnt, '（按字符而非字节，第 7 章详述）');
  Assert(cnt = 4);

  digits := [1, 3, 5];
  cnt := 0;
  for d in digits do Inc(cnt);          // 集合的 for-in 只数存在的元素
  Assert(cnt = 3);

  for suit in TSuit do                  // 枚举也能 for-in（Low..High）
    Write(' ', suit);
  WriteLn;
end;

// ═══ 4.7 Break/Continue/Exit：三把出口钥匙
procedure ShowLoopControl;
var
  i: Integer;
begin
  for i := 1 to 100 do
  begin
    if i mod 2 = 0 then Continue;       // 跳过偶数
    if i * i > 200 then Break;          // 平方超界即停
    Write(' ', i);
  end;
  WriteLn('（Break 时 i=', i, '）');

  // Exit 只退出当前过程；Halt 才是终止整个程序（教程示例统一用 Exit + 末尾标记）
  if i > 20 then
    WriteLn('Exit 之前的逻辑照常执行');
end;

// ═══ 4.8 短路布尔：objfpc 的 and/or 默认就是短路求值（$B-）
var
  CallCount: Integer = 0;          // 计数器：右侧函数是否被求值

function Positive: Boolean;
begin
  Inc(CallCount);
  Result := True;
end;

function SafeCheck(index: Integer; arr: array of Integer): Boolean;
begin
  // 左侧为假时右侧不求值——arr[index] 的下标检查不会触发
  Result := (index >= 0) and (index <= High(arr)) and (arr[index] > 0);
end;

procedure ShowShortCircuit;
var
  a: array[0..2] of Integer = (5, -1, 7);
begin
  // 实测（正文 4.8）：FPC 全部模式默认 $B-（短路），右侧 Positive 不被调用
  if (1 > 2) and Positive then
    WriteLn('不可能到达');
  Assert(CallCount = 0, '左侧为假，右侧被短路跳过');

  Assert(SafeCheck(0, a));
  Assert(not SafeCheck(1, a));
  Assert(not SafeCheck(99, a), '越界索引被短路挡下，右侧不求值（-Cr 下也不报）');

  {$B+}                           // 打开完全求值：右侧总会执行
  if (1 > 2) and Positive then
    WriteLn('不可能到达');
  {$B-}
  Assert(CallCount = 1, '$B+ 下右侧照常求值');
  WriteLn('短路布尔实测：默认 $B- 短路；{$B+} 完全求值；and-then/or-else 运算符仅 MacPas 模式有');
end;

begin
  WriteLn('═══ 4.1 运算符');
  ShowOperators;
  WriteLn('═══ 4.2 if/then/else');
  ShowIf;
  WriteLn('═══ 4.3 case');
  ShowCase(95); ShowCase(85); ShowCase(72); ShowCase(59);
  WriteLn('═══ 4.4 while 与 repeat');
  ShowWhileRepeat;
  WriteLn('═══ 4.5 for/downto');
  ShowFor;
  WriteLn('═══ 4.6 for-in');
  ShowForIn;
  WriteLn('═══ 4.7 Break/Continue/Exit');
  ShowLoopControl;
  WriteLn('═══ 4.8 短路布尔');
  ShowShortCircuit;
  WriteLn;
  WriteLn('==== 04 结束 ====');
end.
