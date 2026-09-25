# 09 · 访问类型与动态数据结构

> 示例：[`examples/ch09_access.adb`](../examples/ch09_access.adb)
> 运行：`./run-all.sh 09`

老教材术语"存取类型"（何诚第 11 章）/"访问数据类型"（刘炳文第 12 章），
现代统一叫**访问类型（access type）**，其值就是俗称的指针。Ada 的指针比 C 的
指针约束多得多：类型系统从头管到尾——但正因为如此，`new` 出来的链表、树
这些动态结构在 Ada 里可以做到**类型安全 + 内存可控**。

---

## 09.1 为什么需要动态分配

老教材的动机分析（何诚 §11.1）今天依然成立。静态分配的对象有两个死穴：

1. **大小必须先知道**。要从文件读数量未知的人名，只能"猜一个上界"开数组——
   猜大了浪费，猜小了程序崩。
2. **结构固定**。数组里元素的关系由下标焊死，想把首元素挪到尾部，
   只能把整块数据复制来复制去。

动态分配 + 访问类型把"数据在哪"和"数据多大"都推迟到运行期决定，
元素之间的关系变成**运行期可改的链接**。本章的三个数据结构
（链表、树、函数表）覆盖了老教材的核心案例。

## 09.2 基本概念：访问值、null 与分配符

```ada
type Node;                      -- ① 不完整类型说明（前向引用）
type Node_Ptr is access Node;   -- ② 访问类型：值指向 Node 对象

type Node is
   record
      Name : String (1 .. 6);
      Next : Node_Ptr;          -- ③ 完整定义里用回去（初值 null）
   end record;
```

三步缺一不可：`Node` 的字段里有 `Node_Ptr`，`Node_Ptr` 又指向 `Node`——
互相引用只能靠①先"占名"。访问类型的值集初始只有一个 **`null`**
（不指向任何对象），每个说明出来、没显式赋初值的访问对象都是 `null`。

**分配符 `new`** 像一个带副作用的函数：在堆上造对象、返回指向它的访问值：

```ada
P := new Node'("GEORGE", null);        -- 分配 + 聚集初始化
Q := P;                                 -- Q、P 指向同一对象
Q.Name := "RUPERT";                     -- 经 Q 改，P 看得见
P.all := ("ALICE ", null);              -- .all：整个被指对象赋值
```

**`.` 与 `.all` 的分工**（老教材讲得最细的地方）：

| 写法 | 含义 |
|------|------|
| `P := Q` | 复制**访问值**（两个名字指同一对象） |
| `P.all := Q.all` | 复制**被指对象的内容**（两块独立数据变相同） |
| `P.Name` | 被指对象的分量——访问类型自己没有分量，直接穿透 |
| `P.Next.Next` | 链式穿透：走两步 |

一个对象失去所有访问路径后（比如 `P := null` 前忘了复制）就**丢失**了：
Ada 不保证自动回收（见 09.6）。丢失 ≠ 立即释放，但你也再摸不到它。

## 09.3 实战一：单链表（老教材 BUILD_LIST）

建表用"头尾双指针 + 尾插法"，这是老教材手把手画了四张指针图的经典算法：

```ada
procedure Append (Head, Tail : in out Node_Ptr; Name : String) is
   Temp : constant Node_Ptr :=
     new Node'(Name (Name'First .. Name'First + 5), null);
begin
   if Head = null then
      Head := Temp;              -- 空表：头即尾
   else
      Tail.Next := Temp;         -- 接到尾部
   end if;
   Tail := Temp;
end Append;
```

老教材的"把第一项移到表尾"练习——三条指针赋值、**零数据复制**，
这就是链接结构对数组复制法的降维打击：

```ada
Temp      := Head;
Head      := Head.Next;
Temp.Next := null;
Tail.Next := Temp;
Tail      := Temp;
```

实跑输出（`./run-all.sh 09`）：

