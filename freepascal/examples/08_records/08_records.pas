{$mode objfpc}{$codepage utf8}{$H+}{$modeswitch advancedrecords}
program records_demo;
{ 08 · 记录与指针：record 高级特性、packed 布局、指针三件套、指针算术、
  过程类型回调、external 调 DLL、内存纪律与 heaptrc。正文见 docs/08-records.md。 }
uses SysUtils;

type
  TPoint2D = record
    X, Y: Double;
  end;

  TVec2 = record    // record 方法/运算符需要 advancedrecords（已在文件头开启）
  public
    X, Y: Double;
    function Len: Double;
    class operator +(const a, b: TVec2): TVec2;     // record 可重载运算符（类不行）
    class operator =(const a, b: TVec2): Boolean;
  end;

  // variant record：一段内存两种解释（最后一段必须是 case）
  TPacket = record
    Kind: Integer;
    case Boolean of
      True:  (Raw: array[0..3] of Byte);
      False: (Value: Integer);
  end;

  PInteger = ^Integer;
  TComparator = function(a, b: Integer): Integer;    // 过程类型：函数指针

function TVec2.Len: Double;
begin
  Result := Sqrt(X * X + Y * Y);
end;

class operator TVec2.+(const a, b: TVec2): TVec2;
begin
  Result.X := a.X + b.X;
  Result.Y := a.Y + b.Y;
end;

class operator TVec2.=(const a, b: TVec2): Boolean;
begin
  Result := (a.X = b.X) and (a.Y = b.Y);
end;

// ═══ 8.1 record 基础与 with
procedure ShowRecordBasics;
var
  p, q: TPoint2D;
begin
  p.X := 3; p.Y := 4;
  with p do                                // with：省略重复的前缀（别嵌套，可读性差）
    Assert(X * X + Y * Y = 25);
  q := p;                                  // record 赋值 = 深拷贝（与动态数组相反！）
  q.X := 99;
  Assert(p.X = 3, 'record 赋值即拷贝');
  WriteLn('record：p.Len 语义的手算是 ', Sqrt(p.X * p.X + p.Y * p.Y):0:1);
end;

// ═══ 8.2 packed：紧凑布局 vs 对齐填充
procedure ShowPacked;
type
  TPadded = record
    A: Byte;        // 1 字节
    B: Integer;     // 对齐到 4 的倍数 → A 后面 3 字节填充
  end;
  TPackedRec = packed record
    A: Byte;
    B: Integer;
  end;
begin
  WriteLn('SizeOf: 普通=', SizeOf(TPadded), ' packed=', SizeOf(TPackedRec));
  Assert(SizeOf(TPadded) = 8);
  Assert(SizeOf(TPackedRec) = 5, 'packed 去掉填充——与文件格式/网络协议对字节时必用');
end;

// ═══ 8.3 variant record：一段内存两种视图
procedure ShowVariantRecord;
var
  pkt: TPacket;
begin
  pkt.Kind := 1;
  pkt.Value := $01020304;                  // 整数视图写入
  Assert(pkt.Raw[0] = 4, '小端机：最低字节落 Raw[0]（同一块内存的另一种解释）');
  WriteLn('variant record：同一 4 字节，Integer 视图=', pkt.Value,
    ' Byte 视图首字节=', pkt.Raw[0]);
end;

// ═══ 8.4 record 方法与运算符重载（FPC 扩展）
procedure ShowRecordMethods;
var
  v, w: TVec2;
begin
  v.X := 3; v.Y := 4;
  Assert(Abs(v.Len - 5) < 1e-12);
  w := v + v;                              // class operator +
  Assert((w.X = 6) and (w.Y = 8));
  WriteLn('record 运算符：v+v = (', w.X:0:0, ',', w.Y:0:0, ')，Len(v)=', v.Len:0:0);
end;

// ═══ 8.5 指针基础：@ 与 ^，New/Dispose
procedure ShowPointers;
var
  n: Integer;
  p: PInteger;
