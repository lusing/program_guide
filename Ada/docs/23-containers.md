# 23 · 标准容器库：Ada.Containers

> 示例：[`examples/ch23_containers.adb`](../examples/ch23_containers.adb)
> 运行：`./run-all.sh 23`

老教材第九章用泛型造出了通用栈（STACK_G）与集合——"写一个模板，
按需实例化"。这个思想在 2005 年被收进标准库：**Ada.Containers**
家族提供了向量、链表、哈希表、有序表、栈、队列、树……全部经过
验证、全部线程安全可选（` indefinite` 变体、稳定视图）。本章
走读四个主力——`Vectors`、`Doubly_Linked_Lists`、`Hashed_Maps`、
`Ordered_Sets`，讲透两个通用机制：**实例化**（第 12 章泛型的
兑现）与**游标（cursor）遍历**。

---

## 23.1 实例化：容器是泛型

用任何容器前，先为你的元素类型实例化（老教材 STACK_G 的
`is new` 一模一样）：

```ada
package Int_Vectors is new Ada.Containers.Vectors
  (Index_Type   => Positive,
   Element_Type => Integer);

package Int_Lists is new Ada.Containers.Doubly_Linked_Lists
  (Element_Type => Integer);

package String_Int_Maps is new Ada.Containers.Indefinite_Hashed_Maps
  (Key_Type        => String,           -- 不定长键 → Indefinite 变体
   Element_Type    => Integer,
   Hash            => Ada.Strings.Hash,
   Equivalent_Keys => "=");

package Int_Sets is new Ada.Containers.Ordered_Sets
  (Element_Type => Integer);
```

三个选择要点：

- **Map 的键是不定长 String** 时用 `Indefinite_Hashed_Maps`
  （普通的 `Hashed_Maps` 要求键是定长的——definite 类型）。
- 哈希容器要**注入 `Hash` 函数**（子程序形参！第 12 章 12.4 的
  知识），字符串直接给 `Ada.Strings.Hash`；整数键可以用
  `Ada.Containers.Hash_Type (Key)` 自己写。
- 有序容器（`Ordered_Sets`/`Ordered_Maps`）要注入 `" < "`——
  实例化后**遍历顺序即排序顺序**，这是与哈希版的本质区别。

实例化之后，`Int_Vectors.Vector` 是一个类型：对象说明、参数
传递、赋值（值语义，容器整体拷贝）全部正常。

## 23.2 Vector：动态数组

尾部追加均摊 O(1)、按下标随机访问 O(1)——默认选择。

```ada
V : Int_Vectors.Vector;
...
V.Append (10);
V.Append (30);
V.Append (40);
V.Insert (Before => 2, New_Item => 20);   -- 中间插入
V.Prepend (5);                            -- 头部插入
```

**两种遍历**——值遍历与游标遍历：

```ada
Put ("  内容 (for of 值遍历): ");
for E of V loop                           -- 值遍历：Ada 2012
   Put (E, Width => 0);
   Put (" ");
end loop;

Put ("  游标遍历（带下标）  : ");
for C in V.Iterate loop                   -- 游标遍历：能查位置
   Put (Int_Vectors.Element (C), Width => 0);
   Put ("@");
   Put (Int_Vectors.To_Index (C), Width => 0);
   Put (" ");
end loop;
```

- `for E of V`：拿**元素值**——只看数据的场合，最短最清晰。
- `for C in V.Iterate`：拿**游标（cursor）**——容器的"位置把手"，
  能 `Element (C)` 取值、`To_Index (C)` 换下标、`Next (C)` 前进、
  与 `Find` 的结果比较……**需要位置信息的场合必须用它**。

删改与端点：

```ada
V.Delete_Last;
Put_Line ("  Delete_Last 后 Length =" & Integer'Image (Integer (V.Length)));
Put_Line ("  First/Last =" & Integer'Image (V.First_Element)
          & "/" & Integer'Image (V.Last_Element));
```

```text
  内容 (for of 值遍历): 5 10 20 30 40
  游标遍历（带下标）  : 5@1 10@2 20@3 30@4 40@5
  Delete_Last 后 Length = 4
  First/Last = 5/ 30
```

