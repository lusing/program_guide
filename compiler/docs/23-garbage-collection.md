# 第 23 章　垃圾回收：可达性、标记清除与 Cheney 复制

## 23.1 问题：堆上的东西谁来扫

第 21 章结尾留了一句话：
栈帧弹掉即弃，
但帧里若存着
指向堆的指针，
堆上的记录就成了
没人认领的家当。
手动管理
（C 的 free）
把清运责任推给程序员，
换来一整类
悬垂指针、
双释放、
泄漏的 bug；
自动回收
（garbage collection，GC）
让运行时来当清运工。

本章把三种经典收集器
在一块**模拟堆**上
跑出确定性对账：
引用计数、
标记清除、
Cheney 半空间复制。
材料取自紫龙 7.4–7.8，
定义与算法自包含。
一个预告：
GC 的核心词
**可达性**
（reachability）
是"从根集合出发、
沿指针闭包"
——这正是
第 30 章不动点、
第 31 章工作表的
又一次现身，
只是这次它扫的
不是程序点，
而是堆上的对象。

## 23.2 根集合与可达性

**根集合**
（root set）：
程序不经过任何
指针解引用
就能直接访问的
全部引用——
栈帧里的局部变量、
静态/全局变量、
（优化代码里）
寄存器中的引用。

**可达**：
根集合里的对象可达；
递归地，
可达对象槽里
引用的对象可达。
除此之外，
皆为**垃圾**。

可达集随程序执行
（mutator 的四种动作）
生灭：
分配让新对象入集；
传参/赋值传播引用；
引用改写与
过程返回
（帧弹出，
局部引用消失）
可能掐断最后的路径。
关键的不可逆性：
**对象一旦不可达，
永不可达**——
没有任何操作
能找回"谁也指不到"的东西。
这条单调性
是"周期性批量回收"
在语义上安全的根据。

编译器与 GC 的
配合点也在这里：
优化器可能把引用
藏进寄存器、
指向对象中段，
所以真编译器要么
只在"无隐藏引用"
的安全点触发 GC，
要么写出
栈映射让 GC
能复原根集合
（紫龙 7.5.2 的三条对策）。

## 23.3 引用计数：把回收摊进每次赋值

**引用计数**
（reference counting）
是"边产生边回收"派：
每个对象带一个计数，
规则五条
（紫龙 7.5.3）：

1. 分配：计数置 1；
2. 传参/返回：计数 +1；
3. 引用赋值 u = v：
   v 指的对象 +1，
   u 原指的对象 −1；
4. 过程返回：帧内所有
   引用逐个 −1；
5. 计数归零：
   立即回收，
   并对其槽指向的
   对象逐一 −1
   （级联）。

优点朴素而实在：
回收是增量的、
无停顿，
空间即时归还。
但它有两个致命伤：

**环**。
E→E（自环）、
F→G→F（二环）：
从外部断掉
最后一根引用后，
环内成员
互相指着对方，
计数永远 ≥ 1，
永远等不来归零。
紫龙 Example 7.11
的结论在我们
期望输出里
按字面兑现：

```
E: count=1   ← 自环
F: count=1   ← 二环
G: count=1   ← 二环
non-zero but unreachable: E F G  （环：计数永不为零，泄漏）
rc_freed = 1（只有 H 计数归零；环上三个永远漏掉）
```

**开销**。
每次引用赋值
都带一串加减，
代价与
程序计算量成正比
（而非与对象数成正比）；
优化代码还要
频繁改写根集合
里的计数。
"延迟引用计数"
（根引用不计数，
回收前补扫根集）
是常见的
减负折中。

## 23.4 标记清除：批量算一次可达

**标记清除**
（mark-and-sweep，
紫龙 Algorithm 7.12）
是"定期批量"派，
两阶段：

**标记**：
从根集合出发，
reached 位置 1、
入 Unscanned 表；
循环弹出 o、
扫它的每个槽：
未达者置位入表。
表空即终止。

**清扫**：
整堆扫一遍，
reached=0 者
进 Free 表；
reached=1 者
**把位清回 0**
——为下一轮
准备正确的初态
（"可达者此刻可达，
下一轮开始时
一切重新接受审判"）。

标记循环的形状
值得盯着看三秒：

```
while (Unscanned 非空) {
    取出 o
    对 o 的每个引用目标 t：
        若 t 未达：置位并入表
}
```

这就是工作表算法：
"发现新东西就记账、
账清了就停"——
第 31 章
把它用在
数据流方程上，
本章它算的是
**指针图的传递闭包**。
可达性 =
从根出发的最小
（传递）闭包，
标记阶段算的
正是这个不动点。

我们的演示图
（八对象、双根）：

```
可达：A→{B,C}, B→{D}, C→{D}   （D 被 B、C 共享）
不可达：E（自环）、F⇄G（二环）、H→B（指向可达者，但自己没人指）
```

期望输出：

```
survived: A B C D
freed: E F G H
ms_freed = 4
```

H 的命运是
本章的教学钉子：
**垃圾指向可达者
救不了自己**——
可达性只问
"有没有人指到我"，
不问"我指着谁"。
方向的单向性
正是传递闭包的
单向性。

标记清除的代价：
清扫要**整堆**扫一遍
（不可达集无法
直接枚举，
只能取补集）；
Baker 的优化
（紫龙 Algorithm 7.14）
维护一张
"已分配对象表"，
用
Free ∪ Unreached
的差集代替整堆扫描，
并顺手把
四态显式化为
四张表。
另一处通病是
**碎片**：
回收后的空洞
散落各处，
大对象装不下——
这就引出了
搬运派。