begin
  n := 42;
  p := @n;                                 // @ 取地址
  p^ := 99;                                // ^ 解引用写入
  Assert(n = 99, '指针改的就是本体');
  Assert(p^ = 99);

  New(p);                                  // 堆上分配一个 Integer（typed pointer）
  p^ := 7;
  Assert(p^ = 7);
  Dispose(p);                              // 配对释放；New/Dispose 必须严格成对
  WriteLn('指针：@/^ 与 New/Dispose 就位');
end;

// ═══ 8.6 GetMem/FreeMem：无类型指针 + 显式字节数
procedure ShowGetMem;
var
  p: Pointer;
  pi: PInteger;
  i: Integer;
begin
  GetMem(p, 4 * SizeOf(Integer));          // 按字节要内存
  pi := PInteger(p);                       // 转成有类型视图
  for i := 0 to 3 do
    pi[i] := i * 10;                       // 默认不可 pi+i（除非 POINTERMATH，见 8.7）
  Assert(pi[2] = 20);
  FreeMem(p);                              // 与 GetMem 字节数配对
  WriteLn('GetMem/FreeMem：手动字节数管理');
end;

// ═══ 8.7 {$POINTERMATH}：指针算术开关
procedure ShowPointerMath;
var
  arr: array[0..4] of Integer = (10, 20, 30, 40, 50);
  p: PInteger;
begin
  p := @arr[0];
  Assert(p[3] = 40, '下标式访问一直可用');
  {$POINTERMATH ON}
  Assert((p + 3)^ = 40, 'POINTERMATH ON：p+3 按元素宽度前进（不是字节）');
  {$POINTERMATH OFF}
  // 关掉后 p+3 编译错误——C 程序员最想念的写法要显式开开关
  WriteLn('指针算术：POINTERMATH 下 (p+3)^=', 40);
end;

// ═══ 8.8 过程类型与回调
function Asc(a, b: Integer): Integer;
begin Result := a - b; end;

function Desc(a, b: Integer): Integer;
begin Result := b - a; end;

procedure BubbleSort(var arr: array of Integer; cmp: TComparator);
var
  i, j, t: Integer;
begin
  for i := High(arr) - 1 downto 0 do
    for j := 0 to i do
      if cmp(arr[j], arr[j + 1]) > 0 then
      begin
        t := arr[j]; arr[j] := arr[j + 1]; arr[j + 1] := t;
      end;
end;

procedure ShowCallbacks;
var
  a: array[0..3] of Integer = (3, 1, 4, 2);
  i: Integer;
begin
  BubbleSort(a, @Asc);                     // @：取函数地址传入（objfpc 要求 @）
  Assert((a[0] = 1) and (a[3] = 4));
  BubbleSort(a, @Desc);
  Assert((a[0] = 4) and (a[3] = 1));
  Write('回调排序：降序 =');
  for i := 0 to 3 do Write(' ', a[i]);
  WriteLn;
end;

// ═══ 8.9 调 DLL：external + cdecl/stdcall + varargs
// varargs：cdecl 变参函数的声明方式——调用时直接跟参数，不打包数组
function printf(fmt: PAnsiChar): Integer; cdecl; varargs; external 'msvcrt';

procedure ShowExternalCall;
begin
  printf('printf from msvcrt.dll: %d + %d = %d' + #10, 1, 2, 3);
  WriteLn('external 声明直调 C 运行库成功（cdecl + varargs）');
end;

begin
  WriteLn('═══ 8.1 record 基础与 with');
  ShowRecordBasics;
  WriteLn('═══ 8.2 packed 布局');
  ShowPacked;
  WriteLn('═══ 8.3 variant record');
  ShowVariantRecord;
  WriteLn('═══ 8.4 record 方法与运算符');
  ShowRecordMethods;
  WriteLn('═══ 8.5 指针基础');
  ShowPointers;
  WriteLn('═══ 8.6 GetMem/FreeMem');
  ShowGetMem;
  WriteLn('═══ 8.7 指针算术');
  ShowPointerMath;
  WriteLn('═══ 8.8 过程类型与回调');
  ShowCallbacks;
  WriteLn('═══ 8.9 调 DLL');
  ShowExternalCall;
  WriteLn;
  WriteLn('==== 08 结束 ====');
end.
