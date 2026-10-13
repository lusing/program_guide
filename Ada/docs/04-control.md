# 04 · 控制结构

> 示例：[`examples/ch04_control.adb`](../examples/ch04_control.adb)
> 运行：`./run-all.sh 04`

Ada 的控制结构集合了结构化程序设计的教科书阵容：条件（if/case）、
三种循环（for/while/无限 loop）、出口（exit）、受限的 goto、块结构
（declare）。本章按"表达式 → 语句 → 循环专题 → 跳出与转移 → 块"
的顺序讲，重点放在 Ada 特有的部分：**短路逻辑操作符**、**rem 与 mod
的区别**、**命名循环**、以及**块结构如何收窄作用域**；最后用百鸡问题
把"循环嵌套 + 约束剪枝"讲成一堂小算法课。内容对应张丽芬
《Ada 程序设计导论》§1.6–1.7（表达式和操作符说明、语句）与
刘炳文《程序设计语言 Ada》第五章（含 §5.6 应用举例）。

---

## 04.1 表达式与操作符

表达式由**操作数**和**操作符**组成。操作数可以是直接量、变量、
数组分量、函数调用、属性值（如 `A'First`）。操作符按优先级从低到高：

| 级别 | 操作符 | 备注 |
|------|--------|------|
| 6（最低） | `and` `or` `xor` | 逻辑 |
| 5 | `=` `/=` `<` `<=` `>` `>=` | 关系（返回 Boolean） |
| 4 | `+` `-` `&` | 二目加减、**数组/字符串连接** |
| 3 | `+` `-` | 一目正负 |
| 2 | `*` `/` `mod` `rem` | 乘除类 |
| 1（最高） | `**` `abs` `not` | 乘方、绝对值、非 |

两个细节：

1. `&` 是**连接操作符**，用于字符串与数组拼接——它和加减同级，
   所以 `"Total: " & Integer'Image (N)` 不需要括号。
2. `=` 是判等、`/=` 是不等（不是 `!=`）；成员测试 `in` / `not in`
   是特殊形式：`J in 1 .. 10` 直接测范围，配合第 03 章的子类型
   约束非常好用。

### 短路操作符：and then / or else

Ada 特有的**短路控制形式**。普通 `and`/`or` 的两个操作数**都**求值；
`and then` / `or else` 则按需短路——左侧已能定结论时右侧不求值：

```ada
function Safe_Big_Ratio (X, Y : Float) return Boolean is
begin
   return Y /= 0.0 and then X / Y > 5.0;
   -- 若写成 and：Y = 0 时两个操作数都求值，除零引发异常
end Safe_Big_Ratio;
```

老教材 §1.6 的经典对比：

```ada
X /= 0.0 and  Y / X > 5.0     -- X=0 时右侧照算 → 除零异常
X /= 0.0 and then Y / X > 5.0 -- X=0 时右侧被跳过 → 安全
```

示例验证：

```text
  Safe_Big_Ratio (30.0, 0.0) = FALSE  （除零未发生，右侧被短路）
  Safe_Big_Ratio (30.0, 5.0) = TRUE
```

判空再取值（`P /= null and then P.Value > 0`）、查界再取下标，
都是 `and then` 的主场。`or else` 对偶：`Is_Cached or else Compute (...)`
——缓存命中就不算。**语义上需要短路时必须写短路形式**，普通
`and`/`or` 不承诺求值顺序。

### rem 与 mod：同是取余，负数分家

两个取余操作符，正数上结果相同，负数上按不同定义分家：

- `X rem Y`——**余数**：满足恒等式 `X = (X/Y)*Y + (X rem Y)`，
  余数与**被除数 X 同号**。跟 C 的 `%` 行为一致。
- `X mod Y`——**模**：结果与**除数 Y 同号**，落在 `0 .. Y-1`
  （Y>0 时）。数学上"模 Y 的最小非负代表元"。

示例把 -7..7 中两者不同的值全列了出来：

