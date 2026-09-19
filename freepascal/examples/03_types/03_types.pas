{$mode objfpc}{$codepage utf8}{$H+}
program types_demo;
{ 03 · 类型与变量：整型尺寸表、实型与精度、布尔家族、枚举与子界、类型转换。
  正文见 docs/03-types.md。 }
uses SysUtils;

type
  // ═══ 3.4 枚举：默认从 0 编号，可用 = 显式指定序数
  // 坑（实测）：成员别叫 Low/High——会遮蔽内建函数 Low()/High()，
  // 之后所有 Low(Integer)/High(Integer) 都报 ") expected but ( found"
  TSuit = (Club, Diamond, Heart, Spade);
  TLevel = (Beginner = 1, Skilled = 5, Master = 10);   // 显式编号可以不连续
  // ═══ 3.4 子界：值域受限的整型/枚举切片，编译器按值域收缩存储
  TDigit = 0..9;
  TBigDigit = 0..300;                          // 0..255 一个字节装不下，升为 Word
  TMonth = 1..12;

var
  // 演示用的全局变量只在个别小节用到；正文建议过程内声明（5 章展开作用域）
  i: Integer;

// ═══ 3.1 整型家族与尺寸表（win64 x86_64 实测值）
procedure ShowIntSizes;
begin
  WriteLn('类型        字节  范围');
  WriteLn('ShortInt      ', SizeOf(ShortInt):2, '  ', Low(ShortInt), '..', High(ShortInt));
  WriteLn('Byte          ', SizeOf(Byte):2, '  ', Low(Byte), '..', High(Byte));
  WriteLn('SmallInt      ', SizeOf(SmallInt):2, '  ', Low(SmallInt), '..', High(SmallInt));
  WriteLn('Word          ', SizeOf(Word):2, '  ', Low(Word), '..', High(Word));
  WriteLn('Integer       ', SizeOf(Integer):2, '  ', Low(Integer), '..', High(Integer));
  WriteLn('Cardinal      ', SizeOf(Cardinal):2, '  ', Low(Cardinal), '..', High(Cardinal));
  WriteLn('Int64         ', SizeOf(Int64):2, '  ', Low(Int64), '..', High(Int64));
  WriteLn('QWord         ', SizeOf(QWord):2, '  0..', High(QWord));
  WriteLn('NativeInt     ', SizeOf(NativeInt):2, '  跟随平台指针宽度');
  // 三个教学要点（正文 3.1 详述）：
  Assert(SizeOf(Integer) = 4, 'Integer 在 16/32/64 位平台上都恒为 32 位');
  Assert(SizeOf(NativeInt) = 8, 'NativeInt 在 win64 上是 8 字节——需要"平台宽度整数"时用它');
  Assert(High(Integer) = MaxInt);
end;

// ═══ 3.2 实型与精度：浮点没有十进制意义上的精确
procedure ShowRealTypes;
var
  a, b, c: Double;
  s: Single;
begin
  WriteLn('Single  ', SizeOf(Single), ' 字节，约 7 位有效数字');
  WriteLn('Double  ', SizeOf(Double), ' 字节，约 15 位有效数字');
  WriteLn('Extended ', SizeOf(Extended), ' 字节（win64 上 Extended = Double，Delphi 32 位是 10 字节）');
  Assert(SizeOf(Extended) = SizeOf(Double), 'win64 实测：Extended 精简为 Double');

  a := 0.1; b := 0.2;
  WriteLn('0.1 + 0.2 = ', a + b);              // 0.30000000000000004 之类
  Assert(Abs((a + b) - 0.3) < 1e-15, '浮点比较必须用容差，禁止用 =');
  // 坑（实测）：c := 1.0/3.0; s := 1.0/3.0 两个常量表达式会被编译器折叠成
  // 同一常量，断言 c <> Double(s) 反而失败——用变量做运行期除法才有真实舍入差
  a := 1.0; b := 3.0;
  c := a / b;                                  // 运行期除法：Double 结果
  s := a / b;                                  // 存进 Single：截断到约 7 位
  WriteLn('1/3: Double=', c, '  Single=', s:0:8);
  Assert(c <> Double(s), 'Single 存不下的精度被截断，转回 Double 必不相等');
end;

