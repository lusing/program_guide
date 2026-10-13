# 18 · 文件 I/O：正文、顺序与直接

> 示例：[`examples/ch18_fileio.adb`](../examples/ch18_fileio.adb)
> 运行：`./run-all.sh 18`

"典型的应用程序中，约有 11% 的源代码用于处理输入，处理输出的
还要占 5%"——老教材第三章用这个统计开篇。Ada 把高级输入输出
交给**三个预定义泛型包**：`Text_IO`（人可读的正文）、
`Sequential_IO`（定长元素的顺序二进制）、`Direct_IO`（可按索引
随机访问的二进制）。本章把三件套各讲一套完整用例，覆盖文件的
建立/打开/关闭、模式、EOF 循环、文件异常与缺省文件重定向；
并补上大多数教程略过的两块：**正文输入 Get 家族**与**格式化
输出参数总表**。内容对应张丽芬《Ada 程序设计导论》第三章
（输入和输出）与刘炳文《程序设计语言 Ada》§4.4–4.5、§11.6–11.9；
`Streams` 等现代补充见第 19 章。

---

## 18.1 两种文件观与三件套

老教材 §3.1 的概念框架：**外部文件**（磁盘、终端、磁带上的一串
字节）与**内部文件**（程序里的 `File_Type` 对象）。操作总是
三步：

```
Create/Open（内外文件建立关联）
    → Read/Write/Get/Put（对内部文件操作）
        → Close（解除关联）
```

三件套按"文件里放什么"分工：

| 包 | 元素 | 存取 | 人类可读 |
|----|------|------|----------|
| `Ada.Text_IO` | 字符/行/页 | 顺序 | 是 |
| `Ada.Sequential_IO` | 任意定长类型 | 顺序 | 否（二进制） |
| `Ada.Direct_IO` | 任意定长类型 | 顺序 + **按索引** | 否（二进制） |

`Sequential_IO`/`Direct_IO` 是**泛型包**——元素类型由你实例化
时指定（这正是第 12 章泛型的用武之地）；`Text_IO` 直接用（但
它内部的 `Integer_IO`/`Float_IO`/`Enumeration_IO` 是泛型，实例化
才有 `Put (Integer)`——不过标准库已替我们对 `Integer`/`Float`
预实例化好了：`Ada.Integer_Text_IO`/`Ada.Float_Text_IO`，
`use` 之后直接 `Get`/`Put` 数值）。

## 18.2 正文文件：Text_IO

写 → 读 → 追加的完整循环：

```ada
procedure Write_Text is
   File : File_Type;
begin
   Create (File, Out_File, "report.txt");     -- 建立并关联外部文件
   Put_Line (File, "=== Ada 文件 I/O 测试 ===");
   Put_Line (File, "第一行：正文文件按行读写。");
   for I in 1 .. 3 loop
      Put_Line (File, "  循环行" & Integer'Image (I));
   end loop;
   Close (File);                              -- 解除关联
end Write_Text;
```

读的核心是 **EOF 循环 + 变长行**：

```ada
procedure Read_Text is
   File  : File_Type;
   Line  : String (1 .. 256);
   Last  : Natural;                            -- 实际读到的长度
   Count : Natural := 0;
begin
   Open (File, In_File, "report.txt");        -- 打开已存在的文件
   while not End_Of_File (File) loop
      Get_Line (File, Line, Last);            -- 变长行：Last 告诉我们截到哪
      Count := Count + 1;
      Put_Line ("    行" & Integer'Image (Count) & ": "
                & Line (1 .. Last));
   end loop;
   Close (File);
end Read_Text;
```

`Get_Line (File, Line, Last)` 的签名是老式的（缓冲区 + 长度出参）：
`Line` 是你准备的定长缓冲区，实际内容在 `Line (1 .. Last)`。
行超过 256 字符时这次调用只搬 256 个、下次循环搬剩下的——写
健壮的行处理要再判 `End_Of_Line`。追加：

```ada
Open (File, Append_File, "report.txt");       -- 追加模式：写在文件尾
```

三种模式（第 04 章表格的展开）：

| 模式 | 允许的操作 |
|------|-----------|
| `In_File` | 读（Get/Get_Line） |
| `Out_File` | 写（新建/覆盖） |
| `Append_File` | 写在尾部（仅 Text_IO/Sequential_IO） |

