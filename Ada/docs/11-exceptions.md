# 11 · 异常处理

> 示例：[`examples/ch11_exceptions.adb`](../examples/ch11_exceptions.adb)
> 运行：`./run-all.sh 11`

异常处理是"程序运行时允许出错的反映和弥补错误的机制"。Ada 把
可靠性列为设计目标——错误输入、硬件故障不该让程序无声崩溃，
而应**引发（raise）一个有名有姓的异常**，由**异常处理程序**接住，
要么恢复要么体面退出。本章讲全异常机制：说明与引发、捕获与
`others`、沿调用链的**传播**与再抛、块结构如何**圈住**异常、
偶发故障的重试模式、以及**抑制检查**。内容对应张丽芬《Ada 程序
设计导论》第七章（异常处理）；Ada 83 的 `NUMERIC_ERROR` 等术语
按现代标准（Ada 95+）勘正。

---

## 11.1 异常模型：两类反应方式

老教材 §7.1 把各语言的错误处理分为两类：

1. 异常处理程序像普通子程序调用，处理完**返回出错点继续执行**；
2. 异常导致正常执行被**挂起**，处理完**不返回**出错点。

Ada 属于第 2 类：异常引发时，当前块/子程序的剩余语句**被放弃**，
控制直接交给处理程序。不能"跳回去重试"——想重试就用循环把可疑
代码围起来（见 11.4）。这个模型与 C++/Java 一致，但在 1992 年的
教材里，这是专门要向 Pascal/C 程序员强调的"新概念"。

预定义异常有五个（名字沿用至今）：

| 异常 | 引发场景（示例） |
|------|------------------|
| `Constraint_Error` | 范围/下标/判别式越界；除零；null 解引用；数值溢出（Ada 95 起） |
| `Program_Error` | 无 else 的 select 全部关闭；调用了尚未加工的单元 |
| `Storage_Error` | 内存耗尽（栈溢出、分配失败） |
| `Tasking_Error` | 任务通信失败（第 15 章） |

> 术语注记：Ada 83 还有第 5 个 `NUMERIC_ERROR`（数值运算出错）。
> Ada 95 把它定义为 `Constraint_Error` 的**换名**——除零、溢出
> 现在都归 `Constraint_Error`。读老代码时知道这个映射即可。

## 11.2 异常说明与 raise

**异常说明**——自定义异常就是一个 `exception` 类型的对象说明：

```ada
My_Error      : exception;
Sensor_Failed : exception;
```

老教材的建议位置：**程序包的说明中、与引发它的子程序放在一起**
（第 10 章的分数包里 `Zero_Denominator : exception;` 就是这么放的）
——异常名是接口的一部分。

**引发语句**两种：

```ada
raise Sensor_Failed;                        -- 引发指定异常
raise Sensor_Failed with "重试 10 次仍失败，放弃";  -- 附带消息（Ada 2005）
```

示例的除法函数演示了"预定义异常 + 消息"的惯用法：

```ada
function Safe_Divide (A, B : Integer) return Integer is
begin
   if B = 0 then
      raise Constraint_Error with "除数不能为零";
   end if;
   return A / B;
end Safe_Divide;
```

用预定义异常加消息，比自定义异常更贴合语义时（约束类错误）就用
预定义；业务性错误（余额不足、传感器失效）才自定义。

## 11.3 捕获：when 选择与 others

异常处理程序放在块/子程序/包体/任务体的 `exception` 关键字之后：

```ada
begin
   Put_Line ("  尝试 10 / 0 ...");
   declare
      Result : constant Integer := Safe_Divide (10, 0);
   begin
      Put_Line ("  结果:" & Integer'Image (Result));
   end;
exception
   when Constraint_Error =>
      Put_Line ("  捕获 Constraint_Error！");
   when others =>
      Put_Line ("  捕获其他异常");
end;
```

语法规则：

- 一个 `when` 后可以列**多个异常名**：`when Constraint_Error |
  Program_Error =>`；
- 每个异常名只能出现一次；
- `when others` 若存在**必须最后**，兜住所有未点名的异常
  （含预定义与你不知道的）；
- 处理程序**不返回**——执行完就结束本块/子程序。

要拿到异常的详细信息，用 `Ada.Exceptions`（处理程序的
`when E : others` 声明了一个"异常出现（occurrence）"对象 E）：

```ada
begin
   raise Program_Error with "演示异常信息";
exception
   when E : others =>
      Put_Line ("  异常名称: " & Ada.Exceptions.Exception_Name (E));
      Put_Line ("  异常信息: " & Ada.Exceptions.Exception_Message (E));
end;
```