// ═══ 3.3 布尔家族：Boolean 是 1 字节枚举，其余三兄弟为兼容 C/WinAPI 而生
procedure ShowBooleans;
begin
  WriteLn('Boolean=', SizeOf(Boolean), ' ByteBool=', SizeOf(ByteBool),
    ' WordBool=', SizeOf(WordBool), ' LongBool=', SizeOf(LongBool));
  WriteLn('Ord(True)=', Ord(True), '  Ord(False)=', Ord(False));
  // 坑：ByteBool 的 True 序数是 1..255 任意非零——Ord(ByteBool(255)) 是 255
  WriteLn('Ord(ByteBool(255))=', Ord(ByteBool(255)));
  Assert(Ord(True) = 1, 'Boolean 的 True 序数恒为 1');
end;

// ═══ 3.4 枚举与子界：序数类型的世界
procedure ShowEnums;
var
  lv: TLevel;
  suit: TSuit;
  dig: TDigit;
begin
  WriteLn('TSuit: ', Ord(Club), ',', Ord(Diamond), ',', Ord(Heart), ',', Ord(Spade));
  Assert(Ord(Spade) = 3);
  suit := Heart;
  WriteLn('suit 的下一个：', Succ(suit) = Spade, '  上一个：', Pred(suit) = Diamond);
  Inc(suit);                                    // Inc/Dec 直接改序数
  Assert(suit = Spade);

  lv := Skilled;
  WriteLn('TLevel: Low=', Ord(Low(TLevel)), ' High=', Ord(High(TLevel)),
    '（显式编号 1/5/10，Ord(Skilled)=', Ord(lv), '）');
  Assert(Ord(lv) = 5);

  WriteLn('TDigit 尺寸=', SizeOf(TDigit), '（0..9 压进 1 字节）',
    '  TBigDigit 尺寸=', SizeOf(TBigDigit), '（0..300 需要 2 字节）');
  Assert(SizeOf(TDigit) = 1);
  dig := 7;                                     // 子界变量赋值受检查通道保护
  Assert(dig in [0..9]);
  // dig := 11;  // 打开这行：check 通道（-Cr）运行时报 Range check error；release 不报——
                // 这就是"检查通道"存在的意义（正文 3.4）
end;

// ═══ 3.5 类型转换：隐式提升、显式硬转、字符串互转三回事
procedure ShowConversions;
var
  n: Integer;
  x: Double;
  code: Integer;
begin
  i := 100;
  x := i;                                       // 整数 → 实数：隐式安全提升
  WriteLn('Integer → Double：', x:0:1);
  n := Trunc(3.87);                             // 实数 → 整数：必须显式，且 Trunc 向零截断
  WriteLn('Trunc(3.87)=', n, '  Round(3.87)=', Round(3.87));
  Assert(Trunc(-3.87) = -3, 'Trunc 向零截断，不是向下取整');
  Assert(Round(3.5) = 4, 'Round 银行家舍入：Round(3.5)=4，但 Round(2.5)=2');
  Assert(Round(2.5) = 2);

  WriteLn('IntToStr(42)=', IntToStr(42), '  StrToInt(''-7'')=', StrToInt('-7'));
  Val('123', n, code);                          // Val/Str：不抛异常的老派转换
  Assert((n = 123) and (code = 0));
  Val('12x', n, code);
  Assert(code = 3, 'Val 出错时 code=出错位置，n 不保证有效');
end;

// ═══ 3.6 常量与类型化常量：const 表达式 vs 带类型的"静态变量"
procedure ShowConstants;
const
  Greeting: string = '你好';     // 类型化字符串常量：按 string 存 UTF-8 字节（Length=6）
  // 坑（实测）：写 Greeting = '你好'（无类型）时它成了"无类型常量"，放进表达式会被
  // 重新定型，Length 变 2（按字符）——与 02 章字面量同一坑，第 7 章统一展开
  Counter: Integer = 100;        // 类型化常量：初值进数据段，过程内即"静态变量"（默认不可写）
begin
  WriteLn(Greeting, '  类型化常量初值=', Counter);
  Assert(Length(Greeting) = 6);
end;

begin
  WriteLn('═══ 3.1 整型家族与尺寸表');
  ShowIntSizes;
  WriteLn;
  WriteLn('═══ 3.2 实型与精度');
  ShowRealTypes;
  WriteLn;
  WriteLn('═══ 3.3 布尔家族');
  ShowBooleans;
  WriteLn;
  WriteLn('═══ 3.4 枚举与子界');
  ShowEnums;
  WriteLn;
  WriteLn('═══ 3.5 类型转换');
  ShowConversions;
  WriteLn;
  WriteLn('═══ 3.6 常量与类型化常量');
  ShowConstants;
  WriteLn;
  WriteLn('==== 03 结束 ====');
end.