注意 `Length` 返回 `Count_Type`（Ada.Containers 的专用无符号
类型），打出来要显式转 `Integer`。第 06 章的定长数组掌握后，
Vector 就是"长度随需要长"的数组——但记住它**没有分片（slice）**，
要窗口用 `Copy` 出子向量。

## 23.3 Doubly_Linked_List：双向链表

两端 O(1)、中间插入删除 O(1)（拿着游标时）、**逆向遍历**是
链表的招牌：

```ada
L : Int_Lists.List;
...
L.Append (100);
L.Append (200);
L.Prepend (50);
L.Append (300);

Put ("  逆向: ");
for C in reverse L.Iterate loop           -- 链表的天然强项
   Put (Int_Lists.Element (C), Width => 0);
   Put (" ");
end loop;
```

查找与删除：

```ada
Put_Line ("  Contains 200 :" & Boolean'Image (L.Contains (200)));
declare
   -- Delete 的游标参数是 in out：必须先存进变量
   Pos : Int_Lists.Cursor := L.Find (200);
begin
   L.Delete (Pos);                        -- 删除后 Pos 变 No_Element
end;
Put_Line ("  Delete (Find (200)) 后 Contains 200 :"
          & Boolean'Image (L.Contains (200)));
```

```text
  正向: 50 100 200 300
  逆向: 300 200 100 50
  Contains 200 :TRUE
  Delete (Find (200)) 后 Contains 200 :FALSE
```

**实测坑**：`L.Delete (L.Find (200))` 编译不过——`Delete` 的
游标参数是 `in out` 模式（删除后游标要更新成"无位置"），
函数调用结果不是变量。先存进 `Pos` 变量再传。这是容器 API
"游标是状态"哲学的自然推论：游标会动，所以必须是变量。

选型：频繁头尾进出（队列原型、撤销栈）选链表；随机访问选
Vector。判据是**访问模式**不是"高级感"。

## 23.4 Hashed_Map：键 → 值

```ada
M : String_Int_Maps.Map;
...
M.Insert ("Alice", 25);
M.Insert ("Bob", 30);
M.Insert ("Carol", 35);

Put_Line ("  M (""Bob"") = " & Integer'Image (M ("Bob")));
```

Map 支持函数式下标：`M ("Bob")` 直接取值（Ada 2012 的
`Constant_Indexing`）。**键不存在时下标会引发异常**——先查后取
用 `Contains`，或无异常版 `Element` 判 Cursor。

`Insert` 与 `Include` 的语义差异（本章实测坑）：

- `Insert (Key, Val)`：键**已存在则引发 Constraint_Error**——
  "插入就是插入，重复是错误"；
- `Include (Key, Val)`：键在则**覆盖**、不在则插入——"upsert"。

```ada
M.Include ("Bob", 31);                    -- 键存在则覆盖
Put_Line ("  Include (""Bob"", 31) 后 M (""Bob"") ="
          & Integer'Image (M ("Bob")));   -- 31
```

手写游标走哈希表：

```ada
C := M.First;
while String_Int_Maps.Has_Element (C) loop
   Put_Line ("    " & String_Int_Maps.Key (C) & " → "
             & Integer'Image (String_Int_Maps.Element (C)));
   String_Int_Maps.Next (C);              -- Next 的 C 是 in out
end loop;
```

```text
  游标遍历（哈希序，与插入序无关）:
    Carol →  35
    Bob →  31
    Alice →  25
```

**哈希序**取决于 `Hash` 函数与桶布局，与插入顺序无关、跨实现
不保证一致——要"按序"就选 `Ordered_Maps`。`while + Next` 的
手写循环与 `for C in M.Iterate` 等价，前者便于在循环中间做
复杂控制流。

## 23.5 Ordered_Set：有序集合

```ada
S : Int_Sets.Set;
...
S.Insert (5);
S.Insert (3);
S.Insert (8);
S.Insert (1);
-- 注意：Insert 重复元素会引发 Constraint_Error！
-- Include 才是"键在则替代、不在则插入"的宽容版本
S.Include (3);                            -- 已在集合中：静默无事

Put ("  插入 5,3,8,1 + Include (3) 后（有序去重）: ");
for E of S loop                           -- 遍历顺序 = 升序
   Put (E, Width => 0);
   Put (" ");
end loop;
```

