# 05 · 过程与函数

## 1. 两类子程序：procedure 与 function

```pascal
procedure Greet(const name: string);        // 无返回值
begin
  WriteLn('你好，', name, '！');
end;

function Add(a, b: Integer): Integer;       // 有返回值：: 类型
begin
  Result := a + b;                          // Result 是编译器内置的"返回值变量"
end;
```

- 函数体内 `Result` 自动声明、可直接读（递归时读的是本次未赋值前的垃圾值，注意）。
  老教材写 `Add := a + b`（函数名赋值）也合法，两者等价；`Result` 更易读。
- `Exit` 提前返回；**`Exit(值)`** 一站式"赋值+返回"：

```pascal
function Factorial(n: Integer): Int64;
begin
  if n <= 1 then Exit(1);           // 等价 Result := 1; Exit;
  Result := n * Factorial(n - 1);
end;
```

- 调用无参过程**不用括号**：`Greet('张三');`、`Bump;`——括号是可选的。

## 2. 参数修饰：五种，各有使命

这是 Pascal 参数传递的精华——**调用者与被调者的契约写在签名上**：

```pascal
procedure ByValue(n: Integer);         // ① 值传递：拷贝一份进去，改了白改
procedure ByConst(const s: string);    // ② 只读引用优化：不许改，避免拷贝
procedure ByVar(var n: Integer);      // ③ 双向引用：C 的 int*，改的是实参本体
procedure ByOut(out r: string);       // ④ 只出不进：进入时实参先被清空
procedure ByConstRef(constref r: TBigRecord);  // ⑤ 只读引用：不拷贝也不许改
```

实测断言（示例 5.2 节）：

```pascal
x := 10;
ByValue(x);  Assert(x = 10);      // 副本被改，本体无损
ByVar(x);    Assert(x = 20);      // 本体被改
s := '旧值';
ByOut(s);    Assert(s = 'out 参数写入的值');   // out 进入即清空，"旧值"根本看不见
```

选型口诀：

| 场景 | 用 |
|---|---|
| 小值（整数、实数、布尔），函数内部只读 | 省略修饰（值传递） |
| 任何大小，函数只读 | `const`（字符串/数组/记录尤其重要——零拷贝） |
| 需要改调用者的变量（输出结果） | `var`（双向）或 `out`（纯输出） |
| 大记录只读，又想零拷贝 | `constref` |

`out` 与 `var` 的机器码一样，差别在**契约与清理**：`out` 声明"我只负责写入"，进入时
编译器先把实参清成空值——适合"函数内构造、调用者不关心旧值"的场景（读代码的人一看
签名就懂）。

## 3. 默认参数与重载

```pascal
function Power(base: Integer; exp: Integer = 2): Integer;  // 默认值：编译期常量
...
Assert(Power(5) = 25);          // exp 取默认 2
Assert(Power(2, 10) = 1024);

procedure Log(msg: string); overload;               // 重载：同名不同参
procedure Log(msg: string; level: Integer); overload;
```

- 默认参数**只能从右端开始连续**出现（同 C++）。
- 重载必须标 `overload` 指令；解析按**参数个数与类型**匹配，两义性调用直接编译错误
  （比如 `Log('x', 3.0)` 找不到 Integer 的匹配——不会静默截断）。
- 返回类型不同、参数相同**不构成**重载。

## 4. 开放数组：array of T

```pascal
function Sum(values: array of Integer): Integer;   // 接纳任意长度
var v: Integer;
begin
  Result := 0;
  for v in values do Result += v;
  Assert(Low(values) = 0);     // 开放数组下标恒为 0..High，与外界声明的下标无关
end;

Sum(arr);          // 动态数组
Sum([10, 20]);     // 字面量构造器
```

- 形参 `array of Integer` 是**开放数组**：实参可以是任意长度的动态/静态数组或字面量。
- 形参内 `Low` 恒 0、`High` 恒 `Length-1`——哪怕实参是 `array[1..7]`。
- 传大数组时配 `const`（`const values: array of Integer`）避免拷贝。

> 坑（实测）：`Sum([1..5])` 编译报 `Got "Set Of Byte", expected "{Open} Array Of LongInt"`——
> **`[1..5]` 是集合构造器不是数组**！方括号在 Pascal 里首先是集合语义（`[a..b]`、`[1,3,5]`
> 都是 set）。老教程"子界传参给开放数组"的写法在 objfpc 不成立。

