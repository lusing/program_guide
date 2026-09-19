# 04 · 运算符与控制流

## 1. 运算符：用单词，不用符号

Pascal 的运算符是英文单词——`and`/`or`/`not`/`xor`/`shl`/`shr`/`div`/`mod`——
1970 年的设计哲学：**键盘上没有的符号不该出现在程序里**。对照表：

| C 系写法 | Pascal 写法 | 备注 |
|---|---|---|
| `&&` `||` `!` | `and` `or` `not` | 布尔与按位**同一个词**，由操作数类型决定 |
| `&` `|` `^` `~` | `and` `or` `xor` `not` | 整数按位 |
| `<<` `>>` | `shl` `shr` | |
| `/`（整除） | `div` | **Pascal 的 `/` 永远是实数除** |
| `%` | `mod` | |

**`/` 与 `div` 是两套除法**，这是 Pascal 与 C 的最大差别之一：

```pascal
WriteLn(7 / 2);      // 3.5000000000000E+000 —— Real 结果，即使两个操作数都是整数
WriteLn(7 div 2);    // 3 —— 截断整数商
WriteLn(7 mod 2);    // 1 —— 余数
```

`div`/`mod` 的符号规则（实测断言）：

```pascal
Assert(-7 div 2 = -3);      // 商向零截断
Assert(-7 mod 2 = -1);      // 余数符号跟随被除数
Assert(7 mod -2 = 1);       // 与 C 的 % 完全一致，与数学定义（余数恒正）不同
```

## 2. if / then / else

```pascal
if score >= 90 then
  WriteLn('优秀')
else if score >= 60 then      // else if 链：注意中间的 else if 是两个词
  WriteLn('及格')
else
  WriteLn('不及格');
```

两条铁律：

1. **`else` 前不能有分号**。`if c then 语句; else ...` 是语法错误——分号意味着 if 语句
   已结束，else 成了孤儿。写完 if 记得看一眼 else 前面。
2. **悬垂 else 属于最近的 if**（同 C）：

```pascal
if score > 0 then
  if score > 85 then WriteLn('>85')
  else WriteLn('0<score<=85')     // 这个 else 属于内层 if
else WriteLn('score<=0');         // 这个属于外层
```

嵌套分不清时用 `begin...end` 显式成块——Pascal 没有大括号，`begin/end` 就是块。

## 3. case：比 switch 灵活的分支

```pascal
case score of
  90..100:          WriteLn('A');        // 子界标签
  80..89:           WriteLn('B');
  60, 65, 70..79:   WriteLn('C');        // 列表与子界混用
else                                    // 默认分支（不是 default）
  WriteLn('F');
end;
```

- 标签可以是**常量、子界、逗号列表**——C 的 switch 做不到子界标签。
- 只接受**序数类型**（整数、字符、枚举、布尔）；字符串和实数不行（这是与 C 明显的差异，
  字符串分支用一串 if-else 或第 7 章的技巧）。
- `case` 也是**语句**，末尾 `end;` 必写——Pascal 里 `end` 从不配 begin 才出现（记录、
  单元、类声明同款）。

## 4. while 与 repeat：先判断与后判断

```pascal
n := 1; sum := 0;
while n <= 10 do begin       // 先判断：条件假则一次都不执行
  sum += n; Inc(n);
end;

n := 10;
repeat
  Dec(n);
until n = 0;                 // 后判断：至少执行一次；until 条件为"真"时结束
```

`repeat...until` 是 Pascal 特有：**无条件执行一轮再判断**，且 `until` 的条件为**真**结束
（注意不是"为假继续"——与 do-while 的心理模型相反）。两分支结构体的
`begin/end`：while 需要（多条语句），repeat 自带边界不需要。

## 5. for 与 downto：边界只求值一次

```pascal
total := 0;
for i := 1 to 10 do
  total += i * i;

for i := 10 downto 1 do ...      // downto 倒数
```

与 C 的 for 心智差异（实测断言）：

```pascal
limit := 3;
for i := 1 to limit do begin
  Write(' ', i);
  limit := 100;                  // 坑：改上限不影响循环——边界只在进入时求值一次
end;
Assert(i = 3, '循环变量停在终值，退出后仍可读——但别依赖它');
```