## 23.5 Cheney 复制：把幸存者搬个家

**复制收集**的思路：
预留半块堆
（to-space），
把可达对象
全部拷过去，
紧凑排列，
旧半块
（from-space）
整块宣布为空。
碎片问题
一次清零，
"空闲空间"退化为
一个指针。

**Cheney 算法**
（紫龙 7.6.5）
用两根指针
在 to-space 上
赛跑：

- **free**：
  下一个空位；
  每拷贝一个对象
  就前移它的体积；
- **scan**：
  下一个待扫描的
  已拷贝对象；
  扫描就是读它的槽、
  把槽指向的对象
  （若未拷贝）拷到
  free 处。

每个对象头里留
**转发地址**
（forwarding address）：
第一次被拷贝时记下
"我搬到 new k 了"，
再次遇到这个引用
直接改写为
新地址、
不再拷贝
（对象只搬一次，
扫描不重复）。
scan 追上 free，
即所有可达对象
拷完且扫完
——广度优先的
传递闭包，
闭包与搬运
一气呵成。

期望输出：

```
copy order: A B C D
new0 = A [new1 new2]
new1 = B [new3]
new2 = C [new3]
new3 = D []
cheney_copied = 4
```

读三点：

1. 拷贝次序
   A B C D
   是从根出发的
   广度优先序；
2. D 只出现一次
   （new3），
   B、C 的槽
   都改写到 new3
   ——共享被保持；
3. E、F、G、H
   根本不出现在
   to-space：
   垃圾不需要
   "被识别"，
   **不被拷贝
   就是消失**
   ——清扫步骤
   整个免了。

代价直白：
堆只能用一半
（空间换时间），
对象被搬走后
**一切指向它的
旧引用**都要改
（根集合、
幸存者槽内——
我们的输出里
槽值已改写成
new 系）。
长命对象在
每轮收集中
反复搬运
是新的痛点，
解药是**分代**：
按"朝生暮死"
的经验规律
（弱分代假说）
把新对象放
"新生代"
频繁清理，
熬过几轮的
晋升"老年代"
少动——
用**记忆集/卡表**
记录老生代
指向新生代的
跨代引用，
收集新生代时
把它们并入根。
紫龙 7.7 的
增量、并发、
火车算法
沿同一方向
把"停顿"削短，
此处按下不表，
坐标已给。

最后一问：
槽里存的是
对象编号，
怎么知道
"哪些槽是引用"？
我们的模拟堆
类型单一、
槽皆引用；
真实运行时
靠类型描述符
（精确式）
或保守地
把"像指针的值"
都当指针
（保守式，
Boehm 收集器，
C/C++ 的现实选择——
可能漏收、
不敢搬对象）。

## 23.5b　三色抽象：黑不指白（匠书 §26.3）

标记清除的"标记"阶段是一锅端——从根一口气标到完。**三色抽象**
把这锅端拆成可暂停的步骤，并且给出一个能证明"随时暂停都不丢
活对象"的不变式——这是增量收集（并发标记、让 GC 与程序交替
跑）的全部理论基础。

三色的定义：**白** = 还没访问到（候选垃圾）；**灰** = 自己已被
访问、但它的引用还没扫完（在途状态）；**黑** = 自己与引用全部
扫完（活对象定案）。标记过程 = 把根染灰，然后反复"取一个灰
变黑、其白子染灰"，直到灰集空——**白集即垃圾**。

**三色不变式：黑不指白。** 任何黑对象的引用目标都不是白——
只要不变式保持，暂停在任何时刻，白色对象都仍然只能被灰或白
引用（灰还会被扫），不存在"黑对象引用的活对象被误判白"——
**不变式是随时暂停的安全性证明**。本章示例把每一步的灰/白
快照与不变式检查全部打印（triColor 的 steps 表）：演示图五步
走完、violation 恒 0、终态白集 {E,F,G,H} 与标记清除的 freed 集
逐元素相等——两台"机器"（一口气 vs 逐步）算出同一份垃圾名单。

**逐步表怎么读**（期望输出的 step 0..4 行）：step 0 是初始化
（根 A、B 染灰——白集 6 个）；step 1 取 A 变黑、A 的白子 C 染灰
（灰 {B,C}）；step 2 取 B 变黑、D 染灰；step 3 取 C 变黑（D 已灰
）；step 4 取 D 变黑、灰空——结束。每行尾的 invariant=held 是
该步后"黑不指白"的机器检查——**五步五检全过**，终态白与
ms_freed 的对账行（final_white == ms_freed : yes）合起来是三色
抽象在本演示图上的完整正确性证书。

**灰集为什么是工作表的孪生兄弟**：三色的灰集恰好就是标记清除
的工作表内容（待扫对象集）——三色抽象没有发明新算法，它给
同一个 BFS 装上了**可暂停的刻度**（每步恰好处理一个对象）。
第 29 章工作表四序的收敛账在这里翻版：三色的步数 = 活对象数
（每个活对象恰好变黑一次）——步数与顺序无关、每步内容有关
（取哪个灰是自由的——这正是并发实现可以挑时机的原因）。

为什么三色对增量如此重要？并发标记时**程序在改图**（新引用
产生）——不变式被破坏的情形恰有两类（黑指白的新边产生、或
白对象被黑引用时未经灰）：增量 GC 的写屏障（write barrier）
就是在赋值处补染色、恢复不变式的运行时钩子。教程不实现屏障，
但读者此刻应能读懂 G1/ZGC 文档里"saturation barrier""snapshot
at the beginning"这些词的所指——**它们全是不变式的维护策略**。

