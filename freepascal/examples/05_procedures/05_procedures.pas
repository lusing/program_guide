{$mode objfpc}{$codepage utf8}{$H+}
program procedures_demo;
{ 05 · 过程与函数：参数修饰 const/var/out/constref、默认参数、开放数组、重载、嵌套、递归。
  正文见 docs/05-procedures.md。 }
uses
  {$IFDEF UNIX}cwstring,{$ENDIF}   // ★ Unix：必须是 uses 第一个——否则 WriteLn 中文字面量全变 ?（见 02 章 2.3）
  SysUtils;

// ═══ 5.1 procedure 与 function：Result 变量 vs 函数名赋值
function Add(a, b: Integer): Integer;
begin
  Result := a + b;                 // objfpc/delphi 模式才有 Result（TP 老写法：Add := a + b）
end;

procedure Greet(const name: string);
begin
  WriteLn('你好，', name, '！');
end;

// ═══ 5.2 参数修饰：值传递 / const / var / out / constref
procedure ParamModes;
var
  x: Integer = 10;
  s: string;

  procedure ByValue(n: Integer);      // 值传递：形参是副本
  begin
    n := 999;
  end;

  procedure ByVar(var n: Integer);    // var：双向引用传递（C 的 &）
  begin
    n := n * 2;
  end;

  procedure ByOut(out r: string);     // out：只出不进——进入时先被清空
  begin
    r := 'out 参数写入的值';
  end;

begin
  ByValue(x);   Assert(x = 10, '值传递不影响实参');
  ByVar(x);     Assert(x = 20, 'var 传引用，改的是实参');
  s := '旧值';
  ByOut(s);
  Assert(s = 'out 参数写入的值', 'out 参数进入时已清空，旧值不可见');
  WriteLn('参数修饰实测：x=', x, ' s=', s);
  // constref：只读引用（大记录/长字符串避免拷贝又保证不被改）——正文 5.2 详述
end;

// ═══ 5.3 默认参数与重载
function Power(base: Integer; exp: Integer = 2): Integer;   // 默认值必须是编译期常量
var
  i: Integer;
begin
  Result := 1;
  for i := 1 to exp do
    Result *= base;
end;

procedure Log(msg: string); overload;
begin
  WriteLn('[log] ', msg);
end;

procedure Log(msg: string; level: Integer); overload;       // 重载靠参数列表区分
begin
  WriteLn('[log L', level, '] ', msg);
end;

// ═══ 5.4 开放数组：array of T 形参接纳任意长度的动态/静态数组
function Sum(values: array of Integer): Integer;
var
  v: Integer;
begin
  Result := 0;
  for v in values do
    Result += v;
  Assert(Low(values) = 0, '开放数组下标恒从 0 开始（与外界声明无关）');
end;

// array of const：万能参数（Format 的底层机制），元素是 TVarRec 记录
procedure PrintAll(args: array of const);
var
  i: Integer;
begin
  Write('  万能参数：');
  for i := 0 to High(args) do
    case args[i].VType of
      vtInteger:    Write(' 整数(', args[i].VInteger, ')');
      vtAnsiString: Write(' 字符串(', AnsiString(args[i].VAnsiString), ')');
      vtPChar:      Write(' PChar(', StrPas(args[i].VPChar), ')');
      vtExtended:   Write(' 实数(', args[i].VExtended^:0:1, ')');
      vtBoolean:    Write(' 布尔(', args[i].VBoolean, ')');
    else
      Write(' 其他类型(vt=', args[i].VType, ')');
    end;
  WriteLn;
end;

// ═══ 5.5 嵌套过程：内层看得见外层的局部变量（闭包的雏形）
procedure OuterCounter;
var
  count: Integer;

  procedure Bump;
  begin
    Inc(count);                   // 直接改外层局部变量——嵌套过程独有
  end;

begin
  count := 0;
  Bump; Bump; Bump;
  Assert(count = 3);
  WriteLn('嵌套过程改外层变量：count=', count);
end;

// ═══ 5.6 前向声明：互相递归时先报名字
procedure OddCheck(n: Integer); forward;      // 声明在前，实现在后

procedure EvenCheck(n: Integer);
begin
  if n = 0 then WriteLn('  ', n, ' 是偶数')
  else OddCheck(n - 1);
end;

procedure OddCheck(n: Integer);
begin
  if n = 0 then WriteLn('  ', n, ' 是奇数')
  else EvenCheck(n - 1);
end;

// ═══ 5.7 递归：阶乘与斐波那契
function Factorial(n: Integer): Int64;
begin
  if n <= 1 then Exit(1);         // Exit(值) = 赋值 + 提前返回
  Result := n * Factorial(n - 1);
end;

function Fib(n: Integer): Int64;
begin
  if n < 2 then Exit(n);
  Result := Fib(n - 1) + Fib(n - 2);
end;

var
  arr: array of Integer;
begin
  WriteLn('═══ 5.1 procedure 与 function');
  Greet('Object Pascal');
  Assert(Add(2, 3) = 5);

  WriteLn('═══ 5.2 参数修饰');
  ParamModes;

  WriteLn('═══ 5.3 默认参数与重载');
  Assert(Power(5) = 25, '默认参数 exp=2');
  Assert(Power(2, 10) = 1024);
  Log('默认重载');
  Log('带级别重载', 3);

  WriteLn('═══ 5.4 开放数组与 array of const');
  arr := [1, 2, 3, 4, 5];          // FPC 3.2.2 支持动态数组字面量（Delphi 风格）
  Assert(Sum(arr) = 15);
  Assert(Sum([10, 20]) = 30, '也能直接传字面量');
  // 坑（实测）：[1..5] 是"集合构造器"不是数组——传给 array of Integer 参数会报
  // "Got Set Of Byte, expected Open Array"；老教程"子界传参"的说法在 objfpc 不成立
  PrintAll([42, 3.5, True, '字符串']);

  WriteLn('═══ 5.5 嵌套过程');
  OuterCounter;

  WriteLn('═══ 5.6 前向声明（互递归）');
  EvenCheck(10);
  OddCheck(7);

  WriteLn('═══ 5.7 递归');
  Assert(Factorial(10) = 3628800);
  Assert(Fib(30) = 832040);
  WriteLn('10! = ', Factorial(10), '  Fib(30) = ', Fib(30));

  WriteLn;
  WriteLn('==== 05 结束 ====');
end.