输出：名称 `PROGRAM_ERROR`、消息 `演示异常信息`。还有
`Exception_Information`（带调用栈信息）与 `Save_Occurrence`/
`Reraise_Occurrence`（存下异常稍后在别处重抛——分布式中转、
日志线程的利器）。

## 11.4 传播与再抛：raise;

异常没被本地处理就**传播**——沿调用链向上找处理程序。规则
（老教材 §7.5 的两种时机四类场景，浓缩版）：

- **语句执行期**引发：本单元无处理程序 → 传播给调用者；调用者
  处理程序在**调用点**被激活。子程序/块/包体/任务体各按此规则。
- **说明加工期**引发（如说明部分的函数调用失败）：跳过本单元
  一切处理程序，直接传播给外层。
- 主程序也无人接 → 程序终止，系统打印异常信息。

示例的三层演示：

```ada
procedure Level_3 is
begin
   raise My_Error with "从 Level_3 抛出的错误";
end Level_3;

procedure Level_2 is
begin
   Level_3;
exception
   when My_Error =>
      Put_Line ("  Level_2 捕获到异常，重新抛出（raise;）");
      raise;                            -- 裸 raise：再抛当前异常
end Level_2;
```

```ada
begin
   Level_2;
exception
   when My_Error =>
      Put_Line ("  最外层捕获到 My_Error（经 Level_2 转发）");
end;
```

**裸 `raise;`** 只能出现在处理程序里：记一笔日志、改写消息、
翻译成别的异常之后再抛——"捕获-加工-转发"链的标准写法。老教材
ROOTS 二次方程例子是经典应用：`SQRT` 负参数引发的
`Constraint_Error` 传到 `ROOTS`，`ROOTS` 打印诊断后 `raise ERROR`
把**业务级**异常传给调用者——底层异常翻译成高层语义。

## 11.5 块结构圈异常：就地处理，循环重试

异常会放弃整个块/子程序——想"只放弃一小段"，把那一小段装进
declare 块。老教材 §7.2 的交互式输入例（`PROCESS_ONLINE`）是
这个模式的范本：读数字失败不该终止程序，该让用户重输。示例的
无交互版本（解析字符串数组，逐个尝试）：

```ada
Bad_Inputs : constant array (1 .. 3) of String (1 .. 4) :=
  ("12ab", "x78y", "3456");
...
for K in Bad_Inputs'Range loop
   begin
      Parsed := Integer'Value (Bad_Inputs (K));
      Put_Line ("  第" & Integer'Image (K) & " 个输入解析成功:"
                & Integer'Image (Parsed));
   exception
      when Constraint_Error =>
         Put_Line ("  第" & Integer'Image (K) & " 个输入 """
                   & Bad_Inputs (K) & """ 不是数字，跳过");
   end;
end loop;
```

输出：

```text
  第 1 个输入 "12ab" 不是数字，跳过
  第 2 个输入 "x78y" 不是数字，跳过
  第 3 个输入解析成功: 3456
  异常被限制在块内，循环继续——这就是块结构的核心用途。
```

`Integer'Value ("12ab")` 引发 `Constraint_Error`（解析失败的正统
信号），但异常的破坏半径被块圈死：**块终止，循环继续**。老教材
原话："异常的引发始终限制在块结构中"——这正是第 04 章 declare 块
"可带自己的 exception 部分"的用武之地。

## 11.6 偶发故障：重试 N 次

硬件故障常常是偶发的——磁带读错、网络抖动，重试几次就好。老教材
§7.6 的"读带重试 10 次"模式：

```ada
for I in 1 .. 10 loop
   begin
      Ok : Boolean;
      Read_Tape (Ok);
      if not Ok then
         raise Sensor_Failed;
      end if;
      Put_Line ("  第" & Integer'Image (I) & " 次尝试成功。");
      exit;
   exception
      when Sensor_Failed =>
         Put_Line ("  第" & Integer'Image (I) & " 次读失败，反绕重试...");
         if I = 10 then
            raise Sensor_Failed with "重试 10 次仍失败，放弃";
         end if;
   end;
end loop;
```

（示例里 `Read_Tape` 用计数器模拟"前 3 次失败、第 4 次成功"。）
结构是**循环 × 块**：块负责圈住单次尝试的异常，循环负责发起
下一次；`exit` 在成功时跳出；第 N 次仍失败就在处理程序里 `raise`
把异常交出去。数据库重连、传感器轮询、IO 重试——全是这个骨架。