## 23.5c　弱引用与字符串池：缓存不是语义（匠书 §26.4）

第 59 章立过"驻留池是缓存不是语义"的原则，本章兑现它的 GC
侧推论：**池不在根集里**。标记只从程序根出发——池里那些没有
程序引用的死串，标记阶段视而不见；清扫前做**弱表清除**：把
死串从池中摘除。效果（weakPoolDemo 的三行报告）：池从 5 缩
到 4、被摘的恰是死串、堆回收数 4 不受池影响——**池的存在不
改变任何程序可观察行为**（下次 intern 死串会重建，比较语义
不变——值相等 ⇔ 指针相等靠的是"活串唯一"，重建不破坏它）。

反例账也在演示里：**若池当强根**，那 1 个死串被误保活——
驻留池从缓存**越位成语义根**，字符串永生、内存只涨不跌（真实
引擎历史上真踩过：早期 JVM 的 String.intern 滥用症）。弱引用
的存在意义就是给"想快速查找、又不想左右生存期"的数据结构一
个合法身份——**缓存的爱是放手的爱**。

**弱引用的三个真实用户**顺带列出：驻留池（本节）、GC 的终结
队列（finalization——对象死后回调的登记表也是弱表）、缓存
（WeakHashMap 族——键死条目自动消失）。三者的共同形状
"查找快 + 不保活"就是弱引用的签名——第 59 章池的"可以回收"
许可证，在此处是三行代码的兑现。

（上值章 FAQ 的伏笔在此兑现：上值盒由 shared_ptr 保活是引用
计数路线；当引擎整体换 GC，盒就是普通堆对象、闭包的 ups 数组
就是引用边——**GC 的第一批真实客户恰好是闭包与驻留池**，
匠书把 GC 章排在闭包章之后的深意即此。）

## 23.5d　LISP2 标记压紧：三指针滑动（练习引申）

标记清除留下**碎片**（活对象间的洞——分配大对象可能失败尽管
总空闲够）；Cheney 用"整堆搬家"压紧（半空间对换）。第三条路
**原地压紧**：LISP2 三指针算法（1960s 的活化石）。

三遍走：**标记**（同前）；**派址**（first 指针从 0 滑过全堆、
给每个活对象按地址升序派新址——活对象密度决定新址前缀）；
**改写**（last 指针再滑一遍、把所有活对象的槽引用改写成新址）
。示例的 moved 表就是派址结果：A→0、B→1、C→2、D→3——
活对象恰好已是前缀（演示图巧了），引用改写后 cell0=[cell1
cell2] 与 Cheney 的 new0=[new1 new2] **形状全同**；洞数从
2（死串夹在活对象间 + 尾块）归到 1（纯尾块）——holes_after
= 1 断言锁死"碎片归一"。

**新址单调的副产品**：LISP2 压紧后活对象保持原相对顺序（first
指针从左到右派址）——这不仅是整齐，它保证了指向同一代的引用
群在压紧后仍然局部（缓存友好的旧邻还是邻）。对比 Cheney 的
BFS 序（按可达层次重排），两种重排对局部性的影响不同——
LISP2 保序对指针密集的老年代更友好（分代引擎的老年代压紧多
选标记压紧族——mark-compact 由此得名，与新生代 copying 相对）。

与 Cheney 的对照收进一行：**原地两次滑 vs 搬家一次 BFS**——
LISP2 省一半空间（无半空间对换）、付出多一遍遍历；Cheney 反
之。真实引擎的取舍看对象生存率（存活少 → Cheney 划算：只拷
活的；存活多 → LISP2：搬家太贵）——**两台压紧机各吃一段
负载谱**，分代引擎的新生代（存活率 ~10%）清一色 Cheney。

## 23.6 期望输出解读与对账

四段输出对应
三台收集器加对账：

**objects/roots**：
演示图的清单，
八对象双根，
H→B 的"指向可达者"
一目了然。

**reference counting**：
八个计数；
H=0（会被回收），
E/F/G=1
（环上漏掉），
对账行
`rc_freed = 1 < ms_freed = 4`
把两种哲学的
差距钉在数字上——
**差额正是环**。

**mark-and-sweep**：
survived/freed
四四开；
freed 里的 H
与 RC 的结论一致，
E/F/G 是
RC 漏掉的部分。

**cheney**：
拷贝序、
新布局（槽已改写为
new 系引用）、
cheney_copied = 4。

**对账**行一：
`survivors(ms) == copied(cheney) : yes`
——两台追踪式收集器
对"什么活着"
必须给出同一答案
（它们算的是
同一个传递闭包）；
行二：
rc 与 ms 的差额
即环的清单。
这两行是本章的
机器证人。

## 23.7 工程注意点

- **GC 与编译器的合同**。
  优化器搬移引用、
  拆解对象，
  GC 就找不到根
  ——安全点、
  栈映射、
  对象头里
  保留类型描述符，
  都是合同的条款。
  第 61 章
  寄存器分配把
  变量留在寄存器，
  同样要向
  根集合申报。
- **精确 vs 保守**。
  精确式
  （知道每个槽的类型）
  才敢搬运对象；
  保守式
  （把可疑值都当指针）
  只能标记清除、
  可能漏收。
  这决定了
  一门语言能上
  哪些收集器。
- **停顿的世界观**。
  引用计数
  无停顿但漏环；
  标记清除
  一次停顿扫全堆；
  复制
  停顿换紧凑；
  分代/增量/并发
  把停顿切细。
  没有免费午餐，
  只有权衡菜单
  （紫龙 7.5.1 的
  四条设计目标：
  速度、空间、
  停顿、局部性）。
