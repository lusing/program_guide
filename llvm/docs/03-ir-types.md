# 03 · IR 类型系统与聚合数据

> 对应示例：`examples/03_ir_types/`（types.ll）

C 能表达的内存布局，IR 都要能表达——结构体、数组、嵌套、对齐、全局常量。这一章把类型系统一次讲全，然后重点攻下 LLVM 最"劝退"的一条指令：`getelementptr`（GEP）。学完这章，你拿到任何 C 声明都能徒手写出对应的 IR。

## 3.1 基础类型总表

IR 的基础类型是刻意保持"贫瘠"的（复杂类型靠组合）：

| 类别 | 类型 | 说明 |
|---|---|---|
| 空 | `void` | 仅用于返回类型 |
| 整数 | `i1` `i8` `i16` `i32` `i64` `i128`… | **任意位宽都合法**（`i37` 也行），有无符号由**运算**决定而非类型 |
| 浮点 | `half` `bfloat` `float` `double` `fp128` | IEEE 754 各精度 |
| 指针 | `ptr` | 不透明指针，**不记录指向类型**（见 3.6） |
| 标签 | `label` | 基本块（只出现在块入口） |
| 向量 | `<4 x i32>`、`<8 x float>` | SIMD，第 5 章优化会见到 |

两个颠覆 C 直觉的设计：

1. **整数没有符号**。`i32` 只是 32 个比特。`icmp slt`（有符号小于）和 `icmp ult`（无符号小于）才是符号所在；除法也分 `sdiv`/`udiv`。
2. **没有 `struct` 关键字的"声明即类型"**。聚合类型是**字面量**：`{ i32, double }` 本身就是类型，两个同构的字面量类型相等。命名只是别名：

```llvm
%Point = type { i32, double }        ; 命名结构体：之后 %Point ≡ { i32, double }
; 以下全部是合法类型：
; { i32, { i8, i64 } }               嵌套字面量
; [4 x [2 x i32]]                    二维数组
; <{ i8, i8, i8 }>                   packed struct（无填充，保证紧凑）
```

> **坑：字面量 vs 命名**。同一模块里 `{i32, double}` 与 `%Point` 的**定义**混用没问题（结构等价），但**自引用类型**（链表节点）必须用命名写法，否则无限展开：

```llvm
%Node = type { i32, ptr }            ; ptr 不带指向类型，自引用天然无压力
```

（v10 时代的 ` %Node = type { i32, %Node* }` 写法随类型化指针一起进了历史。）

## 3.2 全局变量与常量

```llvm
@table   = global [4 x i32] [i32 10, i32 20, i32 30, i32 40]  ; 可变全局
@origin  = constant %Point zeroinitializer                     ; 只读全局
@name    = private constant [6 x i8] c"hello\00"               ; 字符串=字节数组
@counter = global i64 0, align 8                                ; 显式对齐
```

语法骨架：`@名字 = linkage? (global|constant) 类型 初始值`。

**`global` vs `constant`**：`constant` 断言永不写入，违反它优化器有权毁天灭地（把所有 load 折叠成初值）。字符串一律 `constant`。

**初始值速查**：

| 写法 | 含义 |
|---|---|
| `[i32 10, i32 20, ...]` | 数组逐元素 |
| `%Point { i32 0, double 0.0 }` | 结构体逐字段 |
| `zeroinitializer` | 全零（任何类型通吃） |
| `undef` | "随便什么值"（未初始化内存的抽象） |
| `poison` | "传染性垃圾"（碰了就 UB，比 undef 更利于优化） |

**linkage（链接可见性）**只讲最常见的四个，够用到第 24 章：

| linkage | 类比 C | 说明 |
|---|---|---|
| （默认 `external`） | 全局符号 | 跨模块可见 |
| `private` | 匿名命名空间 | 仅本模块，符号名可被随意改写（`.ll` 里那些 `@.fmt` 就是） |
| `internal` | `static` | 本模块可见，参与全局优化 |
| `weak` / `linkonce_odr` | 弱符号/内联候补 | C++ 模板实例、COMDAT 的底座 |

`unnamed_addr` 是补充修饰："地址不重要，只有内容重要"——允许优化器把内容相同的常量合并。

## 3.3 alloca / load / store：栈上的一格内存

IR 里操纵内存的三板斧：

```llvm
%buf = alloca %Point               ; 在栈上开一块 %Point 大小的空间，%buf: ptr
store %Point %pt, ptr %buf         ; 往里写
%pt2 = load %Point, ptr %buf       ; 从里读
```

注意 **load/store 的类型写在操作数前面**：`load 读出的类型, 指针`。因为 `ptr` 不记录指向类型，读什么类型完全由 load 说了算——这既是自由的源泉（`bitcast` 几乎消失），也是脚下的坑（读写的类型要自己保证一致，第 9 章讲 TBAA 时展开）。

## 3.4 GEP：getelementptr 完全指南

GEP 是 LLVM 的"取地址"指令，也是新人杀手。先看对照：

```c
int table[4];
int *p1 = &table[1];              // C：地址 + 4 字节
```

```llvm
%g1 = getelementptr [4 x i32], ptr @table, i64 0, i64 1
```

语法：`getelementptr 基类型, 基地址, 第一索引, 第二索引, ...`

**规则一（最反直觉）**：第一个索引在"整个聚合的外面"走，第二个才进入聚合内部。对全局数组取元素，第一索引恒为 0：

```llvm
;                        基类型      基地址    外面走0格  进到第1格
%g1 = getelementptr [4 x i32], ptr @table, i64 0,   i64 1     ; &table[1]
%g2 = getelementptr [4 x i32], ptr @table, i64 1             ; 越过整个数组（&table+16字节）
```

