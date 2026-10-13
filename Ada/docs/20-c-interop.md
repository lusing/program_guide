# 20 · 与 C 语言互操作

> 示例：[`ch20_c_interop.adb`](../examples/ch20_c_interop.adb)（主程序）+
> [`ch20_capi.ads`](../examples/ch20_capi.ads)/[`ch20_capi.adb`](../examples/ch20_capi.adb)（库级导出包）
> 运行：`./run-all.sh 20`（Linux 需 `-largs -lm`，脚本已内置）

"某些实现允许用 Ada 写一部分程序，用其它语言写一部分程序"——
老教材 §10.4 举的两个动机今天依然成立：**复用**别的语言写好的库
（当年是从 FORTRAN 调统计函数），**提速**（把热点子程序用汇编
重写）。Ada 的答案当年是编用 `INTERFACE`，如今是标准化的
`Interfaces.C` 家族 + `Import`/`Export` 方面（aspect）。本章把
现代互操作的四个面讲全：导入函数、导出函数、C 兼容类型、
字符串互操作——每一步都在本机实测（包括用 `nm` 验证导出符号
真的进了可执行文件）。

---

## 20.1 从 pragma Interface 到 aspect Import

老教材的写法（Ada 83，VAX 时代）：

```ada
-- 1992 年：编用 INTERFACE + 输入编用组合
function SQRT (X : FLOAT) return FLOAT;
pragma INTERFACE (FORTRAN, SQRT);
pragma IMPORT_FUNCTION (SQRT, External_Name => "MTH$SQRT");
```

现代等价物（Ada 2005 起的方面语法，Ada 2012 全面铺开）：

```ada
function C_Sqrt (X : Float) return Float
  with Import, Convention => C, External_Name => "sqrtf";
```

两种写法语义相同，aspect 是现在的正统。四个关键词：

| aspect | 含义 |
|--------|------|
| `Import` | 体在别处（C 目标库里），别找 Ada 体 |
| `Convention => C` | 按 C 调用约定（参数传递、寄存器、名字修饰） |
| `External_Name => "sqrtf"` | 链接器眼里的符号名 |
| （老式等价） | `pragma Import (C, C_Sqrt, "sqrtf");` |

**约定（Convention）是关键**：它告诉编译器参数怎么传、返回值
放哪、栈谁清理。`C` 之外还有 `C++`、`Fortran`、`Ada`、
`Intrinsic`（内建）等。两个"碰巧能跑"的类型不匹配（比如拿
`Integer` 接 C 的 `char`）是未定义行为——互操作的第一纪律：
**类型剖面必须逐参数对齐**。

老式 `pragma` 形式仍到处可见（老代码、GNAT 内部），读得懂即可；
新代码用 aspect。

## 20.2 导入 C 函数：从 sqrtf 到 strlen

示例导入三个函数，前两个是最简形态：

```ada
function C_Sqrt (X : Float) return Float
  with Import, Convention => C, External_Name => "sqrtf";

function C_Abs (X : Integer) return Integer
  with Import, Convention => C, External_Name => "abs";
```

```text
  C_Sqrt (16.0) =  4.00000E+00
  C_Abs (-42)   =  42
```

注意 `sqrtf` 吃 `float`（C 的 32 位浮点）——Ada 侧配 `Float`；
要是导入 `sqrt`（double 版本）就必须配 `Long_Float`，配错精度
就是垃圾值。**平台差异**（本章脚注级坑）：Windows 的 UCRT 把
数学函数并入主 C 运行时，`sqrtf` 直接链得到；Linux 的 glibc 把
它们放在独立的 `libm`——链接时必须加 `-largs -lm`，且 `-largs`
之后的内容全部传给链接器、必须放命令行末尾。本仓库的
run-all.sh 已对第 20 章内置了该选项。

第三个导入展示**参数是 C 指针**的形态：

```ada
function C_Strlen (S : Interfaces.C.Strings.chars_ptr)
   return Interfaces.C.size_t
  with Import, Convention => C, External_Name => "strlen";
```

`strlen (const char *)` 的参数在 Ada 侧是 `chars_ptr`——见 20.4。

## 20.3 导出 Ada 函数：符号表里的 ada_add

反方向：把 Ada 子程序交给 C 调用。**规则一：只有库级（library
level）单元能导出**——嵌套在过程里的子程序带着上溯环境引用，
导出给 C 毫无意义（GNAT 直接报 `local subprogram cannot be
exported`，本章示例实测）。所以示例把导出装在独立包
`Ch20_Capi` 里：

```ada
-- ch20_capi.ads
package Ch20_Capi is

   function Ada_Add (A, B : Integer) return Integer
     with Export, Convention => C, External_Name => "ada_add";

end Ch20_Capi;
```

```ada
-- ch20_capi.adb
package body Ch20_Capi is
   function Ada_Add (A, B : Integer) return Integer is (A + B);
end Ch20_Capi;
```

Export 方面三件事：给这个函数生成**符合 C 约定的入口**、把符号
`ada_add` 写进目标文件、让链接器把它当普通的 C 函数对待。
真实性验证——用 `nm` 看可执行文件的符号表：

```text
$ nm build/ch20_c_interop.exe | grep ada_add
0000000140001b20 T ada_add
```

`T` 表示代码段里的全局符号——C 侧 `extern int ada_add(int, int);`
声明一下就能调用。**参数与返回值仍然建议用 `Interfaces.C.int`
一类 C 兼容类型**（20.4），裸用 `Integer` 在多数实现上恰好等宽
（GNAT 的 Integer = int32），但把正确性押在"恰好"上不是工程。