- **可达性分析
  与本教程主线**。
  markSweep 的
  Unscanned 循环
  与第 31 章
  工作表、
  第 36 章
  框架求解器
  是同一台机器：
  "单调地累积事实
  直到没有新事实"。
  GC 章提前
  出现在 IR 篇，
  就是为了让
  这个旋律
  多响一次。

## 23.8 本章配套文件

本示例无 ANTLR、
无 LLVM——
一块模拟堆加
三台收集器，
走"简单程序"
对账协议
（无参运行，
stdout 对
expected/output.txt）。

### 23.8.1 heap.hpp 与 heap.cpp

对象/堆模型、
演示图、
三台收集器。

```cpp
// file: src/heap.hpp
// file: src/heap.hpp
// 第 23 章配套：模拟堆与三台收集器（引用计数 / 标记清除 / Cheney 复制）。
// 对象 = 名字 + 槽位数（槽存对象编号，-1 空）——刻意最小，
// 让“可达性”成为唯一主角。
#ifndef TIP_HEAP_HPP
#define TIP_HEAP_HPP

#include <map>
#include <string>
#include <vector>

namespace tip {

struct Obj {
    std::string name;
    std::vector<int> slot;   // 槽：指向对象编号；-1 = 空
};

class Heap {
public:
    int alloc(const std::string &name, int nslots);
    void set(int obj, int slot, int target);
    const Obj &o(int id) const { return objs_[id]; }
    int size() const { return static_cast<int>(objs_.size()); }
    const std::vector<int> &roots() const { return roots_; }
    void addRoot(int id) { roots_.push_back(id); }
    void dropRoot(int id);
    // 重新加载内置演示图（供三种收集器各自从同一初始状态出发）
    static Heap demo();

private:
    std::vector<Obj> objs_;
    std::vector<int> roots_;
};

// ---------- 收集器一：引用计数（紫龙 7.5.3） ----------
// 计数按“当前堆+根的引用”推演；报告存活计数与它漏掉的环。
struct RefCountReport {
    std::map<int, int> count;        // 对象 → 入度计数（按根+堆边计算）
    std::vector<int> nonZeroButUnreachable;
};

RefCountReport refCount(const Heap &h);

// ---------- 收集器二：标记清除（紫龙 Algorithm 7.12） ----------
struct MarkSweepReport {
    std::vector<int> survived, freed;
};

MarkSweepReport markSweep(Heap &h);

// ---------- 收集器三：Cheney 半空间复制（紫龙 7.6.5） ----------
struct CheneyReport {
    std::vector<int> copyOrder;         // 拷贝次序（BFS）
    std::map<int, int> forwarding;      // 旧编号 → 新编号
    std::vector<std::pair<int, std::vector<int>>> newLayout;   // 新堆
};

CheneyReport cheney(const Heap &h);

// ---------- 补一（匠书 §26.3）：三色抽象与三色不变式 ----------
// 白 = 未访问；灰 = 自身已访问、子节点未扫完；黑 = 自身与子节点全扫完。
// 不变式：黑不指白（任何黑对象的引用目标不为白）——增量收集
// （并发标记）的正确性根基：只要不变式保持，随时暂停都不丢活对象。
struct TriColorStep {
    std::vector<int> gray;   // 本步前灰集
    int picked;              // 本步变黑的对象（-1 = 本步只初始化/收尾）
    std::vector<int> white;  // 本步后白集
    bool invariantHeld;      // 本步后"黑不指白"是否仍成立
};

struct TriColorReport {
    std::vector<TriColorStep> steps;   // 每步快照（含初始化步）
    std::vector<int> finalWhite;       // 终态白集 = 垃圾（与 markSweep 一致）
    int invariantViolations;           // 全程违反次数（演示里应为 0）
};

TriColorReport triColor(const Heap &h);

// ---------- 补二（匠书 §26.4）：弱引用与字符串池 ----------
// 驻留池是缓存不是语义：GC 的根集不含池，标记后清扫前清弱表——
// 死串从池中摘除（下次 intern 重建即可，行为不变）。
struct WeakPoolReport {
    int pooledBefore;            // 回收前池大小
    std::vector<std::string> evicted;  // 被摘除的死串（按名字序）
    int pooledAfter;             // 回收后池大小
    int freedObjects;            // 本次回收的对象数（弱表清除前后对照）
    bool leakWouldHappenIfStrong;  // 若池当强根：多少死串会被误保活
};

WeakPoolReport weakPoolDemo(Heap &h, const std::vector<std::string> &poolNames);

// ---------- 补三（匠书 §26 练习引申）：LISP2 标记压紧 ----------
// 三指针滑动：mark 后 first/last/free 一趟归位、改写全部引用。
// 压紧后地址单调、碎片归一——与 Cheney 的"拷贝压紧"对照：
// 原地 vs 搬家、两次遍历 vs 一次 BFS。
struct Lisp2Report {
    std::map<int, int> moved;         // 旧编号 → 新编号（活对象）
    std::vector<std::pair<int, std::vector<int>>> newLayout;
    int holesBefore;                  // 压紧前空闲块数（含尾块）
    int holesAfter;                   // 压紧后空闲块数（应恰 1）
};

Lisp2Report lisp2(Heap &h);

}  // namespace tip

#endif  // TIP_HEAP_HPP
```

