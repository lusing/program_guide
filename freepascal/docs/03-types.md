# 03 · 类型与变量

## 1. 强类型的哲学

Pascal 是比 C 更严格的静态强类型语言：整数和实数可以隐式升格，但**窄化必须显式**、
越界默认视为编程错误（检查通道下直接运行时崩溃）。这套"啰嗦"换来的是：大量 C 里的
未定义行为（溢出、越界、截断）在 Pascal 里变成**立刻暴露的 Range/Overflow check error**。

先看全部实测尺寸（FPC 3.2.2，x86_64-win64，与 32 位 Delphi 对照）：

## 2. 整型家族与尺寸表

```pascal
procedure ShowIntSizes;
begin
  WriteLn('ShortInt      ', SizeOf(ShortInt):2, '  ', Low(ShortInt), '..', High(ShortInt));
  WriteLn('Integer       ', SizeOf(Integer):2, '  ', Low(Integer), '..', High(Integer));
  ...
  Assert(SizeOf(Integer) = 4, 'Integer 在 16/32/64 位平台上都恒为 32 位');
  Assert(SizeOf(NativeInt) = 8, 'NativeInt 在 win64 上是 8 字节');
end;
```

| 类型 | 字节 | 范围 | 备注 |
|---|---|---|---|
| ShortInt / Byte | 1 | -128..127 / 0..255 | 有符号/无符号各一 |
| SmallInt / Word | 2 | -32768..32767 / 0..65535 | C 的 short/unsigned short |
| **Integer / Cardinal** | **4** | ±21 亿 / 0..42 亿 | **Integer 恒为 32 位**（16/32/64 位平台皆然） |
| Int64 / QWord | 8 | ±9.2e18 / 0..1.8e19 | 64 位 |
| NativeInt / NativeUInt | 平台 | 跟随指针宽度 | win64 = 8；需要"平台宽度整数"时用它 |

三个容易踩的认知差（尤其从 C/Java 过来）：

1. **`Integer` 不随平台变宽**。C 程序员假设 `int` 迟早变 64 位、Java 程序员知道 `int` 恒 32——
   Pascal 站 Java 这边。要平台宽度整数用 `NativeInt`/`PtrInt`。
2. `MaxInt = High(Integer) = 2147483647`——记住这个数，数组大小、循环边界都常和它打交道。
3. 无符号与有符号混算**不隐式转换**（编译器直接报错），要么显式转换要么统一类型——
   这比 C 的"无声提升"安全得多。

## 3. 实型：Single、Double、Extended

| 类型 | 字节（win64） | 有效数字 | 备注 |
|---|---|---|---|
| Single | 4 | ~7 位 | |
| Double | 8 | ~15 位 | 默认选择 |
| **Extended** | **8** | ~15 位 | **win64 上 Extended 就是 Double**（x86 Delphi 32 位是 10 字节 80 位扩展精度） |

```pascal
a := 0.1; b := 0.2;
Assert(Abs((a + b) - 0.3) < 1e-15, '浮点比较必须用容差，禁止用 =');
```

- 浮点相等比较**永远用容差**（`Abs(x - y) < eps`），这是所有语言的通病，Pascal 不会替你兜底。
- 精度截断的可见证据：`c := a/b`（Double）与 `s := a/b`（Single）转回 Double 后必不相等——
  Single 存不下的位数被物理丢弃。

> 坑（实测）：写 `c := 1.0/3.0; s := 1.0/3.0;` 时两个**常量表达式**被编译器折叠成同一个
> 常量，"截断损耗"根本没发生，断言 `c <> Double(s)` 反而失败。要演示运行期舍入差异，
> 得用**变量**做除法（示例 3.2 节就是这么改的）。

## 4. 布尔四兄弟

```pascal
WriteLn('Boolean=', SizeOf(Boolean), ' ByteBool=', SizeOf(ByteBool), ...);  // 1/1/2/4
Assert(Ord(True) = 1);           // Boolean 的 False=0、True=1，恒定
WriteLn(Ord(ByteBool(255)));      // 255——ByteBool 的"真"是任意非零
```

| 类型 | 字节 | True 的存储 |
|---|---|---|
| Boolean | 1 | 恒为 1 |
| ByteBool / WordBool / LongBool | 1 / 2 / 4 | 任意非零（-1 惯例） |

日常只用 `Boolean`。后三个为对接 C/Win32 API 而生（Windows 的 BOOL 是 4 字节任意非零），
在 08 章调 DLL 时会再遇到它们。

## 5. 枚举：自带编号的类型

```pascal
type
  TSuit = (Club, Diamond, Heart, Spade);            // 默认 0..3
  TLevel = (Beginner = 1, Skilled = 5, Master = 10); // 显式编号，可不连续

suit := Heart;
Succ(suit) = Spade;                                  // 后继/前驱
Inc(suit);                                           // 序数 +1
for suit in TSuit do ...                             // 枚举可 for-in（Low..High）
```

枚举是**序数类型**：有 `Ord`（序数）、`Succ`/`Pred`（后继/前驱）、`Low`/`High`，
可作 `case` 标签、可作数组下标、可进 `set`。比 C 的 enum 多了类型检查：
`TSuit` 和 `TLevel` 之间赋值直接编译错误，不靠注释自律。