配套老教材没讲的现代选项：`Volatile`/`Atomic`（多线程共享）、
`Export_Procedure` 的中断处理版（`Attach_Handler`，第 21 章低级
篇会见）。老教材 §10.4 的"插入机器代码"（`pragma INTERFACE
(ASM, ...)`）今天用 `Inline_Always` + 内建函数或直接链汇编目标
文件，不再往 Ada 源码里嵌机器码。

## 20.4 C 兼容类型与 Interfaces.C

`Interfaces.C` 包提供全套与 C 对应的类型，**名字就叫 C 的名字**：

| Ada (Interfaces.C) | C | 备注 |
|--------------------|---|------|
| `int` / `unsigned` | `int` / `unsigned int` | C 的 int 宽度 |
| `long` / `long_long` | `long` / `long long` | |
| `size_t` | `size_t` | 无符号尺寸 |
| `double` / `c_double` | `double` | |
| `char_array` | `char[]` | 定长字符数组 |
| `chars_ptr` | `char *` | 指针，配 `Interfaces.C.Strings` |

自己定义时用表示子句钉死布局（第 21 章展开）：

```ada
type C_Int is range -(2 ** 31) .. (2 ** 31 - 1)
   with Size => 32;

type C_Point is record
   X : C_Int;
   Y : C_Int;
end record
   with Convention => C;
```

示例验证 `C_Point'Size = 64 bits`——与 C 的
`struct point { int32_t x, y; }` 逐位一致。记录上加
`Convention => C`（或老式 `pragma Convention (C, C_Point)`）
阻止编译器做 Ada 允许的布局优化。

## 20.5 字符串互操作：To_C / chars_ptr / Value

C 字符串是"NUL 终止的 char 数组或指针"，Ada 的 `String` 是
定长数组**没有终止符**——互操作必须显式转换。三步往返
（示例实测）：

```ada
declare
   use Interfaces.C.Strings;

   -- ① Ada 字符串 → C char 数组（自动补 NUL 终止符）
   Buf   : Interfaces.C.char_array := Interfaces.C.To_C ("Hello, C!");
   -- ② char 数组 → C 指针（chars_ptr），可以传给任何吃 char* 的函数
   C_Str : constant chars_ptr := New_Char_Array (Buf);
   Len   : constant Interfaces.C.size_t := C_Strlen (C_Str);
   -- ③ C 指针 → 回 Ada 字符串
   Back  : constant String := Value (C_Str);
begin
   Put_Line ("  Ada 串 ""Hello, C!"" 交给 strlen → 长度 = "
             & Interfaces.C.size_t'Image (Len));
   Put_Line ("  chars_ptr 再转回 Ada 串 → """ & Back & """");
end;
```

输出：

```text
  Ada 串 "Hello, C!" 交给 strlen → 长度 =  9
  chars_ptr 再转回 Ada 串 → "Hello, C!"
```

要领：

- `To_C` 自动追加 `NUL`——**长度比原串多 1**，接收缓冲区要留够；
  它还有带 `Append_Nul => False` 的版本。
- `chars_ptr` 是受管指针：`New_Char_Array` 在堆上分配，由
  `Free` 释放（或交给 GC 环境）；`New_String (Ada_String)` 是
  一步到位的快捷方式。
- `Value (Ptr)` 从 NUL 处截断转回 Ada 串；还有带最大长度的
  `Value (Ptr, Max)` 防"对面忘了写 NUL"。
- 数组与指针是两个世界：`char_array` 是值（可拷贝），`chars_ptr`
  是把手（传给 C）。**传给 C 函数的永远是 chars_ptr**。

## 20.6 本章示例的完整输出

```text
=== Ada 与 C 互操作 ===

--- 1. 导入 C 函数 ---
  C_Sqrt (16.0) =  4.00000E+00
  C_Abs (-42)   =  42

--- 2. 字符串互操作 ---
  Ada 串 "Hello, C!" 交给 strlen → 长度 =  9
  chars_ptr 再转回 Ada 串 → "Hello, C!"

--- 3. 导出函数 ---
  Ch20_Capi.Ada_Add (2, 3) =  5
  Ada_Add 以符号 ada_add 进入可执行文件符号表
  链接 C 代码时直接 extern int ada_add(int, int); 即可调用。

--- 4. C 兼容类型 ---
  C_Point: X = 10, Y = 20
  C_Point'Size = 64 bits（与 C 的 struct point {int32_t x, y;} 一致）
  Interfaces.C 还提供现成的 int/long/size_t/double 等。
```

## 20.7 小结

| 概念 | 要点 |
|------|------|
| Import/Export aspect | 现代形态；等价老式 `pragma Import/Export` |
| Convention | 调用约定的开关；类型剖面必须逐参数对齐 |
| 导出限制 | 只能导出**库级**单元（实测：嵌套子程序编译错） |
| Interfaces.C | int/size_t/double/char_array/chars_ptr 全家 |
| 表示子句 | `Size => 32`/`Convention => C` 钉死布局 |
| 字符串三步 | `To_C` 补 NUL → `New_Char_Array` 成 ptr → `Value` 转回 |
| 平台差异 | Linux 的 libm 要 `-largs -lm`；Windows UCRT 免 |

互操作是"对外"的低级技术；下一章"低级程序设计"向内看：
表示子句、位布局、地址与中断——Ada 控制硬件的全部把手。

---
上一章：[19 文件 I/O 全景](19-file-io-full.md) ｜ 下一章：[21 低级程序设计](21-low-level.md) ｜ 返回：[README](../README.md)