```ada
Put_Line ("--- 2. rem 与 mod（除数 3） ---");
Put_Line ("     X     X rem 3     X mod 3");
for X in -7 .. 7 loop
   if X rem 3 /= X mod 3 then
      Put ("  ");
      Put (X, Width => 4);
      Put (X rem 3, Width => 10);
      Put (X mod 3, Width => 10);
      Put_Line ("   ← 负数时两者不同");
   end if;
end loop;
Put_Line ("  恒等式：X = (X/Y)*Y + (X rem Y)；mod 结果与除数同号。");
```

输出：

```text
     X     X rem 3     X mod 3
    -7        -1         2   ← 负数时两者不同
    -5        -2         1   ← 负数时两者不同
    ...
```

记住用途分工：**rem 用于"剩下的零头"**（分页后剩余记录数），
**mod 用于环形/周期**（星期几滚动、哈希桶定位——`(i mod N)` 永远
落在 0..N-1，哪怕 i 为负）。

## 04.2 条件语句：if 与 case

### if —— 条件依次判断

```ada
if Score >= 95 then
   Grade := 'A';
elsif Score >= 85 then
   Grade := 'B';
elsif Score >= 75 then
   Grade := 'C';
elsif Score >= 65 then
   Grade := 'D';
else
   Grade := 'F';
end if;
```

要点：拼写是 **`elsif`**（不是 elseif）；条件必须是 Boolean 类型——
整数当真值的 C 写法在 Ada 直接编译错；各分支从上到下**依次**判断，
所以范围条件 `>= 95` 在前才不会吞掉后面的档位。

### case —— 值直接定位

```ada
case Grade is
   when 'A' | 'B' =>
      Put_Line ("  A → 优良");      -- 一个分支可以列多个值
   when 'C' =>
      Put_Line ("  C → 中等");
   when 'D' =>
      Put_Line ("  D → 及格");
   when 'E' =>
      Put_Line ("  E → 未使用");
   when others =>
      Put_Line ("  F → 不及格");
end case;
```

case 的选择对象必须是**离散类型**（整型/枚举，第 03 章）；分支值
必须**覆盖全部可能**——漏了值又没有 `when others` 是编译错误；
`others` 若存在必须放最后。这是 if 与 case 的本质区别：**if 是
顺序测试，case 是完备性受检的多路分支**——新增一个枚举值后，
所有相关 case 会立刻编译报错，逼你补齐处理。这是重构时的安全网。

## 04.3 三种循环

### for —— 离散范围驱动

```ada
Put ("  for 正序 1..5 : ");
for I in 1 .. 5 loop
   Put (I, Width => 0);
   Put (" ");
end loop;

Put ("  for 逆序 reverse : ");
for I in reverse 1 .. 5 loop
   ...
end loop;
```

for 的循环变量 `I` 是**循环的私有对象**：类型由范围给出、
**在循环体内是常量**（赋值即编译错）、循环结束即消失。
范围可以是任何离散类型——枚举也行：

```ada
for C in Color loop ... end loop;   -- 遍历整个枚举
for C in Color'(Green) .. Blue loop -- 限定起点
```

`reverse` 必须写在 `in` 之后、范围之前；`1 .. 5` 写成一个子类型
名也行（`for I in Positive loop` 会转很久——除非那是小范围的
子类型）。

### while —— 条件预检

```ada
declare
   Counter : Integer := 3;
begin
   while Counter > 0 loop
      Put (" T-" & Integer'Image (Counter));
      Counter := Counter - 1;
   end loop;
   Put_Line (" 发射!");
end;
```

条件为假（包括第一次就假）时循环体一次都不执行。

### 无限 loop —— 服务器的心跳

```ada
loop
   ...
   exit when N >= 5;         -- 出口见下节
   N := N + 1;
end loop;
```