```text
--- 2. 单链表：建表与重排 ---
  原表:     [GEORGE] ->   [FRED  ] ->   [RITA  ]
  重排后:   [FRED  ] ->   [RITA  ] ->   [GEORGE]
```

## 09.4 实战二：二叉查找树（刘炳文 §12.8）

`access` 自引用天然适合树——左儿子、右儿子各是一个指针：

```ada
type Tree;
type Tree_Ptr is access Tree;

type Tree is
   record
      Value : Integer;
      Left, Right : Tree_Ptr;
   end record;

procedure Insert (T : in out Tree_Ptr; V : Integer) is
begin
   if T = null then
      T := new Tree'(Value => V, Left => null, Right => null);
   elsif V < T.Value then
      Insert (T.Left, V);        -- 递归下降
   elsif V > T.Value then
      Insert (T.Right, V);
   end if;                       -- 相等忽略：集合语义
end Insert;
```

中序遍历（左-根-右）输出必有序——插入序列 50,30,70,20,40,60,80，
遍历得到 `20 30 40 50 60 70 80`。

## 09.5 访问判别记录与访问子程序

**new 判别记录时必须同时定形**（老教材 §11.6）。堆上对象不能"先分配后变体"——
`new Vehicle` 不带约束是编译错误，要么写判别式约束、要么用带判别式的聚集：

```ada
type V_Ptr  is access Vehicle;             -- 指向任意变体
type VC_Ptr is access Vehicle (K => Van);  -- 只准指向 Van 对象（受约束访问类型）

C : V_Ptr := new Vehicle'(K => Car, Serial => 101, Doors => 4);
V : V_Ptr := new Vehicle'(K => Van, Serial => 102, Load  => 5);
C := V;      -- 合法：V_Ptr 无约束，可改指另一变体
-- W := C;   -- 编译错误：C 可能指 Car，W 的类型不允许
```

**访问子程序**（Ada 83 没有的现代设施）把"函数指针"也纳入强类型：

```ada
type Binary_Op is access function (L, R : Integer) return Integer;

Ops : array (1 .. 2) of Binary_Op := (Add'Access, Mul'Access);
Put_Line (Integer'Image (Ops (1) (6, 7)));   -- 13
Put_Line (Integer'Image (Ops (2) (6, 7)));   -- 42
```

回调、调度表、策略模式，都靠它——不需要 C 那种 `void*` 裸奔。

## 09.6 手动回收：`Unchecked_Deallocation`

Ada **没有全称垃圾回收**。动态对象的生存期上界是访问类型的作用域
（离开作用域后整批回收），但作用域内的"提前丢"要自己管——
标准库给了一个泛型，实例化出类型安全的 Free：

```ada
with Ada.Unchecked_Deallocation;

procedure Free is new Ada.Unchecked_Deallocation
  (Object => Node, Name => Node_Ptr);
...
Free (P);       -- 回收 P 指向的对象，P 变为 null
```

名字里带 **Unchecked** 是诚实的：释放后所有别名全部悬空，语言不查。
配套纪律（本示例代码即示范）：

1. **谁分配谁释放**，Free 后立刻置空（Free 已把实参置 null）；
2. 别名存在期间绝不 Free；
3. 整表/整树回收用循环/递归逐节点 Free（`Free_List` / `Free_Tree`）；
4. 大对象或性能敏感路径，考虑用受控类型（`Ada.Finalization`）自动析构，
   或 [23 章](23-containers.md) 的标准容器——它们把这些坑都填好了。

老教材 §11.7 还讲了按访问类型控制存储配额（今天写作 `for Node_Ptr'Storage_Pool use ...`
或 `Storage_Size` 表示子句），嵌入式项目里限制某类节点的总内存，
思路至今在用，细节见 [21 章](21-low-level.md)。

## 09.7 一般访问类型：`access all` 与 `'Access`

上面所有访问类型只能指向 **new 出来的堆对象**。指向**已存在的普通对象**
（栈上、静态区）需要**一般访问类型**：