**页与行**：Text_IO 把文件逻辑上看成"页 → 行 → 字符"三层
（行终止符、页终止符），配套 `New_Line`/`New_Page`/`Skip_Line`/
`Skip_Page`/`Col`/`Line`/`Page` 一族位置操作——打印时代的遗产，
做报表对齐依然好用。老教材 §3.3 用它们写了一个带页码跟踪的
打字誊抄程序（COPY），输出的换页逻辑全靠 `Page (Current_Input)`
比对。

## 18.3 正文输入：Get 家族

输出讲得再多，程序总要从外面拿数据。`Text_IO` 的输入面由
**`Get` 家族**构成——键盘与文件**同源**：每个 `Get` 都以文件
参数开头，省略时用当前缺省输入（默认键盘）。所以"从文件读数"
与"从键盘读数"是同一套调用，只差一个 `Set_Input` 重定向。

### 数值 Get：自动跨行，坏词引发 Data_Error

```ada
Open (Data, In_File, "nums.txt");       -- 内容："10 20 oops" / "30"
Set_Input (Data);                        -- 此后无文件参数的 Get 都从文件读

while not End_Of_File loop              -- 无参 End_Of_File = 当前缺省输入
   begin
      Get (N);                           -- 数值 Get：自动跨过空格和行界
      Sum  := Sum + N;
   exception
      when Data_Error =>                 -- "oops" 不是整数
         Skip_Line;                      -- 丢弃坏词所在行，从下一行继续
   end;
end loop;

Set_Input (Standard_Input);              -- 切回键盘
```

实测输出（数据文件两行、三好一坏）：

```text
  Get 读入 3 个整数（跨行），坏词 1 个，和 = 60
```

四个要点：

1. **数值 Get 跳过空格与行终止符**——"10 20"在一行、`30` 在
   下一行，三个数照单全收。想"一行一组"要自己用 `End_Of_Line`
   划界。
2. **解析失败 = Data_Error**，文件位置停在坏词**之前**。恢复
   动作通常是 `Skip_Line`（丢弃本行）后继续——这正是第 11 章
   "块内重试"模式在文件上的应用，也是刘炳文 §11.9 例 11-11
   （跳过非法行求和）的骨架。
3. `End_Of_File` / `End_Of_Line` / `End_Of_Page` 三件判断对应
   "页 → 行 → 字符"三层结构。
4. 提示输入的程序习惯（老书 §4.5）：**`Put` 提示在先，`Get`
   跟后**——`Put ("Enter an integer: "); Get (N);`。没有提示的
   交互程序会让用户对着黑窗发呆。

### 字符串 Get：硬读满，跨行界

```ada
declare
   Buf  : String (1 .. 8);
   Last : Natural;
begin
   Get (Data, Buf);                      -- 恰好读满 8 个字符（"10 20 oo"）
   ...
   Get_Line (Data, Buf, Last);           -- Get_Line 才给"实际长度"
end;
```

**实测纠正一个以讹传讹**：老教材说"字符串的长度要设置得适当，
否则在输入时要补充空格"（§4.5 例 4-7）。GNAT 的真实语义是——
`Get (Buf)` **硬读满 `Buf'Length` 个字符，行界直接跨过去继续
凑数**：缓冲 6 格、文件第一行只有 `"ab"`，读到的不是 `"ab    "`
而是 `"ab0123"`（后 4 格来自下一行！）；到了文件尾还凑不满，
不做任何补齐，直接 `End_Error`。**按行处理是 `Get_Line` 的
专利**——`Last` 出参告诉你有效长度，`Buf (1 .. Last)` 才是
本行内容。

### Get 家族速查

| 调用 | 语义 |
|------|------|
| `Get (N)` 数值/枚举 | 跳空格跨行界，解析目标类型的值；失败 `Data_Error` |
| `Get (Ch)` 字符 | 恰好一个字符，**同样跨过行界**（实测：读 `"ab"` 后再 Get 得到下一行的 `'c'`；要探测行尾用 `End_Of_Line`/`Look_Ahead`） |
| `Get (Buf)` 字符串 | 硬读满 `Buf'Length` 格，跨行界 |
| `Get_Line (Buf, Last)` | 读到行尾，`Last` 出实际长度 |
| `Get_Immediate (Ch)` | 不等回车立即取一键（键盘交互、游戏循环） |
| `Skip_Line` / `Skip_Page` | 丢弃本行/本页剩余 |

