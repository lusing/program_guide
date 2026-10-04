# 10 · 基本数据结构：栈、队列、链表与有根树

> 对应 CLRS 第 10 章 *Elementary Data Structures*（英文 3rd ed. pp.232–253）。
> 这一章在 C++ 语境里有点特殊：栈、队列、链表标准库全有（`std::stack`、
> `std::queue`、`std::list`）——所以本章的重心是 CLRS 的**三种表示技术**：
> 哨兵简化边界、对象数组 + 自由表（指针的数组化）、树的紧凑表示。它们是
> 第 11–14 章散列表与平衡树的地基。

## 学习目标

1. 会实现数组栈与循环队列，说清「空/满」判据的设计取舍；
2. 理解哨兵（sentinel/nil）如何消灭边界分支，代价是什么；
3. 掌握「对象数组 + 下标当指针 + 自由表」的三数组表示（CLRS 10.3）；
4. 会用 left/right 与 first-child/next-sibling 两套数组表示树并遍历；
5. 知道 STL 容器各自的底层（deque/list/vector）与本章表示的对应。

## 栈与队列（§10.1）

**栈**（LIFO）：数组 + top 指针，push/pop 均摊 O(1)。示例的 `ArrayStack`
直接用 `std::vector` 尾部（vector 的倍增摊还见第 18 章）。下溢用 `assert`
拦——教学实现里 assert 即规格。

**循环队列**（FIFO）：定长数组 + head/tail 环形前进。经典设计问题：head
== tail 既可能是「空」也可能是「满」。三条路：

1. **留一个空位**（容量 n 只装 n−1）——满的判据 `tail+1 == head`；
2. **计数器**（示例的做法）——逻辑直白，多一个字段；
3. 时间戳/镜像位——省内存但绕。

示例实测（容量 4）：enqueue 4 9 16 → dequeue 4（head=1, tail=3）→
enqueue 25 36 时 **tail 环绕到 0** → 依次出队 9 16 25 36。环绕的正确性
靠 `% capacity` 的取模运算保证——head/tail 永远只增不减（模意义下），
这是循环结构「不回退」的纪律。

## 哨兵双链表（§10.2）

CLRS 的 LIST-INSERT/DELETE 满是「如果是头节点/尾节点就……」的分支。
**哨兵**节点 nil 把它们全部消掉：nil.next 是头、nil.prev 是尾，空表也
是 nil 自环——从此「表头」和「中间节点」代码路径合一：

```cpp
void list_insert(std::size_t x) {   // 插到链头，无任何分支
    next[x] = next[nil];
    prev[next[nil]] = x;
    next[nil] = x;
    prev[x] = nil;
}
void list_delete(std::size_t x) {   // O(1) 删除，同样无分支
    next[prev[x]] = next[x];
    prev[next[x]] = prev[x];
}
```

代价：多一个节点的空间 + 「下标 == nil」的判断从「下标 == −1」改成
「下标 == 哨兵下标」（语义不变）。示例用 `constexpr std::size_t NIL =
SIZE_MAX` 表示哨兵槽位。

**给下标即 O(1) 删除**是链表对数组的本质优势：数组删除要搬移 Θ(n)。
反过来数组按下标读是 O(1)、链表要 O(n) 走过去（`list_search`）——
`search(9)` 找到、`search(16)`（已删）返回哨兵，示例都断言了。

## 对象数组与自由表（§10.3）

CLRS 的经典 trick：不用指针不用 new，用**三个平行数组**（key/next/prev）
+ 下标当指针。分配/回收交给**自由表**（free list）——空闲槽位自身串成
单链表：

```cpp
std::size_t allocate_object() {      // 从自由表摘一个槽
    const std::size_t x = freeHead;
    freeHead = next[x];
    return x;
}
void free_object(std::size_t x) {    // 挂回自由表头
    next[x] = freeHead;
    freeHead = x;
}
```

