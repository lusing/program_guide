# 18 · 文件 I/O：正文、顺序与直接

> 示例：[`examples/ch18_fileio.adb`](../examples/ch18_fileio.adb)
> 运行：`./run-all.sh 18`

"典型的应用程序中，约有 11% 的源代码用于处理输入，处理输出的
还要占 5%"——老教材第三章用这个统计开篇。Ada 把高级输入输出
交给**三个预定义泛型包**：`Text_IO`（人可读的正文）、
`Sequential_IO`（定长元素的顺序二进制）、`Direct_IO`（可按索引
随机访问的二进制）。本章把三件套各讲一套完整用例，覆盖文件的
建立/打开/关闭、模式、EOF 循环、文件异常与缺省文件重定向。
内容对应张丽芬《Ada 程序设计导论》第三章（输入和输出）；
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
才有 `Put (Integer)`）。

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

## 18.3 顺序二进制：Sequential_IO

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

## 18.4 直接文件：Direct_IO

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

## 18.5 文件异常：七个预定义名

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

## 18.6 缺省文件：Set_Output 重定向

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

## 18.7 本章示例的完整输出

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

文件 I/O 演示完成。
```

## 18.8 小结

| 概念 | 要点 |
|------|------|
| 内/外文件 | `File_Type` ↔ 物理文件；Create/Open→操作→Close |
| Text_IO | 行/页/字符三层；Get_Line 的 Last 出参 |
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
