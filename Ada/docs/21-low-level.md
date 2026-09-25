# 21 · 低级程序设计与表示子句

> 示例：[`examples/ch21_lowlevel.adb`](../examples/ch21_lowlevel.adb)
> 运行：`./run-all.sh 21`

老教材何诚第 17 章开宗明义：普通 Ada 程序是"与机器无关的抽象描述"，
把描述映射成机器指令是编译器的事；但**实时与嵌入式**程序偶尔要夺回
这个映射的控制权——寄存器长什么样、变量放在哪个地址、某类对象最多
占多少存储。当年管这叫**表示规范说明（representation specification）**，
现代术语是**表示子句 / 表示方面（representation clauses & aspects）**。
张丽芬第 10 章同样以此压轴（含与其它语言接口）。

Ada 敢把这章放进**标准语言**而不是"编译器扩展"，正是它做嵌入式
的底气：同一套语法在 GNAT、在航天器的认证编译器上，语义一致。

---

## 21.1 全景：四类表示控制

| 控制对象 | 老语法（表示子句） | 现代写法（aspect 优先） | 干什么用 |
|----------|-------------------|------------------------|---------|
| 类型大小 | `for T'Size use 16;` | `type T ... with Size => 16` | 限定表示位数 |
| 枚举编码 | `for E use (A => 1, B => 2);` | 同左（无 aspect 形式） | 指定字面量的内部码 |
| 记录布局 | `for R use record ... end record;` | 同左（无 aspect 形式） | 位级摆放分量 |
| 对象地址 | `for X use at 16#F000#;` | `X : T with Address => ...` | 钉住变量位置 |
| 存储配额 | `for P'Storage_Size use 1024;` | 同左（无 aspect 形式） | 限制池/任务栈 |
| 压缩建议 | `pragma Pack (T);` | `with Pack` | 请编译器压缩间隔 |

规矩先立三条：

1. 表示子句**不能与类型定义分开太远**——它属于类型所在的说明部分，
   而且一个类型只许一套表示；
2. 表示子句与可移植性天然对抗——**写下它，你就对布局负责**；
3. `Pack` 与显式布局不同，它是**建议**（编译器尽力压缩），不像
   记录表示子句那样是**命令**。

## 21.2 Size 与 Pack：先管好大小

```ada
type Small is range 0 .. 15 with Size => 4;      -- 4 位足够
type Packed_Bits is array (1 .. 16) of Boolean with Pack;
```

实跑（GNAT 16.2 / x86-64）：

```text
  Small (0..15, Size=>4): Size = 4 位
  16 个 Boolean 打包: Size = 16 位 (未打包则 16x8)
  普通记录 Boolean+Integer: Size = 64 位
  打包记录 Pack:           Size = 33 位
```

要点：`Size` 是"至少要这么小"的**承诺**（编译器必须让赋值、判等
都按这个宽度工作）；`Object'Size` 可能比 `T'Size` 大（对象单独对齐）；
数组配 `Component_Size => 1` 或 `Pack` 才是真正的位数组。

## 21.3 记录表示子句：寄存器位级建模

何诚的 ADC（模数转换器）案例是四十年不变的经典：16 位控制/状态
寄存器，每个位域有名字。三步走——**描述抽象、规定布局、（真实硬件
才有的）钉地址**：

```ada
type Bits_2 is mod 2 ** 2;
type Bits_6 is mod 2 ** 6;

type CSR is
   record
      Enable  : Boolean;     -- 位 0
      Mode    : Bits_2;      -- 位 1..2
      Channel : Bits_6;      -- 位 3..8
      Error   : Boolean;     -- 位 9
   end record
   with Size => 16;

for CSR use
   record
      Enable  at 0 range 0 .. 0;    -- 第 0 个存储单元的位 0
      Mode    at 0 range 1 .. 2;
      Channel at 0 range 3 .. 8;
      Error   at 0 range 9 .. 9;
   end record;
```

`at 单元 range 位` 给每个分量定位；`at mod 2`（本例略）可追加对齐
要求。**验证布局**靠 `Unchecked_Conversion`——两个 `Size` 相同的
类型间"位模式直通"：

```ada
type U16 is mod 2 ** 16;
function To_U16 is new Ada.Unchecked_Conversion (CSR, U16);
function To_CSR is new Ada.Unchecked_Conversion (U16, CSR);
```

实跑输出（数值恰好拼出 "AD"，Ada 的彩蛋）：

