# 21 · 迭代器

前两个行为型模式都在"解耦请求"，迭代器解耦的是更基础的东西：**遍历**。GoF 5.4 节的定义：**提供一种方法顺序访问一个聚合对象中的各个元素，而又不暴露该对象的内部表示**。在 1994 年这个定义是革命性的；在 ranges 时代的 C++23，它需要重读一遍——标准库把迭代器做成了语言级基础设施，自定义迭代器还剩什么职责、什么场景值得手写，是本章真正要回答的问题。

## 意图与动机

二叉搜索树是最能说明问题的容器：数组遍历是 `for i in 0..n`，链表是 `for p = head; p; p = p->next`，树呢？中序遍历要么递归（遍历状态藏在调用栈里，走到一半暂停不了），要么自己在循环里维护一个显式栈。**"怎么走"的知识膨胀成了使用者的负担**——每个想遍历树的调用方都得懂中序。迭代器模式把这份知识收进一个对象：容器说"我从 begin 开始、到 end 结束、++ 是走下一步"，剩下的交给 range for。

## 经典写法：栈式中序迭代器

示例 `tree.hpp`。树容器与迭代器分离——容器管存储，迭代器管遍历状态：

```cpp
template <class T>
class Tree {
public:
    void insert(const T& val) { root_ = insert_(root_, val); ++size_; }

    // ---- 中序迭代器：栈式递归展开（显式栈代替调用栈） ----
    class inorder_iterator {
    public:
        using value_type = T;
        using difference_type = std::ptrdiff_t;
        using reference = const T&;
        using iterator_concept = std::forward_iterator_tag;

        explicit inorder_iterator(TreeNode<T>* root) {
            push_left(root);            // 初始：最左路径全部入栈
        }

        reference operator*() const { return stack_.back()->v; }

        inorder_iterator& operator++() {
            auto* node = stack_.back();
            stack_.pop_back();
            if (node->r) push_left(node->r);   // 右子树的最左路径入栈
            return *this;
        }
    private:
        void push_left(TreeNode<T>* n) {
            for (; n; n = n->l) stack_.push_back(n);
        }
        std::vector<TreeNode<T>*> stack_;
    };
};
```

算法三句话：**构造时把最左路径全部入栈（栈顶即最小元）；`++` 弹栈，然后把右子树的最左路径入栈；栈空即遍历完**。这是"递归转迭代"的标准手法——调用栈里的遍历状态被搬到 `stack_` 成员里，于是遍历可以暂停、可以比较、可以被 range for 接管。结束比较用 C++20 的哨兵：

```cpp
bool operator==(const inorder_iterator&) const = default;

// 与哨兵比较：栈空即遍历完——哨兵无状态，状态全在迭代器里
bool operator==(std::default_sentinel_t) const { return stack_.empty(); }

[[nodiscard]] inorder_iterator begin() const { return inorder_iterator(root_); }
[[nodiscard]] std::default_sentinel_t end() const { return std::default_sentinel; }
```

`end()` 返回 `default_sentinel` 而不是又一个迭代器——**"结束"不需要状态**，造一个空迭代器去和真迭代器比相等，是老式 `end()` 的历史包袱。这是 C++20 ranges 带给自定义迭代器的第一份礼物。运行侧（`main.cpp`）：

```cpp
Tree<int> tree;
for (int v : {50, 30, 70, 20, 40, 60, 80}) tree.insert(v);

std::vector<int> inorder;
for (int v : tree) inorder.push_back(v);          // 范围 for：迭代器的消费端
assert((inorder == std::vector<int>{20, 30, 40, 50, 60, 70, 80}));
```

运行输出：

```text
迭代器: 乱序插入 7 个，中序 = 20 30 40 50 60 70 80
迭代器: default_sentinel 哨兵比较有效
ranges: views::filter 串接自定义迭代器 -> 20 40 60 80
```

三段断言分别验证：乱序 7 个的中序严格升序（遍历语义正确）；`begin() != sentinel`、消费完 7 个后 `== sentinel`（哨兵比较有效）；`tree | std::views::filter(...)` 直接工作（自定义迭代器获得了 ranges 生态的全部组合能力——这是迭代器概念（concept）带来的，不写五个 associated type 之一都拿不到）。

## 模式结构（ASCII 类图）