```ada
declare
   type Int_Access is access all Integer;   -- all：也允许指向静态对象
   X : aliased Integer := 5;                -- aliased：允许取访问值
   P : Int_Access := X'Access;              -- 'Access：取别名
begin
   P.all := 42;                             -- 经别名改原对象
end;
```

三条配套规则：

- 目标对象必须标 `aliased`（明示"我会被指"）；
- **可访问性检查**：访问类型的声明级别不得比对象浅——
  `P : Int_Access := X'Access` 若类型在外面、X 在里层，直接编译错误
  （`non-local pointer cannot point to local object`，本示例特意踩过）；
  这条规则在编译期消灭了 C 里最经典的"返回局部变量指针"悬空 bug；
- 还有 `access constant`（只许读被指对象）与子程序版 `access procedure/
  function` 的 `'Access`，配套同一套可访问性检查。

## 09.8 常见坑

1. **忘写不完整类型说明**：`type Node; type Node_Ptr is access Node;`
   两行必须在前，完整定义随后——顺序错了编译不过。
2. **`new` 判别记录不带约束**：`new Vehicle` 编译错误；
   `new Vehicle'(K => Van, ...)` 或 `new Vehicle (K => Van)` 二选一。
3. **悬空别名**：`Q := P; Free (P);` 之后 Q 是悬空的——纪律问题，
   语言无解；用受控类型或容器回避。
4. **Free 参数不匹配**：实例化 `Unchecked_Deallocation` 时
   `Name` 必须是"指向该 Object 类型的访问类型"，一种节点一个实例。
5. **可访问性**：内层对象取 `'Access` 赋给外层声明的访问类型——
   编译错误（这是特性不是缺陷）。
6. **`P.Name` 还是 `P.all.Name`**：都对，前者是惯用简写；
   只有整对象赋值才必须 `P.all := ...`。
7. **参数模式**：要在过程里改指针本身（如 `Insert (T.Root, ...)`），
   形参必须 `in out`——只传访问值不改指向时 `access` 参数模式更高效
   （`procedure P (N : access Node)`，只读可用 `not null access constant Node`）。

## 09.9 小结

| 概念 | 语法 | 一句话 |
|------|------|--------|
| 访问类型 | `type P is access T;` | 类型安全的指针 |
| 不完整说明 | `type T;` | 自引用结构的敲门砖 |
| 分配符 | `new T'(...)` | 堆上建对象，返回访问值 |
| 解引用 | `P.all` / `P.Comp` | 整对象 / 穿透分量 |
| 手动回收 | `new Ada.Unchecked_Deallocation` | 实例化出类型安全的 Free |
| 受约束访问 | `access Vehicle (K => Van)` | 指针也带判别式约束 |
| 访问子程序 | `access function ...` | 强类型函数指针 |
| 一般访问 | `access all` + `'Access` | 指向静态对象，编译期查悬空 |

下一章回到模块化：把这些类型和结构装进**包**里对外服务。

---

### 习题（改编自何诚第 11 章、刘炳文第 12 章）

1. 把单链表改成**双向链表**（增加 `Prev : Node_Ptr`），
   `Append` / `Print_List` / `Free_List` 全部同步改造。
2. 何诚 §11.8 的交叉引用生成器：读入一段程序文本，为每个标识符记录
   它出现的行号集合。用"标识符链表 + 行号链表"两级动态结构实现，
   最后按字典序输出 `标识符: 行1 行2 ...`。
3. 给二叉查找树加 `function Contains (T : Tree_Ptr; V : Integer)
   return Boolean` 与 `function Depth (T : Tree_Ptr) return Natural`，
   再写一个按层打印（提示：访问值数组当队列）。
4. 把 `Binary_Op` 扩展成带环境的闭包：记录里放一个 `Binary_Op`
   和一个 `Integer` 偏移量，实现"加偏移""乘倍数"两个策略并打印结果。

---
上一章：[08 判别类型](08-discriminants.md) ｜ 下一章：[10 包与模块化编程](10-packages.md) ｜ 返回：[README](../README.md)