实测（示例 10.2/10.3 联演）：槽 16 号节点被 free 后，下一次 allocate
**恰好复用同一个槽**（自由表 LIFO）——`assert(d == b)` 一行验证。这个
表示法的价值：

- **无 GC/无碎片**：定长槽位，分配回收各 O(1)；
- **可持久化/可序列化**：整个结构是三个数组，memcpy/落盘即快照
  （真实系统：数据库页、游戏 ECS、编译器 AST arena 全是它的化身）；
- **缓存友好**：槽位连续（对比 `std::list` 的节点满天飞）。

## 有根树的表示（§10.4）

**二叉树**：left/right（+ 可选 parent）三数组，−1 表空。示例搭了
6 节点小树并跑两种遍历：

- **中序**（left, 自身, right）：递归版用 C++23 的**显式对象形参递归
  lambda**——`auto inorder = [&](this auto&& self, ptrdiff_t i) { … self(…); }`，
  `this auto&& self` 让 lambda 引用自己，不再需要 `std::function` 的
  类型擦除开销；
- **先序**（自身, left, right）：**显式栈**版——递归消除的标准姿势，
  压栈顺序 right 后 left（LIFO 反转）。

**任意分支树**：first-child/next-sibling 两数组（左孩子右兄弟）——不管
节点有多少孩子都只需两个槽。B 的孩子 D、E 表示为 `fc[B]=D, ns[D]=E`。
DFS 的孩子循环就是一个 for 沿 ns 链走。两套表示的 DFS 序一致
（示例断言 `1 2 4 5 3 6`）。

```
下标:      0  1  2  3  4  5
key:       1  2  3  4  5  6
left:      1  3 -1 -1 -1 -1     ← 二叉树三件套
right:     2  4  5 -1 -1 -1
first-child: 1  3  5 -1 -1 -1   ← 左孩子右兄弟两件套
next-sibling:-1 2 -1 4 -1 -1
```

## C++23 语言点

- **递归 lambda（显式对象形参）**：`[&](this auto&& self, auto… args)`
  是 C++23 「deducing this」对 lambda 的应用，等价于 Y 组合子的受控版；
- 平行数组的下标即指针：`std::size_t` 全程无符号，空位用 `SIZE_MAX`
  （或 ptrdiff_t 的 −1）——两套纪律别混；
- `std::vector` 当栈用（back/push_back/pop_back）就是 ArrayStack。

## 与 STL 对照

| 本章结构 | STL 对应 | 底层 |
|---|---|---|
| ArrayStack | `std::stack`（默认） | deque |
| CircularQueue | `std::queue` | deque（环形缓冲的分段实现） |
| 哨兵双链表 | `std::list` | 真指针节点 + 哨兵（libstdc++/MSVC 都是 `_M_node` 哨兵——**本章的工业化版本**） |
| 对象数组+自由表 | `std::pmr::monotonic_buffer_resource` + arena | 槽位复用思想 |
| 定容环形缓冲 | `boost::circular_buffer` / 手写 | 环形 head/tail |

## 坑位清单

1. **把两次 `pop()` 写进同一个 println 的实参**
   （现象：输出「3 2」变「2 3」——顺序反了；原因：函数实参求值顺序
   未指定，MSVC/clang 实测从右往左、先求值右边的 pop；后果：输出语义
   错乱但三通道恰好一致（都右到左），逐字节对账还发现不了；对策：有副
   作用的表达式先落局部变量再打印——本例实测翻车，改后输出恢复
   「3 2」「9 16 25 36」。）