一句话总结这套语义：**在 `Get` 眼里只有"字符流"，行只是
`Get_Line`/`End_Of_Line` 关心的注记**。想按行处理，先
`Get_Line` 拿整行再解析字符串（第 11 章的 `Integer'Value` 路
线），或老老实实用 `End_Of_Line` 划界。

**实测坑（混用 Get 与 Get_Line）**：数值 `Get` 恰好读到最后一
个字符、文件只剩行终止符时，紧接着的 `Get_Line` 会在 GNAT 下
直接 `End_Error`（此时 `End_Of_File` 已为 True）。要清理行残留
用 `Skip_Line`——它对"已在行尾"是安全的。

（`Get_Immediate` 只对真实终端有意义——重定向到文件时它退化为
普通读；本教程的自动化测试都走 `Set_Input` 文件重定向，故示例
未演示它。）

## 18.4 格式化输出：参数总表

老书 §4.4 用一整节加表 4-2 讲 `Put` 的格式参数——这套参数今天
一个没变，依然是报表对齐的全部家当。数值与枚举的 `Put` 来自
实例化包（或预实例化的 `Ada.Integer_Text_IO` 等）：

```ada
Put (255, Width => 6);                   -- 数值右对齐，左侧补空格
Put (255, Base => 16);                   -- 带基输出：16#FF#
Put (255, Base => 2, Width => 12);       -- 2#11111111#，右对齐
Put (3.14159, Fore => 0, Aft => 3, Exp => 0);   -- 3.142
Level_IO.Put (High, Set => Lower_Case);  -- 枚举小写输出：high
```

```text
  Put (255, Width => 6) = [   255]
  Put (255, Base => 16) = [     16#FF#]
  Put (255, Base => 2, Width => 12) = [ 2#11111111#]
  Put (3.14159, Fore => 0, Aft => 3, Exp => 0) = [3.142]
  枚举小写 Level_IO.Put (High, Set => Lower_Case) = [high]
```

参数一览（`Field`/`Number_Base`/`Type_Set` 都是 `Text_IO` 的
整数/枚举子类型）：

| 类型 | 参数 | 缺省 | 含义 |
|------|------|------|------|
| 整数 | `Width` | `Integer'Width` 级实现值 | 最小域宽，右对齐左补空格 |
| 整数 | `Base` | 10 | 2–16 基；输出 `16#FF#` 形态（第 02 章直接量语法互为镜像） |
| 浮点/定点 | `Fore` | 2 | 小数点前位数（含符号位） |
| 浮点/定点 | `Aft` | 由 `digits` 定 | 小数位数（四舍五入） |
| 浮点 | `Exp` | 3 | 指数位数；0 = 不用科学计数 |
| 枚举/布尔 | `Width` | 0 | 最小域宽，**左对齐右补空格** |
| 枚举/布尔 | `Set` | Upper_Case | `Lower_Case` 输出小写 |

两条对齐纪律记牢：**数值右对齐**（补空格在左），**字符/
字符串/枚举/布尔左对齐**（补空格在右）——对账单里价格列与
品名列天然相反的原因。

### Set_Col：绝对列定位

```ada
for I in 1 .. 3 loop
   Set_Col (6);   Put ("Item"  & Integer'Image (I));
   Set_Col (20);  Put_Line ("价格" & Integer'Image (I * 25));
end loop;
```

```text
     Item 1        价格 25
     Item 2        价格 50
     Item 3        价格 75
```

`Set_Col (N)` 把当前位置**跳到第 N 列**（只能向后跳；已越过
则换行）。配套 `Set_Line`（行定位）、`Col`/`Line`（查询）。
刘炳文 §6.10 的价目表程序（例 6-14）通篇靠 `Set_Col` 排版——
今天做两栏报表、对齐表格依然是它。

## 18.5 顺序二进制：Sequential_IO

记录整块进整块出——元素类型**任意**（这里是一个记录）：

```ada
type Sensor_Sample is
   record
      Id    : Integer;
      Value : Float;
   end record;

package Sample_IO is new Ada.Sequential_IO (Sensor_Sample);
```

**实例化是必经步骤**——这就是"为给定元素类型生成文件操作"的
泛型取例（老教材 §3.2 的四步流程：with → 实例化 → 说明 File_Type
→ Create/Open/Read/Write/Close）。写：

```ada
procedure Write_Sequential is
   File  : Sample_IO.File_Type;
   Data  : constant array (1 .. 3) of Sensor_Sample :=
     ((1, 21.5), (2, 22.0), (3, 19.8));
begin
   Sample_IO.Create (File, Sample_IO.Out_File, "samples.bin");
   for K in Data'Range loop
      Sample_IO.Write (File, Data (K));
   end loop;
   Sample_IO.Close (File);
end Write_Sequential;
```

