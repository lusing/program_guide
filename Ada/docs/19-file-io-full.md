# 19 · 文件 I/O 全景：顺序、直接与流

> 示例：[`examples/ch19_files.adb`](../examples/ch19_files.adb)
> 运行：`./run-all.sh 19`

[18 章](18-file-io.md)的 `Ada.Text_IO` 解决"人读得懂"的文本；
本章解决"机器读得快"的数据文件。老教材何诚第 15 章把它分成两个
预定义包：`INPUT_OUTPUT`（紧凑机器格式）与 `TEXT_IO`（人可读格式）。
四十多年过去，`INPUT_OUTPUT` 演化成一个泛型家族，思路原封未动：

| 老教材（Ada 83） | 现代 Ada | 特点 |
|-----------------|----------|------|
| `INPUT_OUTPUT` 的顺序访问 | `Ada.Sequential_IO` | 定长元素，从头到尾 |
| `INPUT_OUTPUT` + `SET_READ`/`SET_WRITE` | `Ada.Direct_IO` | 定长元素，按序号随机跳 |
| ——（83 没有对应物） | `Ada.Streams.Stream_IO` | 异构混装、带边界标签 |

---

## 19.1 Sequential_IO：泛型实例化出来的顺序文件

`Sequential_IO` 是泛型包，**先实例化再使用**——元素类型是类型参数：

```ada
with Ada.Sequential_IO;
...
package Employee_IO is new Ada.Sequential_IO (Employee);
...
F : Employee_IO.File_Type;
Employee_IO.Create (F, Employee_IO.Out_File, "ch19_emp.bin");
Employee_IO.Write (F, (1, "Ada     ", 5000));
Employee_IO.Close (F);
```

`Write` 把记录按**机器内部表示**原样落盘（不转字符），读回用
`Read`，循环判尾用 `End_Of_File`——与 `Text_IO` 的 `Get/Put` 家族
同构，但元素类型任意、内容紧凑、无需解析。

```ada
Employee_IO.Open (F, Employee_IO.In_File, "ch19_emp.bin");
while not Employee_IO.End_Of_File (F) loop
   Employee_IO.Read (F, E);
   Put_Emp (E);
end loop;
Employee_IO.Close (F);
```

实跑输出：

```text
--- 2. 记录顺序文件 ---
  全部记录:
    # 1 Ada      工资 5000
    # 2 Grace    工资 6500
    # 3 Barbara  工资 5800
```

## 19.2 Direct_IO：随机存取

老教材用 `SET_READ (F, I)` + `READ (F, ITEM)` 两步走；现代语法把
位置并进了调用——`Read` / `Write` 带上 `From` / `To` 参数：

```ada
package Employee_DIO is new Ada.Direct_IO (Employee);
...
Employee_DIO.Create (F, Employee_DIO.Inout_File, "ch19_direct.bin");
Employee_DIO.Write (F, (1, "Ada    ", 5000), To => 1);   -- 写 1 号位
Employee_DIO.Write (F, (2, "Grace  ", 6500), To => 2);
Employee_DIO.Write (F, (3, "Barbara", 5800), To => 3);

Employee_DIO.Read (F, E, From => 2);      -- 直取 2 号，不经顺序扫描
Employee_DIO.Write (F, (2, "Grace  ", 7000), To => 2);   -- 原地改写
```

配套的状态查询：

| 子程序 | 含义 |
|--------|------|
| `Size (F)` | 文件元素个数（老教材的 `LAST`） |
| `Index (F)` | 当前读写位置（老教材的 `NEXT_READ`/`NEXT_WRITE` 合一） |
| `Set_Index (F, To)` | 显式跳位（老教材的 `SET_READ`/`SET_WRITE`） |

`Inout_File` 模式是 Direct_IO 的招牌（Sequential_IO 没有它）：一个
打开的文件既读又写。写到超出末尾的位置会自动扩容文件——
老教材"追加 = `SET_WRITE (F, LAST (F) + 1)`"的老招数，
今天直接 `Write (F, Item, To => Size (F) + 1)`。

**Direct_IO 的元素必须是定长的**：记录里放 `String (1 .. 8)` 没问题，
放无约束 `String` 不行（要跳转就得知道每格多大）。变长数据用下一节。

## 19.3 Stream_IO 与流属性

`Ada.Streams.Stream_IO` 把文件抽象成**字节流**，读写靠每个类型都
有的四个**流属性**：

| 属性 | 读/写 | 行为 |
|------|-------|------|
| `T'Output (S, X)` | 写 | 写边界/标签 + 全部内容 |
| `T'Input (S)` | 读 | 按标签还原对象 |
| `T'Write (S, X)` | 写 | 只写内容（不管边界） |
| `T'Read (S, X)` | 读 | 只读内容（调用方自备形状） |

```ada
package SIO renames Ada.Streams.Stream_IO;
...
SIO.Create (F, SIO.Out_File, "ch19_stream.bin");
Integer'Output  (SIO.Stream (F), 42);               -- 整数
String'Output   (SIO.Stream (F), "Ada 2022");       -- 串（界+内容）
Employee'Output (SIO.Stream (F), (7, "Lovelace", 9000));
SIO.Close (F);

SIO.Open (F, SIO.In_File, "ch19_stream.bin");
N   := Integer'Input  (SIO.Stream (F));
Got := String'Input   (SIO.Stream (F));             -- 界自动还原
R   := Employee'Input (SIO.Stream (F));
```