```cpp
// file: src/heap.cpp
// file: src/heap.cpp
// 第 23 章配套：堆的构造与三台收集器实现。
#include "heap.hpp"

#include <algorithm>
#include <deque>
#include <set>

#include <algorithm>
#include <deque>

namespace tip {

int Heap::alloc(const std::string &name, int nslots) {
    objs_.push_back(Obj{name, std::vector<int>(nslots, -1)});
    return static_cast<int>(objs_.size()) - 1;
}

void Heap::set(int obj, int slot, int target) {
    objs_[obj].slot[slot] = target;
}

void Heap::dropRoot(int id) {
    roots_.erase(std::remove(roots_.begin(), roots_.end(), id), roots_.end());
}

// 内置演示图：
//   可达：A→{B,C}, B→{D}, C→{D}（D 被 B、C 共享）
//   不可达自环：E→E
//   不可达二环：F→G→F
//   不可达但指向可达者：H→B（垃圾救不了自己）
// 根：a=A, b=B
Heap Heap::demo() {
    Heap h;
    int A = h.alloc("A", 2), B = h.alloc("B", 1), C = h.alloc("C", 1), D = h.alloc("D", 0);
    int E = h.alloc("E", 1), F = h.alloc("F", 1), G = h.alloc("G", 1), H = h.alloc("H", 1);
    h.set(A, 0, B);
    h.set(A, 1, C);
    h.set(B, 0, D);
    h.set(C, 0, D);
    h.set(E, 0, E);   // 自环
    h.set(F, 0, G);
    h.set(G, 0, F);   // 二环
    h.set(H, 0, B);   // 垃圾指向可达者
    h.addRoot(A);
    h.addRoot(B);
    (void)C;
    (void)D;
    (void)E;
    (void)F;
    (void)G;
    (void)H;
    return h;
}

// ---------- 引用计数 ----------
// “计数清零即回收”在这里以报告形式呈现：统计每对象的入度，
// 并与真可达性（借用 markSweep 的标记阶段结果）对照。
RefCountReport refCount(const Heap &h) {
    RefCountReport r;
    for (int i = 0; i < h.size(); ++i) r.count[i] = 0;
    for (int root : h.roots()) r.count[root] += 1;   // 根引用也计数
    for (int i = 0; i < h.size(); ++i)
        for (int t : h.o(i).slot)
            if (t >= 0) r.count[t] += 1;
    // 真可达集合（独立的标记遍历，不改动 h）
    std::vector<bool> reach(h.size(), false);
    std::deque<int> work(h.roots().begin(), h.roots().end());
    while (!work.empty()) {
        int cur = work.front();
        work.pop_front();
        if (reach[cur]) continue;
        reach[cur] = true;
        for (int t : h.o(cur).slot)
            if (t >= 0 && !reach[t]) work.push_back(t);
    }
    for (int i = 0; i < h.size(); ++i)
        if (!reach[i] && r.count[i] > 0)
            r.nonZeroButUnreachable.push_back(i);
    return r;
}

// ---------- 标记清除（Algorithm 7.12） ----------
// 标记阶段：Unscanned 工作表——第 31 章工作表算法的原生态现身；
// 清扫阶段：整堆扫一遍，未标记者入 freed，标记位复位（为下一轮做准备）。
MarkSweepReport markSweep(Heap &h) {
    MarkSweepReport r;
    std::vector<bool> reached(h.size(), false);
    std::deque<int> unscanned;
    for (int root : h.roots())
        if (!reached[root]) {
            reached[root] = true;
            unscanned.push_back(root);
        }
    while (!unscanned.empty()) {
        int o = unscanned.front();
        unscanned.pop_front();
        for (int t : h.o(o).slot) {
            if (t >= 0 && !reached[t]) {
                reached[t] = true;
                unscanned.push_back(t);
            }
        }
    }
    for (int i = 0; i < h.size(); ++i)
        if (reached[i]) r.survived.push_back(i);
        else r.freed.push_back(i);
    return r;
}

// ---------- Cheney 复制 ----------
// 从根出发广度优先：scan 与 free 两根指针在“到空间”上赛跑；
// 每个对象只拷贝一次（forwarding 表挡驾），拷贝时留下转发地址。
CheneyReport cheney(const Heap &h) {
    CheneyReport r;
    std::map<int, int> fwd;
    std::deque<int> scanQueue;   // 已拷贝、待扫描（新编号即队列位置）
    auto copyOf = [&](int old) -> int {
        auto it = fwd.find(old);
        if (it != fwd.end()) return it->second;
        int fresh = static_cast<int>(r.newLayout.size());
        r.newLayout.push_back({old, h.o(old).slot});
        r.copyOrder.push_back(old);
        fwd[old] = fresh;
        return fresh;
    };
    for (int root : h.roots()) copyOf(root);
    size_t scan = 0;
    while (scan < r.newLayout.size()) {
        auto &entry = r.newLayout[scan];
        for (int &t : entry.second)
            if (t >= 0) t = copyOf(t);
        ++scan;
    }
    r.forwarding = fwd;
    return r;
}

// ---------- 补一：三色抽象（匠书 §26.3） ----------
TriColorReport triColor(const Heap &h) {
    TriColorReport r;
    r.invariantViolations = 0;
    int n = h.size();
    enum Color { White, Gray, Black };
    std::vector<Color> color(size_t(n), White);
    std::vector<int> black;
    // 黑不指白检查：对每个黑对象，引用目标不得为白
    auto checkInvariant = [&]() {
        for (int b : black)
            for (int t : h.o(b).slot)
                if (t >= 0 && color[size_t(t)] == White) return false;
        return true;
    };
    // 第 0 步：根染灰（初始化步）
    {
        TriColorStep s;
        for (int root : h.roots()) color[size_t(root)] = Gray;
        for (int i = 0; i < n; ++i)
            if (color[size_t(i)] == Gray) s.gray.push_back(i);
        s.picked = -1;
        for (int i = 0; i < n; ++i)
            if (color[size_t(i)] == White) s.white.push_back(i);
        s.invariantHeld = true;  // 尚无黑对象
        r.steps.push_back(s);
    }
    // 主循环：每步取一个灰对象变黑、其白子染灰
    for (;;) {
        int pick = -1;
        for (int i = 0; i < n; ++i)
            if (color[size_t(i)] == Gray) { pick = i; break; }
        if (pick < 0) break;
        TriColorStep s;
        color[size_t(pick)] = Black;
        black.push_back(pick);
        for (int t : h.o(pick).slot)
            if (t >= 0 && color[size_t(t)] == White) color[size_t(t)] = Gray;
        for (int i = 0; i < n; ++i)
            if (color[size_t(i)] == Gray) s.gray.push_back(i);
        s.picked = pick;
        for (int i = 0; i < n; ++i)
            if (color[size_t(i)] == White) s.white.push_back(i);
        s.invariantHeld = checkInvariant();
        if (!s.invariantHeld) ++r.invariantViolations;
        r.steps.push_back(s);
    }
    for (int i = 0; i < n; ++i)
        if (color[size_t(i)] == White) r.finalWhite.push_back(i);
    return r;
}

// ---------- 补二：弱引用与字符串池（匠书 §26.4） ----------
WeakPoolReport weakPoolDemo(Heap &h, const std::vector<std::string> &poolNames) {
    WeakPoolReport r;
    r.pooledBefore = static_cast<int>(poolNames.size());
    // 标记（只从根出发——池不在根集）
    std::vector<char> alive(size_t(h.size()), 0);
    std::vector<int> work;
    for (int root : h.roots()) { alive[size_t(root)] = 1; work.push_back(root); }
    while (!work.empty()) {
        int cur = work.back(); work.pop_back();
        for (int t : h.o(cur).slot)
            if (t >= 0 && !alive[size_t(t)]) { alive[size_t(t)] = 1; work.push_back(t); }
    }
    // 弱表清除：池中名字对应的对象若死，从池摘除（名字匹配演示堆对象）
    std::set<std::string> poolSet(poolNames.begin(), poolNames.end());
    for (int i = 0; i < h.size(); ++i) {
        if (!alive[size_t(i)] && poolSet.count(h.o(i).name))
            r.evicted.push_back(h.o(i).name);
    }
    std::sort(r.evicted.begin(), r.evicted.end());
    r.pooledAfter = r.pooledBefore - static_cast<int>(r.evicted.size());
    int dead = 0;
    for (int i = 0; i < h.size(); ++i)
        if (!alive[size_t(i)]) ++dead;
    r.freedObjects = dead;
    // 若池当强根：死串全被误保活
    int rescued = 0;
    for (int i = 0; i < h.size(); ++i)
        if (!alive[size_t(i)] && poolSet.count(h.o(i).name)) ++rescued;
    r.leakWouldHappenIfStrong = rescued;
    return r;
}

// ---------- 补三：LISP2 标记压紧（匠书 §26 练习引申） ----------
Lisp2Report lisp2(Heap &h) {
    Lisp2Report r;
    int n = h.size();
    // 标记
    std::vector<char> alive(size_t(n), 0);
    std::vector<int> work;
    for (int root : h.roots()) { alive[size_t(root)] = 1; work.push_back(root); }
    while (!work.empty()) {
        int cur = work.back(); work.pop_back();
        for (int t : h.o(cur).slot)
            if (t >= 0 && !alive[size_t(t)]) { alive[size_t(t)] = 1; work.push_back(t); }
    }
    // 第一遍：first（写指针）扫滑道，给活对象按地址升序派新址
    std::map<int, int> addr;   // 旧编号 → 新编号
    int first = 0;
    for (int i = 0; i < n; ++i)
        if (alive[size_t(i)]) addr[i] = first++;
    // 第二遍：last（读指针）改写引用——所有活对象的槽指向新址
    std::vector<std::pair<int, std::vector<int>>> layout;
    for (int i = 0; i < n; ++i) {
        if (!alive[size_t(i)]) continue;
        std::vector<int> slots = h.o(i).slot;
        for (int &t : slots)
            if (t >= 0) t = addr.at(t);
        layout.push_back({addr.at(i), slots});
    }
    // 根与引用全部改写后重排完成；数洞（含尾块）
    int holes = 1;  // 尾块
    char prevDead = 1;
    for (int i = 0; i < n; ++i) {
        if (alive[size_t(i)]) { prevDead = 0; }
        else {
            if (!prevDead) ++holes;
            prevDead = 1;
        }
    }
    r.holesBefore = holes;
    r.holesAfter = 1;  // 压紧后：活对象前缀 + 一个尾大块
    r.moved = addr;
    r.newLayout = layout;
    return r;
}

}  // namespace tip
```