```text
  调用方 ──range for──> Tree<T>
                         │ begin() / end()
                         ▼
              ┌─────────────────────┐        ┌──────────────────┐
              │ inorder_iterator    │  !=    │ default_sentinel │
              │ *  ++(走中序下一步) │ ─────> │ （哨兵：无状态） │
              │ stack_: 遍历状态    │        └──────────────────┘
              └─────────────────────┘
                         │ 指向
                         ▼
                 TreeNode<T>* （内部表示——调用方看不见）
```

GoF 五角色：Iterator（inorder_iterator）、Aggregate（Tree）、ConcreteIterator/ConcreteAggregate 各一，Client 是 range for。关键注释一句：**调用方只认识 `*` 与 `++`，永远不碰 `TreeNode`**——"不暴露内部表示"的承诺由迭代器类型兑现。

## 现代写法：协程生成器

如果遍历逻辑能写成顺序代码，为什么还要显式栈？C++23 的 `std::generator` 把"管理游标"降级成"yield 一个值"（`gen.hpp`）：

```cpp
inline std::generator<int> fib_gen(int n) {
    int a = 0, b = 1;
    for (int i = 0; i < n; ++i) {
        co_yield a;              // 暂停点：把 a 交给消费者
        int next = a + b;
        a = b;
        b = next;
    }
}
```

对比中序迭代器的三句话算法加一个显式栈，生成器版本里**没有迭代器对象、没有状态类、没有 begin/end**——协程帧就是遍历状态，`co_yield` 就是 `operator++` + `operator*` 的合体。运行输出第四行验证 fib 前 8 项 `0 1 1 2 3 5 8 13`。那树的生成器版呢？

```cpp
// 思路示意：递归函数 + co_yield，中序逻辑回归自然形态
std::generator<int> inorder(const TreeNode<int>* n) {
    if (!n) co_return;
    co_yield std::ranges::elements_of(inorder(n->l));  // 左
    co_yield n->v;                                     // 根
    co_yield std::ranges::elements_of(inorder(n->r));  // 右
}
```

`std::ranges::elements_of` 把子协程"平铺"进当前输出序列——递归遍历写回了教科书形态。两版取舍：生成器赢在**写法自然**（遍历逻辑即函数体），经典迭代器赢在**零开销与可拷贝**（协程帧是堆分配的，迭代器的栈也可以在堆上，但没有协程的挂起/恢复机制）。遍历逻辑复杂且会变化时（多序、过滤、合并），生成器显著更省心；性能攸关的容器内建迭代器仍走经典路线——标准库自己的容器就是这么做的。

## 内部迭代器：C++ 的缺席

GoF 把迭代器分成两类：**外部迭代器**（客户驱动 `++`，本例形态）与**内部迭代器**（容器自己走，把每个元素喂给客户给的回调）。Ruby/Smalltalk 的 `each`、C++ 标准库的 `std::for_each` 某种意义上都是内部迭代器：

```cpp
// 内部迭代器：容器管遍历节奏，客户只出"对每个元素做什么"
template <class T, class F>
void for_each(const Tree<T>& t, F&& f) {
    for (const auto& v : t) f(v);      // 借外部迭代器实现——但客户只见回调
}
// 使用：for_each(tree, [](int v) { ... });
```

C++ 生态里内部迭代器始终没成主流，原因是结构性的：C++ 的控制流不可从回调中"跳出"到调用方——找到就停（break）、短路求值、早退，在回调模型里都要靠异常或标志位模拟，而外部迭代器的 `!=` 与 `++` 天然支持这些。ranges 用**视图组合**给出了第三条路：`tree | views::filter(...)` 把"找到就停"表达成惰性序列的贪心消费，既不是回调也不是裸循环。三形态对照：

| | 外部迭代器 | 内部迭代器 | ranges 视图 |
|---|---|---|---|
| 遍历控制权 | 客户 | 容器 | 客户（惰性拉取） |
| 提前终止 | `break` / 哨兵 | 难（异常/标志模拟） | 消费到哪停到哪 |
| 组合能力 | 手写嵌套循环 | 回调嵌套地狱 | `|` 管道自由串接 |
| C++ 生态 | 标准容器 / 本章 | `for_each` 边缘 | ranges 主流 |

## 生成器的惰性边界

`fib_gen(8)` 看着像"返回一个 vector"，实际语义差别巨大：**协程体在第一次迭代前一行都没执行**。验证惰性只需要观察时序——把 `co_yield` 前后各放一个计数器（或想象无限序列）：