**这是与 Sequential_IO 的本质区别**：`'Output`/`'Input` 自带类型
边界信息（无约束 `String` 的长度也存进去），所以**一个文件可以混装
异构数据**——序列化、持久化、跨进程交换数据的正解。
`'Write`/`'Read` 是裸版（你自己管格式），适合性能敏感的批量场景。

老教材时代的"高级输入输出异常"（`Status_Error`、`Mode_Error`、
`Name_Error`、`Use_Error`、`Device_Error`、`End_Error`、`Data_Error`）
全部沿用至今，`Data_Error` 在机器格式文件里读出不一致数据时抛出。

## 19.4 案例：二路归并有序文件

张丽芬《导论》的文件合并是顺序文件的经典应用：两份**已排序**的
数据文件合成一份，磁盘时代的外排序就是这么干的。

```ada
Int_IO.Read (A, Xa);                       -- 各取队首
Int_IO.Read (B, Xb);
loop
   if Xa <= Xb then
      Int_IO.Write (C, Xa);                -- 小者出队
      if Int_IO.End_Of_File (A) then
         Int_IO.Write (C, Xb);             -- A 到底：B 手上元素先落盘
         exit;                             -- B 的残余由下面统一倾泻
      end if;
      Int_IO.Read (A, Xa);
   else
      Int_IO.Write (C, Xb);
      if Int_IO.End_Of_File (B) then
         Int_IO.Write (C, Xa);
         exit;
      end if;
      Int_IO.Read (B, Xb);
   end if;
end loop;
while not Int_IO.End_Of_File (A) loop      -- 倾泻残余（其中一方必空）
   Int_IO.Read (A, Xa);
   Int_IO.Write (C, Xa);
end loop;
while not Int_IO.End_Of_File (B) loop
   Int_IO.Read (B, Xb);
   Int_IO.Write (C, Xb);
end loop;
```

实跑：

```text
  ch19_a.bin: 1  4  7  9  13
  ch19_b.bin: 2  3  8  15
  ch19_merged.bin: 1  2  3  4  7  8  9  13  15
```

尾处理是这段代码唯一的难点：循环退出时**手上还捏着对方的队首元素**
（它比刚写走的那个大、又没轮到出队），必须先落盘再倾泻残余——
本示例第一版就栽在这里（末尾 13 写了两次），单步跟踪一遍
`exit` 时刻的 `Xa`/`Xb` 状态是值得做一次的练习。

## 19.5 选型速查

| 需求 | 用什么 |
|------|--------|
| 人读的文本 | `Ada.Text_IO`（18 章） |
| 同种定长记录、顺序扫描日志式追加 | `Sequential_IO` |
| 数据库式按号存取、原地改写 | `Direct_IO` |
| 混装类型 / 变长数据 / 序列化 | `Stream_IO` + `'Input`/`'Output` |
| 批量裸数据（自己管格式） | `Stream_IO` + `'Read`/`'Write` |

## 19.6 常见坑

1. **多实例 use 撞名**：`Sequential_IO` 实例之间、与 `Text_IO` 之间
   都有 `File_Type` / `Out_File` / `In_File` 同名——多个 `use` 直接
   "is not visible / multiple use clauses cause hiding"。
   惯用法：**不 use 实例，全程 `实例名.操作`**（本示例即如此；
   也可在只涉及一个实例的局部块里 use）。
2. **Create 不带名字**：临时文件用法（老教材"隐含文件"），
   `Close` 后无名文件直接消失——想留档必须给名字。
3. **Direct_IO 元素不定长**：无约束 `String` / 判别记录做元素
   编译不过（不定长没法算跳转偏移）。
4. **忘了 Close**：文件句柄耗尽 + 缓冲可能没落盘。异常路径也要
   保证 Close（`exception` 分支里或受控包装）。
5. **Stream 的 `'Input` 乱序读**：流属性必须按写入的**顺序与类型**
   读回——没有类型魔棒，写 `Integer'Output` 读 `String'Input`
   得到的是垃圾。
6. **运行目录**：相对路径以**进程工作目录**为基准；`run-all.sh`
   统一在 `build/` 下运行，所以示例文件都生成在那里。

## 19.7 小结

三个包三板斧：**顺序**（Sequential_IO，从头到尾）、**随机**
（Direct_IO，按号跳转）、**流**（Stream_IO，异构混装）。加上
18 章的 Text_IO，Ada 的"高级 I/O"全谱系就齐了——低级的设备级 I/O
（地址映射、端口）属于 [21 章](21-low-level.md) 的领域。

---

### 习题（改编自何诚第 15 章、张丽芬第 3 章）

1. 给员工文件加"按工号查找"：Sequential_IO 版（全扫）与
   Direct_IO 版（工号即记录号）各写一个，对比代码量与读盘次数。
2. 何诚 §15.11 的交叉引用生成器：输入一份源文件，输出
   "标识符 行号1 行号2 ..." 的有序表——用顺序文件存中间结果。
3. 把二路归并推广成 **k 路归并**：k 个输入文件，败者树选当前最小
   （提示：数组下标模拟树）。
4. 用 `Stream_IO` 实现一个简易"存档"格式：文件头写魔数与版本号
   （`Integer'Output`），随后混装 3 种记录，读回时按版本分支兼容。

---
上一章：[18 文件 I/O](18-file-io.md) ｜ 下一章：[20 与 C 语言互操作](20-c-interop.md) ｜ 返回：[README](../README.md)