## 11.7 出错时的兜底值

老教材 §7.8 的阶乘例——溢出时返回 `Integer'Last` 而不是崩溃：

```ada
function Factorial (N : Natural) return Integer is
   Fact : Integer := 1;
begin
   for I in 2 .. N loop
      Fact := Fact * I;
   end loop;
   return Fact;
exception
   when Constraint_Error =>
      return Integer'Last;      -- 上限兜底：调用方看得懂的含义
end Factorial;
```

```text
  12! = 479001600
  99! 溢出 → 返回 Integer'Last = 2147483647
```

注意处理程序里 `return` 完全合法——处理程序与所在子程序"有同样
的权力"。这种"极端安全值"策略要慎用（调用方必须知道约定），
但对超界即无意义的计算（组合数爆表）是干净的妥协。

## 11.8 抑制检查：pragma Suppress

每个范围/下标/除法检查都要花运行时间。**确信安全**的热点代码
可以局部关闭检查：

```ada
declare
   pragma Suppress (Range_Check);   -- 仅本块生效
   A : Integer range 1 .. 10 := 5;
begin
   A := A + 1;                      -- 确信不会越界：免检提速
   Put_Line ("  本块内 Range_Check 已抑制：A =" & Integer'Image (A));
   Put_Line ("  出了块，检查恢复——抑制范围被块结构限死。");
end;
```

老教材 §7.7 给出的可抑制检查清单至今有效：`Range_Check`、
`Index_Check`、`Access_Check`（null 检查）、`Overflow_Check`、
`Division_Check`……每项对应 `Constraint_Error` 的一族来源。

三条纪律：

1. **先测后关**——只在确认"相应的条件不会发生"后抑制；
2. **范围最小化**——放在块/子程序里，别放库单元级一刀切；
3. **代价认知**——抑制后若条件真的发生，行为**未定义**（不再是
   可靠的异常，可能是静默的错值）。

SPARK（第 25 章）提供了正道：**证明**检查永不触发，然后由工具
自动免检——既快又不出卖安全性。

## 11.9 本章示例的完整输出

```text
=== Ada 异常处理 ===

--- 1. 基本捕获 ---
  尝试 10 / 0 ...
  捕获 Constraint_Error！

--- 2. 异常信息 ---
  异常名称: PROGRAM_ERROR
  异常信息: 演示异常信息

--- 3. 传播与再抛 ---
  Level_2 捕获到异常，重新抛出（raise;）
  最外层捕获到 My_Error（经 Level_2 转发）

--- 4. 块内重试 ---
  第 1 个输入 "12ab" 不是数字，跳过
  第 2 个输入 "x78y" 不是数字，跳过
  第 3 个输入解析成功: 3456
  异常被限制在块内，循环继续——这就是块结构的核心用途。

--- 5. 偶发故障重试 ---
  第 1 次读失败，反绕重试...
  第 2 次读失败，反绕重试...
  第 3 次读失败，反绕重试...
  第 4 次尝试成功。

--- 6. 出错时返回安全值 ---
  12! = 479001600
  99! 溢出 → 返回 Integer'Last = 2147483647

--- 7. 抑制检查 (Suppress) ---
  本块内 Range_Check 已抑制：A = 6
  出了块，检查恢复——抑制范围被块结构限死。
```

## 11.10 小结

| 概念 | 要点 |
|------|------|
| 模型 | 引发即挂起；处理完不返回出错点 |
| 预定义异常 | Constraint/Program/Storage/Tasking_Error；NUMERIC_ERROR 已并入 |
| 说明与引发 | `X : exception;` + `raise X with "消息";` |
| 捕获 | `when A \| B =>`；`others` 必须最后；不返回 |
| 传播 | 无本地处理程序→沿调用链；说明期异常直接外抛 |
| 裸 `raise;` | 处理程序内再抛当前异常；捕获-加工-转发 |
| 块圈异常 | declare 块 + exception：破坏半径最小化 |
| 重试模式 | 循环 × 块；N 次失败后主动 raise |
| Suppress | 局部关检查提速；SPARK 是正道 |

异常兜住了"出错的时刻"，接下来两章回到"写可复用代码"的主线：
泛型（第 12、13 章）与面向对象（第 14 章）。

---
上一章：[10 包](10-packages.md) ｜ 下一章：[12 泛型](12-generics.md) ｜ 返回：[README](../README.md)