无限循环没有内置终止条件，靠 exit/return/异常退出。它不是写错了的
while——**事件驱动服务器**（等输入、等中断）的正规形态就是无限
循环（第 15 章的任务体几乎全是 `loop ... select ... end loop`）。
老教材举的例子是生产者/消费者：两个任务各自 `loop` 读写缓冲区，
满/空时自动挂起——无限循环 + 并发原语，正是 Ada 为实时系统设计的
用法。

## 04.4 循环嵌套与剪枝：百鸡问题

公元五世纪，张丘建《算经》提出"百鸡问题"——**鸡翁一，值钱五；
鸡母一，值钱三；鸡雏三，值钱一。百钱买百鸡，问鸡翁、母、雏各
几何？** 刘炳文 §5.6 用它讲循环嵌套与效率，是全书最漂亮的渐进
重构案例：同一个问题，两版程序，快 1442 倍。

设公鸡 X、母鸡 Y、雏鸡 Z 只，两个约束：

```
X + Y + Z = 100          （百鸡）
5X + 3Y + Z/3 = 100      （百钱，雏鸡三只一钱 → Z 必须整除 3）
```

三个未知数两个方程——不定方程，恰好用穷举。

### 版本 A：三重暴力循环

```ada
for X in 0 .. 100 loop                -- 公鸡数
   for Y in 0 .. 100 loop             -- 母鸡数
      for Z in 0 .. 100 loop          -- 雏鸡数
         Count_Triple := Count_Triple + 1;
         if X + Y + Z = 100
           and then Z mod 3 = 0
           and then 5 * X + 3 * Y + Z / 3 = 100
         then
            Put_Line ("    解：公鸡" & Integer'Image (X)
                      & "  母鸡" & Integer'Image (Y)
                      & "  雏鸡" & Integer'Image (Z));
         end if;
      end loop;
   end loop;
end loop;
```

结构一目了然，但 `101 × 101 × 101 = 1 030 301` 次判定——1993
年的 PC 上"要用较长的时间"（原书语），今天虽秒出，思路却是
反效率的。**顺带一个实测勘误**：原书程序没有 `Z mod 3 = 0`
这条先验，直接 `Z / 3`——截断除法会"造"出伪解，GNAT 实测
多打 4 行（X=3/7/11，Z=77/80/83 不整除 3，却凑出百钱）。
`and then` 短路序（先便宜的计数检查，再贵的钱数检查）也是
同一课：**把最可能失败的便宜条件放最前面**。

### 版本 B：约束传播，砍掉一层循环

两个动作：**等式代换**（Z = 100 − X − Y 白送）与**界收紧**
（百钱至多买 20 只公鸡、33 只母鸡）：

```ada
for X in 0 .. 20 loop                 -- 5X <= 100 → X <= 20
   for Y in 0 .. 33 loop              -- 3Y <= 100 → Y <= 33
      Count_Double := Count_Double + 1;
      declare
         Z : constant Integer := 100 - X - Y;  -- 白送的第三个变量
      begin
         if Z >= 0 and then Z mod 3 = 0
           and then 5 * X + 3 * Y + Z / 3 = 100
         then
            null;                     -- 解已在版本 A 列全，这里只对账
         end if;
      end;
   end loop;
end loop;
```

```text
    解：公鸡 0  母鸡 25  雏鸡 75
    解：公鸡 4  母鸡 18  雏鸡 78
    解：公鸡 8  母鸡 11  雏鸡 81
    解：公鸡 12  母鸡 4  雏鸡 84
  三重循环判定 1030301 次；两重循环仅 714 次（相差约 1442 倍）
```

四个解与《算经》答案完全一致（相邻解公鸡差 4、母鸡差 7、
雏鸡差 3——不定方程的解在等差数列上）。这一课超出语法的
地方在于：**循环边界不是"题目给的 0..100"，是约束推出的更紧
的界**；嵌套层数每少一层，规模除掉一个因子。写完穷举先问
一句"哪些变量能被等式代换、哪些界能被约束收紧"——这是从
循环到算法的分水岭。

## 04.5 exit：四种形态与命名循环