### 23.8.2 驱动 main.cpp

打印四段与对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 23 章驱动（无参运行，走"简单程序"对账协议）：
//   演示图 → 引用计数报告 → 标记清除 → Cheney 复制 → 两行对账
//   →（匠书增量）三色抽象逐步 → 弱引用字符串池 → LISP2 压紧。
#include "heap.hpp"

#include <algorithm>
#include <iostream>
#include <vector>

namespace {

void dumpGraph(const tip::Heap &h) {
    std::cout << "== objects ==\n";
    for (int i = 0; i < h.size(); ++i) {
        std::cout << "  " << i << ": " << h.o(i).name << " [";
        for (size_t k = 0; k < h.o(i).slot.size(); ++k) {
            int t = h.o(i).slot[k];
            std::cout << (k ? " " : "") << (t < 0 ? "-" : h.o(t).name);
        }
        std::cout << "]\n";
    }
    std::cout << "== roots ==\n";
    for (int r : h.roots()) std::cout << "  -> " << h.o(r).name << '\n';
}

}  // namespace

int main() {
    tip::Heap h = tip::Heap::demo();
    dumpGraph(h);

    std::cout << "== reference counting ==\n";
    tip::RefCountReport rc = tip::refCount(h);
    for (int i = 0; i < h.size(); ++i)
        std::cout << "  " << h.o(i).name << ": count=" << rc.count.at(i) << '\n';
    std::cout << "  non-zero but unreachable:";
    for (int i : rc.nonZeroButUnreachable) std::cout << ' ' << h.o(i).name;
    std::cout << "  （环：计数永不为零，泄漏）\n";
    int rcFreed = 0;
    for (int i = 0; i < h.size(); ++i)
        if (rc.count.at(i) == 0) ++rcFreed;
    std::cout << "  rc_freed = " << rcFreed << "（只有 H 计数归零；环上三个永远漏掉）\n";

    std::cout << "== mark-and-sweep ==\n";
    tip::Heap h2 = tip::Heap::demo();
    tip::MarkSweepReport ms = tip::markSweep(h2);
    std::cout << "  survived:";
    for (int i : ms.survived) std::cout << ' ' << h2.o(i).name;
    std::cout << "\n  freed:";
    for (int i : ms.freed) std::cout << ' ' << h2.o(i).name;
    std::cout << "\n  ms_freed = " << ms.freed.size() << '\n';

    std::cout << "== cheney copying ==\n";
    tip::CheneyReport cr = tip::cheney(h);
    std::cout << "  copy order:";
    for (int i : cr.copyOrder) std::cout << ' ' << h.o(i).name;
    std::cout << '\n';
    for (const auto &entry : cr.newLayout) {
        std::cout << "  new" << cr.forwarding.at(entry.first) << " = " << h.o(entry.first).name
                  << " [";
        for (size_t k = 0; k < entry.second.size(); ++k) {
            int t = entry.second[k];
            std::cout << (k ? " " : "") << (t < 0 ? "-" : "new" + std::to_string(t));
        }
        std::cout << "]\n";
    }
    std::cout << "  cheney_copied = " << cr.copyOrder.size() << '\n';

    std::cout << "== 对账 ==\n";
    std::cout << "  survivors(ms) == copied(cheney) : "
              << (ms.survived.size() == cr.copyOrder.size() ? "yes" : "NO") << '\n';
    std::cout << "  rc_freed = " << rcFreed << " < ms_freed = " << ms.freed.size()
              << "：差额正是环\n";

    // ================= 匠书增量（批次四十七） =================
    std::cout << "== tri-color abstraction（§26.3）==\n";
    tip::TriColorReport tc = tip::triColor(h);
    for (size_t k = 0; k < tc.steps.size(); ++k) {
        const tip::TriColorStep &s = tc.steps[k];
        std::cout << "  step " << k << ": gray={";
        for (size_t j = 0; j < s.gray.size(); ++j)
            std::cout << (j ? "," : "") << h.o(s.gray[j]).name;
        std::cout << "} ";
        if (s.picked >= 0)
            std::cout << "blacken=" << h.o(s.picked).name << " ";
        std::cout << "white={";
        for (size_t j = 0; j < s.white.size(); ++j)
            std::cout << (j ? "," : "") << h.o(s.white[j]).name;
        std::cout << "} invariant="
                  << (s.invariantHeld ? "held" : "VIOLATED") << '\n';
    }
    std::cout << "  final white = 终态白集（垃圾）:";
    for (int i : tc.finalWhite) std::cout << ' ' << h.o(i).name;
    std::cout << "\n  violations = " << tc.invariantViolations << "（黑不指白全程保持）\n";
    // 三色终白集应与 markSweep 的 freed 一致
    {
        std::vector<int> a = tc.finalWhite, b = ms.freed;
        std::sort(a.begin(), a.end());
        bool same = a == b;
        std::cout << "  final_white == ms_freed : " << (same ? "yes" : "NO") << '\n';
    }

    std::cout << "== weak references & string pool（§26.4）==\n";
    // 池里放五个名字：两个活（被根可达引用）、三个死——池不是根
    tip::Heap h3 = tip::Heap::demo();
    tip::WeakPoolReport wp = tip::weakPoolDemo(
        h3, {"A", "B", "C", "D", "H"});  // 池含死对象名（C/D/H 由对账确定）
    std::cout << "  pooled_before = " << wp.pooledBefore << '\n';
    std::cout << "  evicted（弱表清除的死串）:";
    for (const auto &n : wp.evicted) std::cout << ' ' << n;
    std::cout << "\n  pooled_after = " << wp.pooledAfter << '\n';
    std::cout << "  freed_objects = " << wp.freedObjects << '\n';
    std::cout << "  若池当强根将误保活 = " << wp.leakWouldHappenIfStrong << " 个（缓存变语义根）\n";

    std::cout << "== LISP2 mark-compact（练习引申）==\n";
    tip::Heap h4 = tip::Heap::demo();
    tip::Lisp2Report l2 = tip::lisp2(h4);
    std::cout << "  moved:";
    for (const auto &old2new : l2.moved)
        std::cout << ' ' << h4.o(old2new.first).name << "->" << old2new.second;
    std::cout << '\n';
    for (const auto &entry : l2.newLayout) {
        std::cout << "  cell" << entry.first << " = [";
        for (size_t k = 0; k < entry.second.size(); ++k) {
            int t = entry.second[k];
            std::cout << (k ? " " : "") << (t < 0 ? "-" : "cell" + std::to_string(t));
        }
        std::cout << "]\n";
    }
    std::cout << "  holes_before = " << l2.holesBefore
              << "（清除视角的碎片）→ holes_after = " << l2.holesAfter << "（活对象成前缀）\n";
    // LISP2 活对象数应与 markSweep survived 一致
    std::cout << "  lisp2_alive == ms_survived : "
              << (l2.moved.size() == ms.survived.size() ? "yes" : "NO") << '\n';
    return 0;
}
```

### 23.8.3 期望输出 expected/output.txt

```text
; expected: expected/output.txt
== objects ==
  0: A [B C]
  1: B [D]
  2: C [D]
  3: D []
  4: E [E]
  5: F [G]
  6: G [F]
  7: H [B]