**规则二：GEP 只做地址算术，绝不访问内存**。它算出 `ptr`，要值还得 `load`。也没有"数组越界检查"——纯粹是 `(基地址 + 字节偏移)` 的类型化包装。

**规则三：每级索引按该层的步长走**。结构体字段必须用**常量**索引：

```llvm
%f = getelementptr %Point, ptr %p, i32 0, i32 1    ; &p->y：外0格，进字段1（偏移4，double）
```

多维与嵌套的直觉：**索引串就是"寻路指令表"**，逐层进入聚合：

```llvm
; int m[3][4];
%e = getelementptr [3 x [4 x i32]], ptr @m, i64 0, i64 2, i64 3   ; &m[2][3]
;  进到第 2 行（步长 16 字节）→ 再进到行内第 3 格（步长 4 字节）
```

> **为什么 GEP 长这样（而不是像 C 指针算术）**：GEP 的索引是"逻辑格数"，步长由类型系统推——`&table[1]` 是 +4 字节还是 +8，由 `i32`/`i64` 决定，不必硬编码。这使优化器能精确推理别名和对齐。C 的 `p+1` 翻译到 IR 必须经过 GEP（或显式字节算术 `ptrtoint/add/inttoptr`，后者会杀死别名信息）。

**inbounds 变体**：`getelementptr inbounds` 额外断言"没出聚合边界"，优化器据此敢做更多推理。clang 生成的 GEP 几乎都带它。

## 3.5 结构体的构造与析取

聚合值（非内存）操作用 `insertvalue`/`extractvalue`：

```llvm
%p0 = insertvalue %Point undef, i32 %x, 0      ; 在 undef 骨架上填字段 0
%p1 = insertvalue %Point %p0, double %y, 1     ; 再填字段 1
%x2 = extractvalue %Point %p1, 0               ; 取字段 0
```

索引语法和 GEP 一脉相承（但作用于**值**，没有第一索引——不涉及地址）。

实测主程序里两种风格同框：

```llvm
%pt  = call %Point @make_point(i32 7, double 2.5)  ; 函数可以按值返回结构体
%buf = alloca %Point
store %Point %pt, ptr %buf                          ; 整个结构体一次性入内存
%y   = call double @point_y(ptr %buf)               ; 经 GEP+load 读字段（见 3.4）
```

## 3.6 不透明指针 ptr：为什么扔掉了类型化指针

LLVM 15 之前，指针带类型（`i32*`、`%Point*`），同一个地址能同时存在 `i32*` 和 `double*` 两种表达，优化器被迫做大量"指针是不是同一个"的猜测。不透明指针改革后：

- 所有指针都是 `ptr`，**读写什么类型由 load/store/GEP 当场声明**；
- `bitcast`（指针位模式转换）基本退役——类型转换发生在**使用处**而非指针本身；
- 别名分析更稳，_address-space 仍保留（`ptr addrspace(1)`，GPU 编程用）。

实战影响两条：读老代码把 `T*` 替换成 `ptr`、`bitcast T*` 直接删掉；写新代码时 load/store 的类型责任在你手上。

## 3.7 类型转换指令

| 指令 | 方向 | 例 |
|---|---|---|
| `trunc` / `zext` / `sext` | 整数↔整数 | `trunc i64 %x to i32`；`zext i32 %x to i64`（零扩展） |
| `sitofp` / `fptosi` | 整数↔浮点 | `sitofp i32 %x to double` |
| `fptrunc` / `fpext` | 浮点↔浮点 | `fptrunc double %x to float` |
| `ptrtoint` / `inttoptr` | 指针↔整数 | 尽量少用（毁掉别名信息） |

没有"C 风格万能转换"——每对类型一个专用指令，转换语义显式且可推理。`zext` vs `sext` 的选择要点：无符号语义用 zext（高位补 0），有符号用 sext（补符号位）。

## 3.8 完整示例与实测输出

`examples/03_ir_types/types.ll` 覆盖：命名结构体、全局数组/常量/可变全局、GEP（数组+结构体字段）、insertvalue、alloca/load/store、trunc、跨类型 printf。运行：

```powershell
& "G:\scoop\apps\msys2\current\ucrt64\bin\lli.exe" examples\03_ir_types\types.ll
```

（实测输出）：

```text
100          ; sum_table(): 10+20+30+40
2.500000     ; make_point(7, 2.5).y 经 GEP+load 读出
3            ; bump() 两次：1+2（i64 计数 trunc 到 i32 打印）
hello        ; 字符串=字节数组，%s 打印
==== 03 ok ====
```

## 3.9 本章小结

- 整数无符号，符号在运算（`icmp s*/u*`、`sdiv/udiv`）；任意位宽合法。
- 聚合类型是字面量，`%T = type` 只是别名；自引用用命名+ptr。
- `global`/`constant` + linkage 四件套（external/private/internal/weak）。
- GEP 三规则：第一索引在聚合外、只算地址不碰内存、逐层按步长走。
- 指针只有 `ptr`；类型在使用处声明；转换一族指令各管一段。

| 坑 | 解法 |
|---|---|
| GEP 第一索引忘写 0 | 全局/单聚合寻址，第一索引就是 0 |
| 结构体字段索引用变量 | 字段索引必须是常量 i32 |
| `constant` 被写入 | UB；要写就 `global` |
| load/store 类型不匹配 | 自己保证——`ptr` 不背类型信息 |
| 老代码 `%Node = type {... %Node*}` | 换 `ptr` |

下一章进入 IR 的灵魂：SSA 与 `phi`。