`exit` 显式终止循环，四种合法形态：

```ada
exit;                -- 无条件退出最内层循环
exit when 条件;       -- 条件为真退出最内层
exit 循环名;          -- 退出指定名字的循环
exit 循环名 when 条件;  -- 条件为真退出指定循环
```

后两种需要**命名循环**——标识符写在 loop 前，`end loop` 后重复。
示例是老教材 §1.7 的经典应用：二维网格找零，一步跳出双重循环：

```ada
Search :
for I in M'Range (1) loop
   for J in M'Range (2) loop
      if M (I, J) = 0 then
         Put_Line ("  在 M ("
                   & Integer'Image (I) & ","
                   & Integer'Image (J) & ") 找到 0");
         exit Search;        -- 一步跳出两重循环
      end if;
   end loop;
end loop Search;
```

不用命名循环的话，内层得设旗标、外层得再判一次——两处状态、
两处判断。`exit Search` 一行干净解决。命名循环的 `end loop` 后
**必须**重复名字（漏写编译错，这是故意的：读代码时一眼看到循环
边界）。注意区分**循环名**（`Search :`，普通标识符）与**语句标号**
（`<<Sort>>`，双尖括号，见下节 goto）——两者语法完全不同。

## 04.6 goto：受限的转移

Ada 保留了 goto，但套上三层镣铐：目标必须是 `<<标号>>`；**不能
把控制转移出子程序/包体/任务体**；**不能转移进 if/case/循环或其它
控制结构内部**。即 goto 只能在**同一单元体内**、**向前或向后沿
语句层面**跳。

示例用老教材的气泡分类演示合法用法——"一趟里有交换就从头再来"：

```ada
declare
   A : array (1 .. 6) of Integer := (5, 2, 8, 1, 9, 3);
   Temp : Integer;
begin
   <<Sort>>                        -- 语句标号：双尖括号
   for I in 1 .. 5 loop
      if A (I) > A (I + 1) then
         Temp := A (I);
         A (I) := A (I + 1);
         A (I + 1) := Temp;
         goto Sort;                -- 本趟有交换：从头再来
      end if;
   end loop;
   -- 到达这里时数组已有序
```

输出 `排序结果 :1 2 3 5 8 9`。注意数组说明 `A : array (1 .. 6)
of Integer := ...`——**匿名数组类型**只能出现在对象说明里，这是
Ada 唯一允许"类型定义内联在对象说明中"的场合（正经工程代码更常
先 `type` 后说明，第 06 章细讲）。

老教材自己都注明这个气泡分类"效率非常低"（时间与 N³ 成正比）——
它演示的是 goto 的**深层嵌套逃生**用途。现代 Ada 风格：优先命名
循环 + `exit 名字`；goto 仅在"从深层嵌套向前统一出口"这类场景
比旗标变量更清晰时使用，且永远**向前**跳。

## 04.7 return 与块结构

**return** 结束"包含它的最内层子程序"（或 accept 语句，第 15 章）：

```ada
return;              -- 过程体/块内：不带值
return X + Y;        -- 函数体：必须带与结果类型匹配的值
```

（Ada 2012 起还有扩展 return：`return Result : Vector do ... end return;`，
给结果对象一段初始化代码——遇到再查即可。）

**块结构（declare 块）**——本章最后一个、也是被低估的一个结构。
形式：

```ada
[名字 :]
declare
   局部说明
begin
   语句序列
[exception
   异常处理程序]
end [名字];
```

块的用途是**把说明的作用域压到最小**。示例演示命名块交换：

```ada
declare
   X : Integer := 10;
   Y : Integer := 20;
begin
   Swap_Block :
   declare
      Temp : Integer;             -- Temp 只在本块可见
   begin
      Temp := X;
      X := Y;
      Y := Temp;
   end Swap_Block;
   Put_Line ("  块内交换后：X =" & Integer'Image (X)
             & "，Y =" & Integer'Image (Y));
end;
```