```text
  插入 5,3,8,1 + Include (3) 后（有序去重）: 1 3 5 8
  Length = 4（3 只算一次）
  Ceiling (4) = 5（第一个 >= 4 的元素）
```

三个看点：

1. **遍历即有序**——插入 5,3,8,1 出来就是 1 3 5 8。顺序查询、
   范围处理的天然工具。
2. **重复 Insert 抛异常**（与 Map 的 Insert 一致），`Include`
   才是幂等版本。本节演示两种语义各一次。
3. `Ceiling (4)`：第一个 ≥ 4 的元素。配套还有 `Floor`（≤）、
   `Lower/Upper_Bound`——集合版二分查找，O(log N)。

老教材 §9.4 的"集合"泛型包提供 Insert/Member/Empty 一类操作；
Ordered_Sets 是它的全功能后代——加上了有序遍历、范围查询、
集合运算（`Union`/`Intersection`/`Difference` 直接两个 Set 运算）。

## 23.6 家族速览与选型

本章只走了四位主力，全家福（`Ada.Containers.*`）按需求选：

| 容器 | 结构 | 何时选 |
|------|------|--------|
| `Vectors` | 动态数组 | 随机访问、尾追加 |
| `Doubly_Linked_Lists` | 双向链表 | 两端进出、频繁中间增删 |
| `Hashed_Maps` / `Ordered_Maps` | 键值表 | O(1) 查找 / 按序遍历 |
| `Hashed_Sets` / `Ordered_Sets` | 集合 | 去重、成员测试 / 有序去重 |
| `Bounded_Doubly_Linked_Lists` | 有界链表 | 无堆分配（嵌入式） |
| `Multiway_Trees` | 多路树 | 层次结构（文件系统、XML） |
| `Indefinite_Holders` | 单值盒子 | 给不定长类型做容器元素 |

两条通用军规：**`Indefinite_` 前缀**的变体接受不定长元素
（String、class-wide）；**容器赋值是深拷贝**（值语义），
共享要用 `holder`/访问类型，没有"引用语义容器"。

## 23.7 本章示例的完整输出

```text
=== Ada 标准容器库 ===

--- 1. Vector ---
  内容 (for of 值遍历): 5 10 20 30 40
  游标遍历（带下标）  : 5@1 10@2 20@3 30@4 40@5
  Delete_Last 后 Length = 4
  First/Last = 5/ 30

--- 2. Doubly_Linked_List ---
  正向: 50 100 200 300
  逆向: 300 200 100 50
  Contains 200 :TRUE
  Delete (Find (200)) 后 Contains 200 :FALSE

--- 3. Hashed_Map ---
  M ("Bob") =  30
  Contains "Dan" : FALSE
  Include ("Bob", 31) 后 M ("Bob") = 31
  游标遍历（哈希序，与插入序无关）:
    Carol →  35
    Bob →  31
    Alice →  25

--- 4. Ordered_Set ---
  插入 5,3,8,1 + Include (3) 后（有序去重）: 1 3 5 8
  Length = 4（3 只算一次）
  Ceiling (4) = 5（第一个 >= 4 的元素）

  这些容器正是老教材泛型栈 STACK_G/集合思想的
  标准库化：实例化一次，得到一整套经过验证的操作。
```

## 23.8 小结

| 概念 | 要点 |
|------|------|
| 实例化 | 容器是泛型；哈希容器注入 Hash、有序容器注入 "<" |
| `for E of C` | 值遍历；`for C in C.Iterate` 游标遍历 |
| 游标 | 位置把手；`Element/Key/Next/To_Index`；`Next` 要变量 |
| Insert vs Include | 重复键：抛异常 vs 覆盖（Map/Set 通用） |
| `M (Key)` | 函数式下标；键缺失即异常 |
| 哈希序 vs 有序 | 遍历顺序：不保证 vs 确定 |
| `Indefinite_` | 接受不定长元素/String/class-wide |
| 值语义 | 容器赋值 = 深拷贝 |

容器的正确性靠类型系统与运行期检查兜底，**程序的正确性证明**
则要更进一步——下一章的契约（Pre/Post）与第 25 章的 SPARK。

---
上一章：[22 定点与十进制实数](22-fixed-point.md) ｜ 下一章：[24 契约](24-contracts.md) ｜ 返回：[README](../README.md)
