{$mode objfpc}{$codepage utf8}{$H+}
program arrays_demo;
{ 06 · 数组与集合：静态/动态数组、SetLength、引用共享语义、多维、集合运算。
  正文见 docs/06-arrays.md。 }
uses
  {$IFDEF UNIX}cwstring,{$ENDIF}   // ★ Unix：必须是 uses 第一个——否则 WriteLn 中文字面量全变 ?（见 02 章 2.3）
  SysUtils;

type
  TWeek = array[1..7] of string;          // 静态数组：下标范围自己定，不必从 0 开始
  TGrid = array[0..2, 0..2] of Integer;   // 静态二维
  TInts = array of Integer;               // 动态数组：长度运行期决定
  TDigits = set of 0..15;                 // 集合：基类型必须序数且 ≤256 个值

// ═══ 6.1 静态数组：定长、自定义下标、整体赋值是深拷贝
procedure ShowStaticArrays;
var
  week: TWeek;
  copyWeek: TWeek;
  i: Integer;
begin
  week[1] := '周一'; week[2] := '周二'; week[3] := '周三';
  week[4] := '周四'; week[5] := '周五'; week[6] := '周六'; week[7] := '周日';
  Assert(Low(week) = 1);
  Assert(High(week) = 7);
  Assert(Length(week) = 7);

  copyWeek := week;                        // 静态数组整体赋值 = 逐元素深拷贝
  copyWeek[1] := 'Monday';
  Assert(week[1] = '周一', '静态数组赋值即拷贝，改副本不动本体');

  for i := Low(week) to High(week) do      // 下标范围用 Low/High，别写死 1..7
    Write(' ', week[i]);
  WriteLn;
end;

// ═══ 6.2 动态数组：SetLength 分配，赋值却是"共享"——与静态数组相反！
procedure ShowDynamicArrays;
var
  a, b: TInts;
  i: Integer;
begin
  SetLength(a, 5);                         // 长度 0 开始，SetLength 分配
  Assert(Length(a) = 5);
  for i := 0 to High(a) do                 // 动态数组下标恒为 0..High
    a[i] := i * i;

  b := a;                                  // 坑（实测）：动态数组赋值 = 共享同一块内存
  b[0] := 999;
  Assert(a[0] = 999, 'a 和 b 是同一个数组的两个名字（引用计数指针）');

  SetLength(b, 3);                         // SetLength 时才"脱离共享"（重新分配/引用计数减一）
  Assert(Length(a) = 5, 'b 缩容后 a 长度不变——引用分离发生在 SetLength');
  Assert(a[0] = 999, '分离是拷贝当时的值');

  // 要独立副本：显式拷贝
  SetLength(b, Length(a));
  Move(a[0], b[0], Length(a) * SizeOf(Integer));
  b[1] := -1;
  Assert(a[1] = 1, 'Move 拷贝后互不影响');

  a := [10, 20, 30];                       // 动态数组字面量（FPC 3.x）
  Assert((a[0] = 10) and (a[2] = 30));
  WriteLn('动态数组：a=', Length(a), ' 个元素，首=', a[0], ' 尾=', a[High(a)]);
end;

// ═══ 6.3 多维动态数组：数组的数组，逐维 SetLength
procedure Show2DArrays;
var
  m: array of array of Integer;
  rows, cols, r, c: Integer;
begin
  rows := 3; cols := 4;
  SetLength(m, rows);                      // 先定行数
  for r := 0 to rows - 1 do
    SetLength(m[r], cols);                 // 再定每行列数——可以不规则（锯齿数组）
  for r := 0 to High(m) do
    for c := 0 to High(m[r]) do
      m[r][c] := r * 10 + c;               // m[r][c] 与 m[r,c] 等价
  Assert(m[2][3] = 23);
  Assert(Length(m) = 3);
  Assert(Length(m[0]) = 4);
  WriteLn('二维动态数组 3x4：m[2][3]=', m[2][3], '（行主序，锯齿可行）');
end;

// ═══ 6.4 数组作参数：开放数组最通用；动态数组参数可以改长度
procedure DoubleAll(var arr: TInts);       // var + 动态数组：过程内可改长度并回传
var
  i: Integer;
begin
  for i := 0 to High(arr) do
    arr[i] *= 2;
  SetLength(arr, Length(arr) + 1);         // 追加一个元素
  arr[High(arr)] := -1;
end;

function Total(const values: array of Integer): Integer;   // 开放数组：任意数组都能进
var
  v: Integer;
begin
  Result := 0;
  for v in values do
    Result += v;
end;

procedure ShowArrayParams;
var
  a: TInts;
begin
  a := [1, 2, 3];
  DoubleAll(a);
  Assert((a[0] = 2) and (a[3] = -1), 'var 动态数组参数：改元素与改长度都回传');
  Assert(Total(a) = 11, '2+4+6+(-1)=11');
  Assert(Total([5, 5]) = 10, '字面量走开放数组');
  WriteLn('数组参数：翻倍+追加后 Total=', Total(a));
end;

// ═══ 6.5 集合 set：并交差、in、for-in，位图实现
procedure ShowSets;
var
  prime, odd, both, either, diff: TDigits;
  d: Integer;
  cnt: Integer;
begin
  prime := [2, 3, 5, 7];
  odd := [1, 3, 5, 7, 9];
  both := prime * odd;                     // 交集
  either := prime + odd;                   // 并集
  diff := prime - odd;                     // 差集
  Assert(both = [3, 5, 7]);
  Assert(either = [1..3, 5, 7, 9]);        // 集合字面量也能用子界
  Assert(diff = [2]);
  Assert(odd <> prime);                    // 比较：包含关系用 <= >=
  Assert([3, 5] <= prime, '子集判断：[3,5] <= prime');

  Assert(7 in prime);                      // in：成员判断，集合最常用的场合
  Assert(not (4 in prime));

  cnt := 0;
  for d in either do                       // for-in 只迭代存在的元素
    Inc(cnt);
  Assert(cnt = 6);

  Include(prime, 11);                      // Include/Exclude：比 prime := prime + [11] 快
  Exclude(prime, 2);
  Assert(prime = [3, 5, 7, 11]);

  WriteLn('集合位图：SizeOf(TDigits)=', SizeOf(TDigits),
    ' 字节（16 个可能值只占 16 位，但 FPC 按 32 位粒度分配到 4 字节）');
  Assert(SizeOf(TDigits) = 4, '实测：set of 0..15 是 4 字节；set of Byte 是 32 字节');
  // 坑（实测）：Include(s, 11) 在 set of 0..9 上是【编译期】range check error——
  // "range check error while evaluating constants (11 must be between 0 and 9)"，
  // 越界常量根本活不过编译（这是好事）
  WriteLn('并集元素数=', cnt, '（1,2,3,5,7,9）');
end;

var
  grid: TGrid;
  r, c: Integer;
begin
  WriteLn('═══ 6.1 静态数组');
  ShowStaticArrays;
  WriteLn('═══ 6.2 动态数组');
  ShowDynamicArrays;
  WriteLn('═══ 6.3 多维动态数组');
  for r := 0 to 2 do
    for c := 0 to 2 do
      grid[r, c] := r * 3 + c;
  Assert(grid[1][1] = 4);
  Show2DArrays;
  WriteLn('═══ 6.4 数组作参数');
  ShowArrayParams;
  WriteLn('═══ 6.5 集合');
  ShowSets;
  WriteLn;
  WriteLn('==== 06 结束 ====');
end.