## 5. array of const：万能参数

`Format('%d-%s', [42, 'x'])` 里那个什么都能塞的方括号，底层是 **array of const**——
元素其实是 `TVarRec` 记录（带类型标签的变体记录）：

```pascal
procedure PrintAll(args: array of const);
var i: Integer;
begin
  for i := 0 to High(args) do
    case args[i].VType of
      vtInteger:    Write(' 整数(', args[i].VInteger, ')');
      vtAnsiString: Write(' 字符串(', AnsiString(args[i].VAnsiString), ')');
      vtExtended:   Write(' 实数(', args[i].VExtended^:0:1, ')');
      vtBoolean:    Write(' 布尔(', args[i].VBoolean, ')');
    else
      Write(' 其他类型');
    end;
end;

PrintAll([42, 3.5, True, '字符串']);
```

- `{$H+}` 下字符串字面量进 `TVarRec` 是 **`vtAnsiString`**（不是 `vtString`——那是
  ShortString 时代的老标签；也不是 `vtPChar`）。
- `VExtended^` 要解引用——`VExtended` 是指针。这仨细节是初学者写万能参数时最常撞的墙。
- 实战里你极少手写 TVarRec——但 `Format`/`WriteLn` 之外需要"可变个数异质参数"时，
  这是唯一的正路（Pascal 没有 C 的可变参数表）。

## 6. 嵌套过程：看得见外层的闭包雏形

```pascal
procedure OuterCounter;
var count: Integer;
  procedure Bump;
  begin
    Inc(count);              // 直接改外层的局部变量
  end;
begin
  count := 0;
  Bump; Bump; Bump;
  Assert(count = 3);
end;
```

过程可以套过程，内层**直接读写外层局部变量**（编译器用静态链实现）——相当于免费拿到了
"闭包捕获"。用它把大过程切成小步骤而不用传一堆参数；代价是内层不能离开外层单独复用。

## 7. 前向声明：互相递归

Pascal 先声明后使用，两个互相调用的过程必然有一个"还没声明就用了"——`forward` 解决：

```pascal
procedure OddCheck(n: Integer); forward;    // 只报名字，实现在后

procedure EvenCheck(n: Integer);
begin
  if n = 0 then WriteLn('偶数') else OddCheck(n - 1);
end;

procedure OddCheck(n: Integer);             // 真正的实现（签名不得再写参数默认值）
begin
  if n = 0 then WriteLn('奇数') else EvenCheck(n - 1);
end;
```

## 8. 递归

```pascal
Assert(Factorial(10) = 3628800);
Assert(Fib(30) = 832040);
```

栈上每层一帧，FPC 默认栈 16 MB（Win64）——深递归前心里有数；`Fib` 的朴素双递归是
O(1.6ⁿ)，n=30 已是百万级调用，教学演示刚好，实战要记忆化（14 章泛型字典正好用上）。

## 9. 示例与验证

本章示例 `examples/05_procedures`：五种参数修饰实测、默认参数/重载、开放数组与
TVarRec、嵌套过程、forward 互递归、阶乘/斐波那契。

```powershell
pwsh -File build.ps1 -Example 05_procedures
```

## 10. 坑位清单（实测）

1. `[1..5]` 是**集合**不是数组——传给开放数组参数直接编译错误；数组字面量要写全
   `[1,2,3,4,5]`。
2. `out` 参数进入时被清空——依赖实参旧值的逻辑必须改 `var`。
3. 默认参数必须从右端连续；重载解析有二义性时编译器直接报错（不会静默选一个）。
4. `TVarRec` 的字符串标签是 `vtAnsiString`（`{$H+}` 下），老资料的 `vtString` 查不到。
5. 嵌套过程拿不到"外层过程当值传出去"（不是真闭包）——想存回调只能用第 8 章的过程类型。
6. 函数名赋值（`Add := x`）与 `Result` 并存时，读返回值统一用 `Result`——混用易埋错。

---
上一章：[04 运算符与控制流](04-control.md) ｜ 下一章：[06 数组与集合](06-arrays.md) ｜ 返回：[README](../README.md)