读：

```ada
File : Sample_IO.File_Type;
S    : Sensor_Sample;
...
Sample_IO.Open (File, Sample_IO.In_File, "samples.bin");
while not Sample_IO.End_Of_File (File) loop   -- 二进制文件同样有 EOF
   Sample_IO.Read (File, S);
   ...
end loop;
```

运行验证（记录原样往返）：

```text
--- 3. 顺序二进制 (Sequential_IO) ---
  顺序写入 3 条记录：samples.bin
    读回: Id = 1  Value = 2.15000E+01
    读回: Id = 2  Value = 2.20000E+01
    读回: Id = 3  Value = 1.98000E+01
```

**多 IO 包撞名陷阱**（本章示例实测）：`Sample_IO.File_Type` 与
`Text_IO.File_Type` 同名，`In_File`/`Out_File` 也同名。规则：
**实例化之后绝不 `use`**，全部限定调用 `Sample_IO.Open (...)`。
一旦 `use Sample_IO;`，`File_Type` 立刻二义，编译器直接罢工。

## 18.6 直接文件：Direct_IO

直接文件 = 顺序文件 + **索引**：每个元素有个位置号（**从 1
起**），读写可以直奔目标。这是老教材 §3.2 例二（10 的幂表）的
现代重演：

```ada
package Nat_IO is new Ada.Direct_IO (Integer);
...
Nat_IO.Create (File, Nat_IO.Inout_File, "powers.bin");  -- 可读写一体
for P in 0 .. 5 loop
   Nat_IO.Write (File, 10 ** P);           -- 顺序写 6 条
end loop;
Nat_IO.Reset (File, Nat_IO.Inout_File);    -- 复位到文件头，保持读写一体

Nat_IO.Read (File, V, 3);                  -- 直接读第 3 条（索引从 1 起）
Nat_IO.Write (File, 999_999, 2);           -- 原地改写第 2 条
```

`Read/Write` 带索引参数（`FROM`/`TO`）就是随机访问；不带则从
当前位置顺序走。输出：

```text
--- 4. 直接文件 (Direct_IO) ---
  直接读第 3 条（10**2）→ 100
  直接读第 6 条（10**5）→ 100000
  改写第 2 条后读回 → 999999
```

三个使用要点：

1. **模式**：Direct_IO 独有 `Inout_File`——读写一体，随机改写的
   前提。（本章示例实测：Reset 成 `In_File` 之后再 `Write`，
   运行期立刻 `MODE_ERROR: file not writable`——模式不是摆设。）
2. **元素定长**：索引 n 的字节位置 = (n-1) × 元素大小。所以
   元素类型必须是定长的（记录里塞无界 `String` 不行，定长
   `String (1..20)` 可以）。
3. **文件尺寸**：`Size (File)` 返回元素个数，`Index (File)` 返回
   当前索引——分页、索引查找都靠它们。

直接文件是数据库文件、定长记录表（工资表、学籍卡）的正统工具：
改第 3847 条记录不必重写整个文件。

## 18.7 文件异常：七个预定义名

老教材 §3.2 列出的 IO 异常，全部活在 `Ada.IO_Exceptions` 里：

| 异常 | 引发场景 |
|------|----------|
| `Name_Error` | Open 的文件不存在 / 名字非法 |
| `Use_Error` | 模式与文件不匹配（对只读文件 Create） |
| `Mode_Error` | 在 In_File 上写、Append 之外的模式越权 |
| `Status_Error` | 对未打开的文件操作 / 重复打开 |
| `End_Error` | 读过了文件尾 |
| `Data_Error` | Get 读到的不是合法的目标类型值 |
| `Device_Error` | 设备故障 |

示例演示最常见的一个：

```ada
declare
   File : File_Type;
begin
   Open (File, In_File, "不存在 的 文件.txt");
exception
   when Name_Error =>
      Put_Line ("  捕获 Name_Error：文件名不存在/不可访问。");
end;
```

工程习惯（第 11 章的重试模式）：**Create 失败问用户、Open 失败
查路径、End_Error 是循环边界、Data_Error 提示数据损坏**——
四种最常见的处理路径。

## 18.8 缺省文件：Set_Output 重定向