```text
  CSR'Size =  16 位
  Enable=True Mode=2 Channel=16#15#  =>  位模式 = 16#AD#
  反向转换 173 => Enable=TRUE, Mode= 2, Channel= 21
```

手算核对：位 0 起**小端编号**（`System.Default_Bit_Order =
LOW_ORDER_FIRST`），`1 + 2×2 + 16#15#×8 = 173 = 16#AD#` ✓。
跨平台寄存器代码常用 `with Bit_Order => High_Order_First,
Scalar_Storage_Order => ...` 强制大端布局，避免依赖本机字节序。

真实设备上还差最后一步——把对象钉在寄存器地址：

```ada
CSR_Reg : CSR with Address => System'To_Address (16#F000_0010#),
                      Volatile,          -- 每次访问都真读真写
                      Import;            -- 外部定义，不初始化
```

（教学示例不能真去戳硬件地址，故以转换验证代替；`Volatile` 阻止
编译器把两次读合并成一次——设备寄存器的值随时会"自己变"。）

## 21.4 枚举表示子句：操作码表

枚举字面量的内部编码也可以钉死——写指令译码器、协议字段时必备：

```ada
type Opcode is (Halt, Load, Store, Add, Sub, Jump);
for Opcode use
  (Halt => 16#00#, Load => 16#10#, Store => 16#20#,
   Add  => 16#30#, Sub  => 16#31#, Jump => 16#F0#);
```

关键在**`'Pos` 与 `'Enum_Rep` 的分野**：

```text
  字面量   Pos  Enum_Rep
  HALT    0     0
  LOAD    1    16
  STORE    2    32
  ADD    3    48
  SUB    4    49
  JUMP    5   240
```

- `'Pos`：语言层面的序号（永远 0..n-1，`for X in E loop` 用的就是它）；
- `'Enum_Rep`：你钉的内部码（进寄存器、上线缆的值）；
- `'Enum_Val (16#31#)`：按内部码反查字面量（本例返回 `SUB`），
  `'Val` 则是按 `'Pos` 反查——两个方向、两套属性，别混。

老教材用 `for BIT use (OFF => 0, ON => 1)` 干的也是这事：
`Boolean` 是预定义类型改不了表示，所以要**自定义** `Bit` 类型
再钉表示——这条理由今天依然成立。

## 21.5 地址覆盖与字节序

`Address` 方面的另一个安全用法：**同一块内存多种视图**（overlay）。

```ada
I : aliased Integer := 16#1234_5678#;
B : Byte_Array with Address => I'Address, Import;   -- 覆盖在 I 上
```

实跑：

```text
  Integer 16#1234_5678# 的字节序:  120  86  52  18
  改 B(0)=0 后 I = 305419776 = 16#1234_5600#
```

120 = 16#78# 在最低地址——x86-64 **小端**实锤；改 `B (0)` 立即
反映到 `I`，因为它们**就是同一块内存**。`Import`（老写法
`pragma Import (Ada, B)`）声明"这对象的初始状态不归我管"，
配合 `Address` 是标准的覆盖惯用法；协议解析、零拷贝视图都靠它。

## 21.6 System 常量与存储配额

`System` 包是"机器的身份证"（老教材 §17.4）：

```text
  Storage_Unit       =  8 位/存储单元
  Word_Size          =  64 位/字
  Default_Bit_Order  = LOW_ORDER_FIRST
  Max_Integer_Size   =  128 位
```

（`Min_Int`/`Max_Int` 按 `Max_Integer_Size` 定义成 128 位
universal 常量——直接塞 64 位 Integer 会编译期溢出，本示例
特意踩了一遍。）

**`Storage_Size` 配额**是老教材 §17.3 的重头：给访问类型的存储池
（或任务类型的栈）限粮，让"内存泄漏"变成可捕获的异常而不是慢慢
吃光系统：

```ada
type Node is record A, B : Integer; end record;      -- 8 字节
type Node_Ptr is access Node;
for Node_Ptr'Storage_Size use 24;                    -- 只给 3 个的量
```

实跑：

```text
  Node_Ptr'Storage_Size =  24 字节（Node 本体 8 字节 x 3）
  装到第  4 个触发 Storage_Error —— 池满了
```

第 4 次 `new` 抛 `Storage_Error`——在内存受限的嵌入式目标上，
这正是"声控故障边界"的正确姿势（配额计算见老教材公式：
`个数 × (T'Size / System.Storage_Unit)`，实际可用会因簿记略少）。
任务栈同理：`for T'Storage_Size use 10000` 给任务类型的工作区
定量。