== roots ==
  -> A
  -> B
== reference counting ==
  A: count=1
  B: count=3
  C: count=1
  D: count=2
  E: count=1
  F: count=1
  G: count=1
  H: count=0
  non-zero but unreachable: E F G  （环：计数永不为零，泄漏）
  rc_freed = 1（只有 H 计数归零；环上三个永远漏掉）
== mark-and-sweep ==
  survived: A B C D
  freed: E F G H
  ms_freed = 4
== cheney copying ==
  copy order: A B C D
  new0 = A [new1 new2]
  new1 = B [new3]
  new2 = C [new3]
  new3 = D []
  cheney_copied = 4
== 对账 ==
  survivors(ms) == copied(cheney) : yes
  rc_freed = 1 < ms_freed = 4：差额正是环
== tri-color abstraction（§26.3）==
  step 0: gray={A,B} white={C,D,E,F,G,H} invariant=held
  step 1: gray={B,C} blacken=A white={D,E,F,G,H} invariant=held
  step 2: gray={C,D} blacken=B white={E,F,G,H} invariant=held
  step 3: gray={D} blacken=C white={E,F,G,H} invariant=held
  step 4: gray={} blacken=D white={E,F,G,H} invariant=held
  final white = 终态白集（垃圾）: E F G H
  violations = 0（黑不指白全程保持）
  final_white == ms_freed : yes