`Put_Line ("...")` 不带文件参数时输出到**当前缺省输出**——
默认是屏幕，但可以重定向：

```ada
declare
   Log : File_Type;
begin
   Create (Log, Out_File, "trace.log");
   Set_Output (Log);                          -- 此后无文件参数的 Put 都进日志
   Put_Line ("这行进了 trace.log，而不是屏幕。");
   Set_Output (Standard_Output);              -- 切回标准输出
   Close (Log);
```

配套家族：`Set_Input`/`Standard_Input`/`Standard_Output`/
`Current_Input`/`Current_Output`。老教材 §3.3 的用法：把某段
计算"tee"进日志文件而不改计算代码——一个 `Set_Output` 夹住即可。
（现代更讲究的做法是到处传 `File_Type` 参数；重定向适合快速
取证与老代码的无侵入改造。）

## 18.9 本章示例的完整输出

```text
=== Ada 文件 I/O ===

--- 1. 正文文件 ---
  写入完成：report.txt
    行 1: === Ada 文件 I/O 测试 ===
    行 2: 第一行：正文文件按行读写。
    行 3:   循环行 1
    行 4:   循环行 2
    行 5:   循环行 3

--- 2. 追加 ---
  追加完成（带时间戳）
    行 1: === Ada 文件 I/O 测试 ===
    ...
    行 6: 追加时间: 2026-10-13 03:30:36

--- 3. 顺序二进制 (Sequential_IO) ---
  顺序写入 3 条记录：samples.bin
    读回: Id = 1  Value = 2.15000E+01
    读回: Id = 2  Value = 2.20000E+01
    读回: Id = 3  Value = 1.98000E+01

--- 4. 直接文件 (Direct_IO) ---
  直接读第 3 条（10**2）→ 100
  直接读第 6 条（10**5）→ 100000
  改写第 2 条后读回 → 999999

--- 5. 文件异常 ---
  捕获 Name_Error：文件名不存在/不可访问。

--- 6. 缺省文件重定向 ---
  从 trace.log 读回: 这行进了 trace.log，而不是屏幕。

--- 7. 正文输入：Get 家族 ---
  Get 读入 3 个整数（跨行），坏词 1 个，和 = 60
  字符串 Get 前 8 格 = "10 20 oo"
  Get_Line 第二行 = "30"（Last = 2，不含补空格）

--- 8. 格式化输出参数 ---
  Put (255, Width => 6) = [   255]
  Put (255, Base => 16) = [     16#FF#]
  Put (255, Base => 2, Width => 12) = [ 2#11111111#]
  Put (3.14159, Fore => 0, Aft => 3, Exp => 0) = [3.142]
  枚举小写 Level_IO.Put (High, Set => Lower_Case) = [high]
  Set_Col 两栏对齐:
     Item 1        价格 25
     Item 2        价格 50
     Item 3        价格 75

文件 I/O 演示完成。
```

## 18.10 小结

| 概念 | 要点 |
|------|------|
| 内/外文件 | `File_Type` ↔ 物理文件；Create/Open→操作→Close |
| Text_IO | 行/页/字符三层；Get_Line 的 Last 出参 |
| 数值 Get | 跳空格跨行界；坏词 `Data_Error` + `Skip_Line` 恢复 |
| 字符串 Get | 硬读满缓冲、跨行界；EOF 凑不满直接 `End_Error` |
| 键盘=文件 | `Set_Input`/`Standard_Input` 与 Set_Output 对称 |
| 格式化 | 整数 Width/Base（`16#FF#`）；浮点 Fore/Aft/Exp；枚举 Set |
| 对齐纪律 | 数值右对齐补左空格；字符/串/枚举/布尔左对齐补右空格 |
| Sequential_IO | 泛型实例化定元素；Write/Read + EOF |
| Direct_IO | `Inout_File` 读写一体；索引从 1；元素必须定长 |
| 撞名纪律 | 多 IO 包实例化后绝不 use，全限定 |
| IO 异常 | Name/Use/Mode/Status/End/Data/Device_Error |
| 缺省文件 | Set_Output/Standard_Output 重定向 |

本章覆盖了三件套的核心面。`Ada.Streams`（变长元素、跨类型混合
流）、`Ada.Directories`（遍历/改名/删除文件）等现代设施在第 19
章"文件 I/O 全景"继续。

---
上一章：[17 任务深入](17-select-family.md) ｜ 下一章：[19 文件 I/O 全景](19-file-io-full.md) ｜ 返回：[README](../README.md)