2. **注释行尾的反斜杠触发 -Wcomment**
   （现象：gcc 报 `warning: multi-line comment`，零告警判定失败；原因：
   ASCII 树形注释里 `/  \` 的行尾 `\` 恰在换行前——反斜杠续行把下一行
   注释吞了；后果：gcc 通道全红而 msvc 无感；对策：树形注释行尾不落
   反斜杠（加尾随空格或换画法）——本例实测翻车。）
3. **循环队列的空/满判据混用**
   （现象：enqueue 抛 assert「full」而实际没满，或满时静默覆盖；原因：
   「留空位」与「计数器」两种方案各有一套判据，代码里混用（比如 full
   用计数器、empty 用 head==tail）；后果：off-by-one 类边界 bug；
   对策：一种方案走到底，capacity/count/head/tail 的不变式写成 assert
   （每步 `count ≤ capacity` 且 `(head+count)%capacity == tail`）。）
4. **自由表忘把回收槽位的 next 清理/复用未重置 prev**
   （现象：遍历链表偶发走到「已删除」节点或成环；原因：free_object 后
   槽位的 next 仍指向自由表外的节点（或 prev 残留），allocate 后若调用方
   只设 key 不重接 prev 就成环；后果：数据结构损坏，且时机随机难复现；
   对策：allocate 返回后由 insert 负责四指针全部赋值——绝无「只接一半」
   的路径，示例 list_insert 四行全覆盖。）
5. **左孩子右兄弟的 next-sibling 与 first-child 混写**
   （现象：DFS 走出环或漏子树；原因：fc 指向**第一个**孩子、ns 指向
   **下一个兄弟**——把 ns 当「下一个孩子」接是同一类错；后果：遍历
   序错乱；对策：不变式断言「fc 与 ns 的终点都必须是 −1，且每节点被
   至多一个 fc/ns 指向」。）

## 练习

1. （CLRS 练习 10.1-1）画图演示 push/pop/enqueue/dequeue 各操作的 head/
   tail 变化（示例的输出就是答案底稿）。
2. （CLRS 练习 10.1-2）用一个数组实现两个栈（两端向中间长），给出
   满/空判据。
3. （CLRS 练习 10.1-4/10.1-6/10.1-7）队列的留空位版判据；两个栈模拟
   一个队列（均摊代价）；一个栈模拟队列的代价分析（第 18 章摊还伏笔）。
4. （CLRS 练习 10.2-1）单链表上 insert 前插 O(1)、delete/search 最坏
   Θ(n)——能不能都 O(1)？（不能，见思考题。）
5. （CLRS 练习 10.2-5）单向循环链表（哨兵无头）的实现；10.2-7 链表反转
   的迭代版（指针三件套 prev/cur/next）。
6. （CLRS 练习 10.3-4/10.3-5）紧凑化（让被占用槽位连续）；在自由表对象
   上做 ALLOCATE/OBJECT/FREE 的语言级解释器雏形。
7. （CLRS 练习 10.4-1/10.4-2/10.4-3）给图 10.9 的树做三种遍历；写出
   O(1) 空间的中序（不用栈——线索/父指针法）。
8. （本教程）给示例的 ListEngine 加 `validate()`（全程断言双向一致性
   prev[next[x]]==x），在 1000 步随机 insert/delete 序列上跑。

## 示例说明与运行输出

`examples/10_elementary_structures/main.cpp`：10.1 数组栈 + 计数器循环队列
（含环绕实测）、10.2 哨兵双链表（头插/O(1) 删/搜索）、10.3 自由表分配
回收与槽位复用、10.4 二叉树三数组（递归 lambda 中序 + 显式栈先序）与
左孩子右兄弟 DFS。

运行输出：

```text
栈：push 1 2 3 后弹出 3 2（LIFO）
循环队列（容量 4）：enqueue 4 9 16 → dequeue 4，head=1/tail=3
  再 enqueue 25 36（tail 环绕到 0）→ 依次出队：9 16 25 36
哨兵双链表：insert 9,16,4（头插）→ 遍历:
  4 16 9 
  delete(16)（O(1)——给下标即删）→ 遍历: 4 9（search(16) 返回哨兵）
  free_object(16) 后再 allocate → 复用槽 1，insert 25 → 遍历: 25 4 9
二叉树（数组三件套）中序遍历: 4 2 5 1 3 6 
先序遍历（显式栈）: 1 2 4 5 3 6 
左孩子右兄弟表示的 DFS: 1 2 4 5 3 6 
自检通过
```

*可运行示例见 examples/10_elementary_structures/。*