```cpp
// 无限序列是生成器的杀手锏——经典迭代器表达"无限"很别扭
inline std::generator<int> naturals() {
    for (int i = 0;; ++i) co_yield i;      // 永不返回，但消费端随时可停
}
// 用法：naturals() | std::views::take(5) —— 拉取式求值：要 5 个才算 5 个
```

惰性由**拉取协议**保证：range for 每次要一个值，协程才从暂停点推进到下一个 `co_yield`。消费端不要，生产端就不算——这与第 16 章代理的"用到才构造"是同一思想在序列上的投影。警惕一个坑：`for (int v : naturals())` 没有 `take` 就死循环——生成器不知道消费端要几个，`n` 参数（如 `fib_gen(int n)`）其实是把"停"的责任推回给生产端，`views::take` 才是把责任交给消费端的形态。两者选哪个看"知道要多少"的知识在谁手里。

## ranges 时代手写迭代器还剩什么

给一张"什么时候还值得手写"的判定表：

| 场景 | 结论 |
|---|---|
| 容器是连续/链式内存 | 直接 `std::vector`/`std::list` + 标准迭代器，别手写 |
| 遍历逻辑 = 顺序生成值 | `std::generator` 协程（本章现代写法） |
| 已有 range 串接可得 | `views::transform/filter/join` 组合，零新类型 |
| 非线性结构（树/图）+ 性能敏感 | 手写迭代器（本章经典写法）——显式栈比协程帧便宜 |
| 要接入 ranges 算法生态 | 两者都行，但须满足 `forward_iterator` 概念的 associated type |

迭代器模式没有过时，它**下沉**了：从"设计模式"降维成"语言基础设施"，你写自定义迭代器时享受的每一分组合能力（range for、views、算法），都是这个模式标准化后的利息。

## 陷阱清单

1. **迭代器失效**（现象：遍历中 insert/delete 容器，迭代器悬空或跳元素；原因：底层存储变了，栈里的 `TreeNode*` 失效；后果：UB。对策：树这种结点式结构天然稳定（结点地址不随插入变），vector 型容器要么在文档里声明失效规则，要么遍历中拒绝修改）。
2. **`Tree(const Tree&) = delete;` 吃掉默认构造**（现象：C2512 无法构造；原因：声明拷贝删除 = 声明了构造函数，抑制隐式默认构造——编译器只在"什么构造函数都没声明"时才送默认构造；后果：对象造不出来。对策：删拷贝的同时显式补 `Tree() = default;`（tree.hpp 有注释标记））。
3. **忘记 iterator_concept/五个 associated type**（现象：`views::filter` 编译不过，报 concept 不满足；原因：ranges 用 `iterator_concept`/`iterator_category` 判断迭代器强度；后果：串接失败。对策：至少写 `value_type`、`difference_type`、`reference`、`iterator_concept` 四件套——少一个都不行）。
4. **哨兵类型不对齐**（现象：拿 `end()` 返回的迭代器去赋值遍历变量；原因：哨兵与迭代器类型不同，不能互赋；后果：编译错误（本例 `it = tree.end()` 类型不符）。对策：哨兵只用于比较，遍历变量从 `begin()` 来）。
5. **拷贝迭代器共享状态**（现象：拷贝一份迭代器"存档"，继续推进原件后发现存档也动了；原因：栈里存的是裸 `TreeNode*`，浅拷贝指向同一序列；后果：多-pass 算法错乱。对策：`operator==` 用 `= default` 比栈内容（本例如此），需要真正独立的遍历快照时深拷贝或重新 begin）。

## 三书对应

- 之禅：第 20 章"迭代器模式"（20.2 定义、20.3 应用——项目经理分派任务的比喻、20.4 扩展——"谁用谁less"讨论主动让迭代器退居标准库、与本章"下沉"论呼应）。
- 刘伟：第 20 章"迭代器模式"（20.1 动机与定义、20.2 结构与分析——内外部迭代器之分（本例是外部迭代器：遍历权在客户）、20.3 实例——电视遥控器频道遍历、20.5 扩展——与 STL 迭代器的关系）。
- GoF：第 5 章 5.4 节 Iterator——List 例与"谁控制迭代（外部/内部）、谁定义遍历算法、迭代器健壮性（Robust Iterators）"，其中健壮性一节正是本章陷阱 1 的源头讨论。

*可选延伸：可运行示例见 examples/21_iterator/。*