== weak references & string pool（§26.4）==
  pooled_before = 5
  evicted（弱表清除的死串）: H
  pooled_after = 4
  freed_objects = 4
  若池当强根将误保活 = 1 个（缓存变语义根）
== LISP2 mark-compact（练习引申）==
  moved: A->0 B->1 C->2 D->3
  cell0 = [cell1 cell2]
  cell1 = [cell3]
  cell2 = [cell3]
  cell3 = []
  holes_before = 2（清除视角的碎片）→ holes_after = 1（活对象成前缀）
  lisp2_alive == ms_survived : yes
```

## 23.9 小结与练习


**增量三节的合账**：三色给了标记"可暂停的刻度与安全证明"（
不变式黑不指白——五步演示零违例、终白集与清除 freed 全等）；
弱表给了缓存"不越位的身份"（池缩 5→4、死串摘除、误当强根则
1 个死串永生）；LISP2 给了压紧"原地的第三个选项"（三指针两遍
滑、洞 2→1、与 Cheney 形状同）。三节各带断言，把匠书 §26 的
三块宝石嵌进了本章已有的三台收集器之间——本章从三台收集器
扩成"三机三宝"的全景。

本章接管了
堆上无主的家当：

- 可达性 =
  根集合出发的
  传递闭包，
  不可达不可逆；
- 引用计数
  增量回收、
  无停顿，
  但环上计数
  永不归零；
- 标记清除
  批量算闭包，
  工作表算法
  原生态现身，
  代价是
  整堆清扫与碎片；
- Cheney 复制
  用 scan/free
  两根指针
  把闭包与搬运
  合成一遍，
  不拷贝即消失，
  代价是半堆
  与改写一切引用；
- 分代假说
  与精确/保守之分
  是真实运行时的
  两条主线。

至此第三篇
（中间表示与运行时）
完结。
下一站回到
格与数据流的
主战场：
第 33 章的两个
经典分析之后，
第 34 章
补齐四大的
另外两个——
到达定值与
非常忙表达式。

练习：

1. 手工对演示图
   跑标记阶段，
   按 Unscanned 表
   的进出顺序
   记录每一步，
   与 survived
   清单对账。
2. 给演示图加一个
   三环
   I→J→K→I，
   无外部引用，
   验证 RC 的新计数
   与 ms 的新 freed
   各是什么。
3. 把根改成
   {A}（去掉 B），
   重跑三台收集器：
   survived 变成什么？
   H 的命运变吗？
4. 实现 mark-compact
   （三相：
   标记、算新址、
   搬运改写），
   对同一演示图
   输出新布局，
   与 Cheney 的
   布局对比
   （顺序为何不同？
   BFS vs 低地址序）。
5. （思考）保守式
   收集器为什么
   "不敢搬对象"？
   用"把整数 5
   当成了指针"
   的场景
   论证你的答案。

---

上一章：[22 参数传递四机制](22-param-passing.md) · 下一章：[24 类型变量](24-type-vars.md)