> 坑（实测，本教程示例初版亲历）：**枚举成员不要叫 `Low`/`High`**（或其他内建标识符）。
> 写了 `TLevel = (Low = 1, ...)` 之后，全程序所有 `Low(Integer)`/`High(arr)` 都解析成
> "枚举常量后跟左括号"，报 `")" expected but "(" found`——错误位置在**使用处**，
> 离真正的肇事处（类型声明）可能隔着几百行，极难排查。

## 6. 子界：编译器帮你守值域

```pascal
type
  TDigit = 0..9;        // SizeOf = 1（值域小，存储自动收缩）
  TBigDigit = 0..300;   // SizeOf = 2（一个字节装不下 300）
  TMonth = 1..12;
var
  dig: TDigit;
begin
  dig := 11;            // 检查通道（-Cr）：运行时 Range check error；发布通道：静默通过
```

子界继承基类型的运算，只是加了值域约束。**存储按值域自动收缩**（0..9 只要 1 字节）——
`SizeOf(TDigit) = 1`、`SizeOf(TBigDigit) = 2`，写紧凑结构时能省内存。

值域检查由 `-Cr` 编译开关控制：本教程的**检查通道**开、**发布通道**关。所以"越界赋值"
这种 bug 在双通道验证下必然现形——发布通道看输出"正常"，检查通道当场崩溃，崩溃即线索。

## 7. 类型转换：三条不同的路

```pascal
i := 100;
x := i;                    // ① 隐式拓宽：整数→实数，安全，编译器允许
n := Trunc(3.87);          // ② 显式窄化：必须写出来
n := Round(3.87);          // Round 是"银行家舍入"：Round(3.5)=4 但 Round(2.5)=2！
IntToStr(42); StrToInt('-7');   // ③ 字符串互转：SysUtils 家族，失败抛 EConvertError
Val('123', n, code);            // 老派三件：不抛异常，code=0 成功、否则是出错位置
```

三件事别混：

| 路 | 形式 | 失败时 |
|---|---|---|
| 隐式拓宽 | `x := i` | 不存在失败 |
| 显式窄化/硬转 | `Trunc`、`Round`、`Integer(...)`、`Char(...)` | 截断/越界靠检查通道暴露 |
| 字符串互转 | `StrToInt`（抛异常）/ `Val`（返回码） | 按需选 |

特别记两条：**`Trunc` 向零截断**（`Trunc(-3.87) = -3`，不是 -4）；**`Round` 是银行家舍入**
（四舍六入五取偶：`Round(2.5)=2`、`Round(3.5)=4`）——和 C 的 `round()` 行为不同。

## 8. 常量与类型化常量

```pascal
const
  Greeting: string = '你好';   // 类型化常量：有地址有初值，过程内即"静态变量"
  MaxRetry = 3;                // 真常量：编译期折叠，无地址
  Counter: Integer = 100;      // 类型化常量（默认 {$J-} 不可写；{$J+} 下可改，即 C 的 static）
```

- **真常量**（无类型）：`= 3`、`= '文本'` 编译期直接折叠进指令。
- **类型化常量**（`: 类型 = 值`）：进数据段，有地址。配合 `{$J+}` 就是过程内的静态变量
  （保留上次调用的值）——本教程示例保持默认 `{$J-}`，把它当"带初值的常量"用。

> 坑（实测）：无类型的字符串常量 `Greeting = '你好'` 与 02 章的字面量同坑——放进表达式
> 会被重新定型（`Length` 按字符算 2 而不是按字节算 6）。要按字节语义用，声明成
> **类型化常量** `Greeting: string = '你好'`。第 7 章统一解释机理。

## 9. 示例与验证

本章示例 `examples/03_types`：尺寸表全打印 + 断言、浮点容差、布尔家族、枚举子界、
三种转换、两种常量。把示例里 `dig := 11;` 的注释解开再跑一次，亲眼看检查通道崩溃、
发布通道装死——这是理解"双通道"价值最直接的实验。

```powershell
pwsh -File build.ps1 -Example 03_types
```

## 10. 坑位清单（实测）

1. 枚举成员叫 `Low`/`High` → 全程序 `Low(...)`/`High(...)` 报 `")" expected but "(" found`，
   错误位置离肇事处极远。
2. 常量表达式 `1.0/3.0` 被编译器折叠，Single/Double 的"截断损耗"不会发生——演示舍入
   必须用变量做运算。
3. `Extended` 在 win64 是 8 字节（=Double），x86 32 位 Delphi 资料里的"10 字节 80 位"
   说法在此平台不成立。
4. `Round` 是银行家舍入（0.5 取偶），不是四舍五入。
5. 无类型字符串常量/字面量进表达式被重新定型，`Length` 按字符算——要字节语义先入
   `string` 变量或类型化常量。
6. 子界越界只在检查通道（`-Cr`）崩溃，发布通道静默——别只用 `-O2` 验证。

---
上一章：[02 第一个程序](02-hello.md) ｜ 下一章：[04 运算符与控制流](04-control.md) ｜ 返回：[README](../README.md)