- 循环变量必须是**序数类型**，步长恒为 ±1（要步长 2 用 while 或 `Inc(i, 2)`）。
- `for-in`（下节）遍历集合时更省心。

## 6. for-in：四种遍历对象

```pascal
for s in names do ...            // ① 静态/动态数组
for ch in s do ...               // ② 字符串
for d in digits do ...           // ③ 集合（只迭代存在的元素）
for suit in TSuit do ...         // ④ 枚举类型（Low..High）
```

③值得强调：`set` 的 for-in **跳过不存在的元素**——`digits := [1,3,5]` 迭代 3 次，
天然就是"遍历开关位"的写法。

> 坑（实测）：**字符串字面量与字符串变量的 for-in 行为不同**——
> `for ch in 'ab中文'`（字面量）按**字符**迭代 4 次；先 `s := 'ab中文'` 再 `for ch in s`
> 按**字节**迭代 8 次。机理（UTF-8 字面量在无类型上下文被重新定型）第 7 章统一讲；
> 记住结论：**要按字节处理，先存进 string 变量**。

## 7. Break / Continue / Exit / Halt

```pascal
for i := 1 to 100 do begin
  if i mod 2 = 0 then Continue;      // 跳过本轮剩余
  if i * i > 200 then Break;         // 整个循环提前结束
  Write(' ', i);
end;
```

| 语句 | 作用域 | 用途 |
|---|---|---|
| `Break` / `Continue` | 当前循环 | 与 C 相同 |
| `Exit` | 当前过程/函数 | 提前返回；`Exit(值)` = 赋值 + 返回 |
| `Halt` | 整个程序 | 立刻终止进程（教程示例统一不用，改用正常流程 + 结束标记） |

## 8. 布尔求值策略：默认短路，可开关

先给实测结论（本教程最重要的求值语义）：

```pascal
CallCount := 0;
if (1 > 2) and Positive then ...     // Positive 没被调用！
Assert(CallCount = 0);               // FPC 全部模式默认 {$B-}：短路求值
```

| 编译指令 | 语义 | 说明 |
|---|---|---|
| `{$B-}`（默认） | 短路求值 | 左侧定案则右侧不求值——`if (i >= 0) and (a[i] > 0)` 安全 |
| `{$B+}` | 完全求值 | 两侧都算——某些依赖副作用的场合才需要 |

```pascal
{$B+}
if (1 > 2) and Positive then ...     // Positive 被调用（CallCount = 1）
{$B-}
```

> 坑（实测）：网上常说 Pascal 有 `and then` / `or else` 短路运算符——**FPC 3.2.2 的
> objfpc 模式不认**（实测报 Illegal expression），它们只存在于 MacPas 模式。
> objfpc/delphi 的短路靠默认的 `{$B-}`。示例 4.8 节用计数器函数证明了两种策略的差别。

## 9. 示例与验证

本章示例 `examples/04_control`：运算符断言、悬垂 else、case 子界标签、三种循环、
for-in 四对象、循环控制、`{$B}` 开关实验。

```powershell
pwsh -File build.ps1 -Example 04_control
```

## 10. 坑位清单（实测）

1. `/` 对整数操作数也返回实数——整数除法必须写 `div`（写 `/` 赋回整数变量直接编译错误，
   倒是好排查）。
2. `else` 前的分号是语法错误；悬垂 else 绑定最近的 if。
3. `repeat...until` 的条件为**真**结束（心理模型与 do-while 相反）。
4. for 循环边界只在进入时求值一次；循环变量退出后停在终值（可读但别依赖）。
5. 字符串**字面量**的 for-in 按字符、**变量**按字节——要字节语义先入变量。
6. `and then`/`or else` 在 objfpc 模式非法（仅 MacPas）——短路靠默认 `{$B-}`，
   完全求值用 `{$B+}`。
7. `case` 只接受序数类型——字符串分支老老实实写 if-else 链。

---
上一章：[03 类型与变量](03-types.md) ｜ 下一章：[05 过程与函数](05-procedures.md) ｜ 返回：[README](../README.md)