## 21.7 中断（概念性一节）

老教材把中断入口写成 `for INTERRUPT use at 8#340#;`——把设备
中断向量"接"到任务入口上，硬件触发即完成一次会合。现代 GNAT
的等价物是 Annex D 的标准 pragma：

```ada
with System;
task Adc_Driver is
   entry Read (Ch : Channel; Value : out Integer);
   entry Interrupt;
   for Interrupt'Address use System.Interrupt_Reference (...);
   pragma Attach_Handler (Interrupt, Some_Interrupt_Id);
end Adc_Driver;
```

需要运行时与目标机的中断支持，教学环境跑不了——但骨架与何诚
§17.2 的 `ADC_DRIVER` 一致：驱动任务在 `accept Read` 里启动转换，
内嵌 `accept Interrupt` 等硬件"回调"，[17 章](17-select-family.md)
的会合家族到这里就是设备驱动本体。GNAT 用户级近似可玩
`pragma Interrupt_Handler` + 信号（如 SIGINT），此处点到为止。

## 21.8 常见坑

1. **改预定义类型的表示**：`for Boolean use ...` 编译不过——
   只能对自定义类型钉表示（老教材 `Bit` 类型的存在理由）。
2. **`Size` 钉太紧**：`Size => 4` 而范围要求 5 位 → 编译错误；
   表示子句必须"装得下所有值"。
3. **布局与转换不同宽**：`Unchecked_Conversion` 两侧 `Size`
   不一致是未定义行为——先 `with Size => 16` 钉宽，再转换。
4. **忘 `Volatile`**：覆盖设备寄存器的对象不加 `Volatile`，
   编译器可能合并/删除重复读——优化器没错误，是你的声明错了。
5. **位序想当然**：`range 0 .. 0` 在小端机器是最低位；
   写跨平台寄存器代码时显式 `Bit_Order` + `Scalar_Storage_Order`。
6. **`'Pos` 当 `'Enum_Rep` 用**：译码器发出 `1` 想找 `LOAD`，
   实际 `'Pos=1` 是 `LOAD` 恰好对上、`'Pos=2` 是 `STORE` 但
   `Enum_Rep` 是 16#20#——两套编号只在"没钉表示"时重合。

## 21.9 小结

| 工具 | 一句话 |
|------|--------|
| `Size` / `Pack` / `Component_Size` | 控宽与压缩 |
| 记录表示子句 `at .. range ..` | 位级摆放，寄存器建模 |
| 枚举表示 + `'Enum_Rep`/`'Enum_Val` | 指令码/协议字段编码 |
| `Address` + `Import` + `Volatile` | 钉地址、覆盖、防优化 |
| `Unchecked_Conversion` | 同宽类型间位模式直通 |
| `Storage_Size` | 池/栈配额，`Storage_Error` 兜底 |
| `System` 常量 | 机器参数，写可移植的低级代码 |

Ada 的低级设施不是"逃生舱"而是**受管控的下降**：每一步下沉
都有类型系统陪同——这正是它与 C 内联汇编路线的根本区别。
[20 章](20-c-interop.md) 讲怎么和 C 握手，本章讲怎么和硬件握手，
两章合起来就是嵌入式 Ada 的全部地基。

---

### 习题（改编自何诚第 17 章）

1. 何诚的完整 ADC_CSR（错误/通道/中断允许/外部启动/启动，含
   跨字节位域 `at 1 range 0..5`）：按 PDP-11 布局建模并验证
   `(Chan => 5, Intr_Enable => True)` 的位模式。
2. 给 21.3 的 `CSR` 加一个"只读状态"视图：再定义一个分量重合、
   但只含 `Error`/`Channel` 的记录类型，用 `Address` 覆盖到同一
   寄存器对象上，体会"控制视图/状态视图"分离。
3. 把 `Node_Ptr'Storage_Size` 改成刚好 2 个节点，捕获
   `Storage_Error` 后释放一个节点（`Unchecked_Deallocation`），
   再分配成功——写出"配额内自愈"的骨架。
4. 写一个 12 位压缩 BCD 计数器：`type BCD is mod 2 ** 12 with
   Component_Size => 4`（数组版），实现 +1 跳过 16#0A#..16#0F#
   的非法码。

---
上一章：[20 与 C 语言互操作](20-c-interop.md) ｜ 下一章：[22 定点与十进制实数](22-fixed-point.md) ｜ 返回：[README](../README.md)