输出 `X = 20，Y = 10`。`Temp` 离开块即不可见，不污染外层名字
空间；进入块分配、退出块回收。块还能带自己的 `exception` 部分——
"这一小段代码的异常就地处理，不影响外层流程"，第 11 章会看到
这是交互输入容错的标准姿势。

从本章起示例里频繁出现的 `declare ... begin ... end;` 不再是摆设：
**每一段演示都是一块**，局部类型（如各段的 `type Age`）互不冲突，
正是块结构在托底。

## 04.8 本章示例的完整输出

```text
=== Ada 控制结构 ===

--- 1. 短路逻辑 ---
  Safe_Big_Ratio (30.0, 0.0) = FALSE  （除零未发生，右侧被短路）
  Safe_Big_Ratio (30.0, 5.0) = TRUE

--- 2. rem 与 mod（除数 3） ---
     X     X rem 3     X mod 3
    -7        -1         2   ← 负数时两者不同
    -5        -2         1   ← 负数时两者不同
    -4        -1         2   ← 负数时两者不同
    -2        -2         1   ← 负数时两者不同
    -1        -1         2   ← 负数时两者不同
  恒等式：X = (X/Y)*Y + (X rem Y)；mod 结果与除数同号。

--- 3. if 分级 ---
  分数 97 → 等级 A
  分数 85 → 等级 B
  分数 76 → 等级 C
  分数 65 → 等级 D
  分数 40 → 等级 F

--- 4. case 语句 ---
  A → 优良
  B → 优良
  C → 中等
  D → 及格
  E → 未使用
  F → 不及格

--- 5. 三种循环 ---
  for 正序 1..5 : 1 2 3 4 5
  for 逆序 reverse : 5 4 3 2 1
  for 的循环变量是隐式常量，循环体内不可赋值；
  枚举类型同样可以做循环范围。
  while 倒计时 : T- 3 T- 2 T- 1 发射!
  loop + exit when :1 2 3 4 5

--- 6. 百鸡问题：三重循环 → 两重循环 ---
    解：公鸡 0  母鸡 25  雏鸡 75
    解：公鸡 4  母鸡 18  雏鸡 78
    解：公鸡 8  母鸡 11  雏鸡 81
    解：公鸡 12  母鸡 4  雏鸡 84
  三重循环判定 1030301 次；两重循环仅 714 次（相差约  1442 倍）

--- 7. 命名循环 ---
  在 M ( 3, 4) 找到 0
  命名循环的 end loop 后必须重复循环名。

--- 8. goto 与气泡分类 ---
  排序结果 :1 2 3 5 8 9
  goto 只能在同一单元体内转移，不得转入 if/case/循环内部。

--- 9. 块结构 ---
  块内交换后：X = 20，Y = 10
  块可以有名字（如 Swap_Block），还可带自己的 exception 部分。
```

## 04.9 小结

| 结构 | 要点 |
|------|------|
| `and then` / `or else` | 短路求值；判空/判界后取值的标准姿势 |
| `rem` / `mod` | 余数与被除数同号 / 模与除数同号；环形索引用 mod |
| `if` | `elsif` 拼写；条件必须 Boolean；顺序判断 |
| `case` | 离散类型；分支必须完备；`others` 收尾 |
| `for` | 循环变量是私有常量；`reverse`；枚举可作范围 |
| 嵌套剪枝 | 等式代换白送变量、约束收紧循环界（百鸡 1442 倍） |
| `exit 名字` | 命名循环一步跳出多重嵌套 |
| `goto` | 同单元体内、不得进出控制结构；仅作深层逃生 |
| declare 块 | 压小作用域；可带名字与 exception 部分 |

控制结构就位后，代码已经有了骨架——但可复用的部件要靠子程序与
包。下一章讲过程与函数：参数模式、缺省参数、重载与递归。

---
上一章：[03 类型](03-types.md) ｜ 下一章：[05 子程序](05-subprograms.md) ｜ 返回：[README](../README.md)
