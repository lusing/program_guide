# 36 · Effective STL：50 条精要的现代解读

> 对应示例：`examples/36_effectivestl/`；参考书：Scott Meyers《Effective STL 中文版：50 条有效使用 STL 的经验》（2001）

## 36.1 为什么 2026 年还要读一本 2001 年的书

三个理由。**其一**，大部分条款讲的是"数据结构 + 复杂性权衡 + 失效规则"层面的工程判断——标准改不掉它们。**其二**，书中好几条预言了未来：第 25 条盼望的哈希容器成了 C++11 的 `unordered_*`，第 24 条手写的 `efficientAddOrUpdate` 被 C++17 标准化为 `try_emplace`/`insert_or_assign`，第 23 条"排序 vector 替代关联容器"就是 C++23 的 `flat_map`。**其三**，少数条款已经成了历史本身（`auto_ptr`、`bind2nd`、COW string），读它们的价值变成"知道为什么今天不这么写"。

本章按原书 7 章的顺序过全部 50 条，每条给一句话精要加 C++23 视角的裁决：

- ✅ **仍成立**——照做；
- 🔁 **已有标准答案**——老问题有了新姿势；
- ⚰️ **已成历史**——原因消失了，认得即可。

示例程序挑了最容易翻车的十几条做可运行验证（输出全部是确定值）。

## 36.2 容器通则（条 1–12）

**条 1 慎重选择容器类型 ✅**。核心思维模型是"**连续内存 vs 基于节点**"：vector/string/deque 元素挤在一块内存里，插入删除要挪动别的元素、扩容全体失效，但缓存友好；list/map/set 每个元素一个节点，插入删除只动指针、迭代器永不失效（指向被删元素除外），但空间开销大、缓存不友好。选型问题清单一句话版：要任意位置插 → 序列容器；要有序 → 树容器；要极速点查 → 哈希容器；要 C 布局兼容 → 只有 vector；要迭代器稳定 → 节点容器。第 14 章的选型总表是它的现代版。

**条 2 不要编写容器无关代码 ✅**。"vector 换成 list 不改代码"的执念会让代码退化成所有容器的交集：没 `reserve`、没 `[]`、没随机访问排序、假设一切操作全失效。正解是**封装**：`using Customers = std::vector<Customer>;` 起步，认真了就包成类。25 年后 ranges 也没改变这条——不同容器的失效规则与复杂度差异依然真实。

**条 3 确保容器中对象的拷贝正确而高效 ✅**。存进容器的是**拷贝**，不是你给它的那个对象；排序、插入搬移、remove 还会继续拷。两个经典翻车：拷贝贵的对象塞满容器 → 性能塌方；基类容器装派生对象 → **切片**（示例 36.1：`Derived` 进 `vector<Base>` 后 `name()` 变回 `"Base"`）。现代答案：移动语义（22 章）让搬运代替拷贝、`emplace_back` 原地构造、多态场景一律智能指针容器（24 章）。

**条 4 用 empty() 而不是 size()==0 ⚰️（原因消失，写法仍推荐）**。原书的理由是 list 的 `size()` 可能线性——C++11 起标准强制**所有**容器 `size()` 都是 O(1)（list 拿"区间 splice 变成线性"换的）。今天这条只剩语义价值：问"空不空"就写 `empty()`。

**条 5 区间成员函数优先于单元素循环 ✅**。`assign(first, last)`、`insert(pos, first, last)`、区间 `erase`、迭代器对构造——一个循环逐个 `push_back` 相比，少一串函数调用，更重要的是连续容器**一次挪到位**（逐个插入最坏 O(n·m) 次搬移，区间版 O(n+m)）。示例 36.2：`half.assign(src.begin() + 3, src.end())` 一行拷后半。现代延伸：`ranges::to`（19 章）把视图收进容器也是这个思路。

**条 6 当心最烦人的解析 ✅**。`std::vector<int> data(std::istream_iterator<int>{in}, std::istream_iterator<int>());` 声明的是一个**返回 vector 的函数**——能解析成函数声明的就一定是函数声明。C++11 的修复是花括号加命名哨兵（示例 36.3）：

```cpp
std::istream_iterator<int> read{nums_in}, eof{};
std::vector<int> parsed{read, eof};   // {} + 命名迭代器，双保险
```

**条 7/8/33 指针容器三兄弟 → 智能指针一站式 🔁**。原书三条打一套组合拳：裸 new 指针容器忘了 delete 就泄漏（7）；`auto_ptr` 容器是未爆弹（8）；`remove_if` 会用保留元素覆盖被删指针、覆盖完连 delete 的机会都没了（33）。今天的答案一行：**`std::vector<std::unique_ptr<T>>`**——析构自动 delete、move-only 照常排序搬移、`std::erase_if` 直接删元素连带销毁对象。示例 36.4 用构造/析构计数器验证：`构造 5 次 == 析构 5 次 → 泄漏 0`。（`auto_ptr` 本体已在 C++17 删除。）

**条 9 慎重选择删除方式 🔁（std::erase_if 统一，细节仍要懂）**。原书要按容器类型背三张表（vector 用 erase-remove、list 用成员 remove、关联容器用 erase），C++20 的 `std::erase_if(c, pred)` 把三种容器一行统一。仍在的两条细节：边遍历边删的循环里，序列容器要用 `erase` 的**返回值**接住下一迭代器；关联容器的 `erase(it)` 从 C++14 起也返回下一迭代器了（原书写作"返回 void"——已过时）。

**条 10/11 了解分配子 ⚰️→🔁**。老 allocator 的 `pointer/reference` typedef、"同类型分配子必须等价"（即不可有状态）等怪规矩，C++11 后大幅冷门化。真要定制内存（ arenas、共享内存、池），现代路线是 C++17 的 `std::pmr::memory_resource` + `pmr::vector`——策略挂在**资源**上而不是分配子类型上。教程主线用不上，认得这个词即可。

**条 12 对线程安全不要有不切实际的期望 ✅**。能指望的只有两条：多线程**同时读**同一容器安全；多线程写**不同**容器安全。其余（边读边写、并发写同一容器）都要自己上锁（28 章的家伙事）。25 年不变，因为"算法/迭代器拿不到容器"这个结构性原因没变。

## 36.3 vector 与 string（条 13–18）

**条 13 vector/string 优先于动态分配的数组 ✅**。`new T[n]` 三宗罪（忘 delete、delete/delete[] 配错、重复 delete）第 05 章领教过。原书留了个口子——多线程下引用计数 string 可能更慢——这个口子下面一条就关死了。

**条 14 用 reserve 避免不必要的重新分配 ✅**。四件套分清：`size()` 元素数、`capacity()` 容量、`resize(n)` 改元素数、`reserve(n)` 只改容量。扩容 = 分配新内存 + 搬移 + 析构旧元素 + 释放，且全体迭代器/指针/引用失效。示例 36.6 的确定性验证：`reserve(1000)` 后连 push 1000 次**数据指针不动**；不 reserve 的对照组指针必然搬过家。已知终点规模就先 reserve，是 vector 的基本礼仪。

**条 15 注意 string 实现的多样性 ⚰️**。原书对比四种实现（引用计数 COW、SSO……），今天可以直接写结论：**C++11 把 `data()`/`c_str()` 定为 O(1) 且要求内存连续，判了 COW string 死刑**；三大标准库清一色 SSO（短串存在对象内部，长串一次分配）。留两条常识：`sizeof(std::string)` 不是字符数（典型 24–32 字节）；短串构造零堆分配。

**条 16 了解如何把 vector/string 数据传给 C API ✅**。vector 的内存与数组布局兼容：`v.data()`（C++11，比 `&v[0]` 安全——空容器也能调，只是不可解引用）配 `v.size()` 送 `(const T*, size_t)` 接口；string 用 `c_str()`——它保证 NUL 结尾，`data()` 在 C++11 起也保证（C++17 起非 const 版亦然）。示例 36.7。反向（C 缓冲区进容器）用迭代器对构造。

**条 17 用 swap 技巧除去多余容量 🔁**。`std::vector<T>(v).swap(v)` 的经典咒语在 C++11 转正为 `v.shrink_to_fit()`（非强制请求，但主流实现都照办；示例 36.6 实测 `capacity == size`）。顺带 swap 的常忘特性：交换后**迭代器/指针仍然有效**，只是"跟到了对面容器里"（string 是唯一例外）。

**条 18 避免使用 vector\<bool\> ✅**。它不存 bool、存打包的位，`operator[]` 返回的是**代理对象**不是 `bool&`——所以 `&v[0]` 编不过、不是连续容器（示例 36.8 用 `static_assert` 验明正身）。要真 bool 数组用 `deque<bool>`/`vector<char>`，定长位图用 `bitset`。这是"代理容器"的活教材，C++11 特性墙 (`requires`) 反而更容易把它挡在模板外了。

## 36.4 关联容器（条 19–25）

**条 19 理解相等与等价的区别 ✅（全书中最重要的一条）**。`find` 算法用**相等**（`operator==`）判"相同"；有序关联容器用**等价**（`!comp(a,b) && !comp(b,a)`）判"相同"。两者可以给出不同答案——示例 36.9 的忽略大小写 set：

```cpp
ci_names.insert("Persephone");   // 第二个 "persephone" 与它等价 → 拒绝，size == 1
ci_names.find("PERSEPHONE");     // 成员 find 按等价 → 找到
std::find(begin, end, "PERSEPHONE");   // 算法 find 按相等 → 找不到
```

为什么用等价：容器只有一份比较函数，靠它既定序又判同——两套标准（一个排序一个判等）会在"插不插、以什么序遍历"上自相矛盾。哈希容器则用相等（见条 25）。查关联容器一律用**成员** `find`/`contains`（44 条）。

**条 20 为指针关联容器指定比较类型 ✅**。`set<string*>` 默认按**指针值**排——书里那句"看到字母序的概率是 1/24"的幽默依然成立。给一个解引用比较器（示例 36.10），或者干脆存值/智能指针（`unique_ptr` 配 `owner_less`）。

**条 21 总是让比较函数在等值时返回 false ✅**。比较器必须**严格弱序**：`comp(x, x)` 必须为 false。`less_equal` 当比较器 → 两个 10 互相"不等价"→ set 里出现重复值、`equal_range` 行为错乱，且是 UB 不是异常。体检一行：`static_assert`/运行时断言 `!comp(x, x)`（示例 36.9 顺带演示 `less(10,10)=false` 合格、`less_equal(10,10)=true` 不合格）。第 15 章坑位 4 的 sort 越界是同一病灶。

**条 22 切勿直接修改 set/map 中的键 ✅（老坑已补新路）**。改键会破坏有序性。两个更新：C++11 起标准明确 set/multiset 迭代器解引用是 `const T&`（原书吐槽的"碎玻璃"实现分歧已被拍死，想改编译不过）；C++17 的 **`extract` 节点句柄**是改键正道——把节点整个拔出来、`node.key() = 新值`、再 `insert` 回去，值对象不搬窝（示例 36.11）。map 的键是 `const K`，永远别 `const_cast`。

**条 23 考虑用排序 vector 替代关联容器 🔁（C++23 flat_map 兑现）**。"设置阶段插一堆 → 查找阶段只查不插"的三段式负载下，排序 vector 的二分查找比红黑树更快更省（节点容器的每元素 3 指针开销 + cache miss）。原书要你手写 pair 比较器模拟 map；今天直接 `std::flat_map`/`flat_set`（14.7 已实测）——底层就是排序 vector。通用负载仍用 map/unordered_map。

**条 24 效率关键时区分 map::operator[] 与 insert 🔁（C++17 标准化了正解）**。`m[k] = v` 对不存在的键走的是"**默认构造 + 赋值**"两步；`m.emplace(k, v)` 一步直达。原书手写了一个 `efficientAddOrUpdate`（lower_bound + 等价测试 + hint insert）；C++17 把这个轮子标准化成两个语义清晰的半轮：

```cpp
auto [it, ok] = m.try_emplace(k, args...);   // 只添加：撞已有键不动手（实参保证不被搬空）
m.insert_or_assign(k, v);                    // 只更新或覆盖
```

示例 36.12 验证了 try_emplace 的合同：插入失败时 `std::move` 过去的实参**原封未动**。顺带 `operator[]` 还有个静态限制：值类型必须可默认构造，否则编译错。

**条 25 熟悉非标准散列容器 ⚰️（预言兑现）**。`hash_set`/`hash_map` 在 C++11 以 `unordered_set`/`unordered_map` 之名进标准（SGI/Dinkumware 两套方言之争成为历史）。一个值得记住的语义差异：有序容器判同用**等价**（一份比较函数），unordered 判同用**相等**（hash 函数 + KeyEqual 两件套）——第 19 条在哈希世界换了答案。

## 36.5 迭代器（条 26–29）

**条 26 iterator 优先于 const_iterator ⚰️（建议反转）**。原书推荐 iterator 的三个原因（insert/erase 只收 iterator、const_iterator 转不回 iterator、混用比较编不过）全被 C++11 拆了：`cbegin()/cend()` 诞生、insert/erase 接受 const_iterator、混合比较合法。今天的建议正相反：**能用 const_iterator 就用**——const 正确性优先，range-for 天然走这条路。

**条 27 用 distance/advance 转换 const_iterator ⚰️（已消亡）**。上一条的直接后果：不需要转了。顺带记住 16 章的提醒——`distance` 在链表类容器上是走着数的 O(n)。

**条 28 正确理解 reverse_iterator::base() ✅（仍是细思恐极的那一类）**。`base()` 给的迭代器**未必是你想要的那个**：

- **插入**：就在 `ri.base()` 处插——与"在 ri 处插"等价；
- **删除**：要删 ri 所指元素，得删 `std::next(ri).base()`（偏一格）。

示例 36.13 全程演示：`1 2 3 4 5` 上插 99 得 `1 2 3 99 4 5`，再删 3 得 `1 2 99 4 5`。口诀：**插用 base，删偏一格**。日常少写反向迭代器（`views::reverse` 更好读），但读到别人的代码时这一条救命。

**条 29 逐字符输入考虑 istreambuf_iterator ✅**。`istream_iterator<char>` 走格式化抽取（跳空白、sentry 开销一套全走）；`istreambuf_iterator<char>` 直读流缓冲区，空白一个不丢、还更快。示例 36.14：同一串 `"a b  c"`，前者视角 3 个词，后者原样 `[a b  c]`。输出侧对偶物是 `ostreambuf_iterator`。

## 36.6 算法（条 30–37）

**条 30 确保目标区间足够大 ✅**。算法往目标区间**赋值**，不插元素：`transform(src.begin(), src.end(), dst.begin(), f)` 的 dst 若是空容器 → 写 UB。两条正路：目标先 `resize`，或用插入迭代器 `std::back_inserter(dst)`（16.5）。

**条 31 了解与排序有关的选择 ✅（这张地图 25 年没过时）**。按"要多少排多少"选工具：

| 需求 | 算法 | 排序量 |
|---|---|---|
| 全序 | `sort` / `stable_sort` | O(n log n) |
| 前 n 名**且这 n 名内部有序** | `partial_sort` | O(n log m) |
| 前 n 名即可（或中位数/百分位） | `nth_element` | O(n) |
| 只按条件分两堆 | `partition` / `stable_partition` | O(n) |

性能排序 partition < nth_element < partial_sort < sort < stable_sort（越往下越贵）。示例 36.15：9 个数上 `partial_sort` 出有序前三、`nth_element` 出第 5 小、`partition` 分出 ≤4 的前半截。都要随机访问迭代器——list 用成员 `sort()`（16.2）。

**条 32 remove 不删除元素，要删得再调 erase ✅**。`remove` 是 STL 第一错觉制造机：它拿不到容器（只拿迭代器对），**不可能**删元素——它把保留元素前压，返回"新逻辑尾"。示例 36.5 的三个铁证：`remove` 后 `size` 不变（7）、保留前缀 `[1 3 5 7]` 正确、新逻辑尾之后的"僵尸"值**未指定**（别打印它们）。收尾二选一：`v.erase(new_end, v.end())`（erase-remove 惯用法，读旧代码必备）或 `std::erase_if`（新代码首选）。`unique` 同理。

**条 33 对指针容器使用 remove 类算法要特别小心 ✅→🔁**。remove 覆盖掉的不合格指针再也找不回来 → 泄漏。两条路：先 delete 置空再清空指针（原书方案），或直接上智能指针容器（36.2 条 7 的方案，一条解决三条）。

**条 34 了解哪些算法要求排序区间 ✅**。背清单：**查找**`binary_search`/`lower_bound`/`upper_bound`/`equal_range`；**集合**`set_union`/`set_intersection`/`set_difference`/`set_symmetric_difference`/`includes`；**合并**`merge`/`inplace_merge`；习惯上还有 `unique`（去重的前提是相等元素相邻）。喂未排序区间**不报错、直接算错**（运行期未定义）。另一条纪律：给算法的比较函数必须与当初排序用的**同一个**——降序排的区间要带着 `greater{}` 去查。

**条 35 用 mismatch/lexicographical_compare 实现忽略大小写比较 ✅**。两个到手零件：`tolower` 前先把 char 转 `unsigned char`（负值 char 直接喂是 UB）；字符串级用 `std::lexicographical_compare(first1, last1, first2, last2, 字符判别式)`（示例 36.9 的 `ci_less`）。原书附录 A 的告诫依然有效：`tolower/toupper` 依赖**全局 locale**——只处理 ASCII 没问题；要国际化就得走 `std::locale` 的 ctype facet，且别做"忽略大小写的 string 类"，用**比较策略**参数化才是标准库的思路。

**条 36 理解 copy_if 的正确实现 ⚰️（标准补课了）**。原书教你手写 copy_if（HP STL 遗失件）——C++11 已收录。`copy_if(first, last, out, pred)` 今天随取随用。

**条 37 用 accumulate 或 for_each 做区间统计 ✅**。`accumulate`（`<numeric>`！条 48 高危）两种形态：纯求和，或带自定义折叠函数。三个坑我们实测过两个：**初始值决定累加类型**（示例 36.17：`{1.5, 2.5}` 用初值 `0` 得 3、`0.0` 得 4）；折叠函数**不许有副作用**（标准原文级要求）。要带状态统计就用 `for_each`——它把 functor 的**拷贝**返回给你，状态从返回值带出（示例的 `Averager`）；并行场景用 `transform_reduce`（17/29 章）。

## 36.7 函数子（条 38–42）

**条 38 函数子按值传递设计 ✅（lambda 闭包同理）**。算法把 functor **拷着**传来传去（`for_each` 的签名进也 Functor 出也 Functor）。推论至今成立：闭包要小巧（拷贝有价）、别多态（拷贝会切片）；大状态用"指向实现的指针"（Bridge/Pimpl）。有状态 functor 的合法取状态通道是**返回值**（条 37）。

**条 39 确保判别式是纯函数 ✅（这条违反是 UB）**。谓词 = 返回 bool 的函数；纯函数 = 结果只依赖实参。原书的恐怖案例：带"第三次调用返回 true"状态的谓词交给 `remove_if`——remove_if 内部把谓词**拷贝**给 find_if 再拷贝给 remove_copy_if，两个副本各数各的，第三次和第六个元素一起被删。所以：谓词的 `operator()` 写 `const`、不碰 mutable/static/全局状态。C++11 并行算法时代这条只会更严。

**条 40 使函数子可配接 ⚰️**。`unary_function`/`binary_function` 基类、`argument_type` 系 typedef——为的是喂得进 `not1`/`bind2nd`。C++17 删了这对基类，C++20 删了 not1/not2：lambda 的**类型自动推导**让"配接"彻底自动化（`!` 直接写进 lambda 体）。

**条 41 理解 ptr_fun/mem_fun/mem_fun_ref ⚰️**。它们存在的唯一理由：C++ 有 `f(x)`、`x.f()`、`p->f()` 三种调用语法，而算法只认第一种。C++17 全数删除；现代写法 `std::mem_fn(&T::f)`、`std::invoke`，或者最直白的 lambda：`[](auto& w) { return w.test(); }`。名字里那段历史（先有 mem_fun 后有 mem_fun_ref）当作掌故听。

**条 42 确保 less\<T\> 与 operator\< 语义一致 ✅**。`less<T>` 的契约就是调 `operator<`——为"按别的字段排"去特化 `std::less` 是违背全体程序员的合理预期（最小惊奇原则）。想要不同排序：老老实实写个**名字不是 less** 的比较器传给容器模板参数。现代补强：`std::less<>`（透明比较器，C++14）解锁异构查找——`set<std::string>` 能用 `"literal key"` 查而不构造临时 string。

## 36.8 综合运用（条 43–50）

**条 43 算法调用优先于手写循环 ✅（ranges 把它推得更远）**。三大收益：**效率**（实现者懂容器内部，deque 特化版快 20%）、**正确性**（手写循环的迭代器失效雷区——原书的 deque insert 例子一错再错才对）、**可维护性**（算法名即语义，`for` 只是"某种循环"）。原书同时承认的边界今天依然成立：一行循环能说清的事，别为它搭配接器脚手架。现代注脚：书里要 `compose2(logical_and, bind2nd(greater, x), bind2nd(less, y))` 的"找区间内的数"，lambda 捕获两行解决（示例 36.17）；ranges 管道（19 章）让"算法优先"升级成"管道优先"。

**条 44 容器的成员函数优先于同名算法 ✅**。两重理由：**快**（set::find O(log n) vs std::find O(n)，百万级元素 22 次 vs 50 万次比较）+ **对**（成员版用等价、只看键，与容器自身语义一致）。list 的同名成员（remove/remove_if/unique/sort/merge）还多一层：真删、不拷贝、只动指针。记忆桩：**关联容器查找用成员函数；`contains`（C++20）是存在性测试的终点形态**。

**条 45 区分 count/find/binary_search/lower_bound/upper_bound/equal_range ✅**。查找选型表（区间未排序 → 线性族；排序区间/关联容器 → 二分族）：

| 问题 | 未排序区间 | 排序区间 | 关联容器 |
|---|---|---|---|
| 在不在？ | `any_of`/`count` | `binary_search` | `contains`/`count` |
| 在哪 / 有几个？ | `find`/`find_if` | `equal_range` | `find`/`equal_range`（成员） |
| 插入点在哪？ | — | `lower_bound`/`upper_bound` | `lower_bound`（成员） |

两个细节：`lower_bound` 找到后判命中要用**等价**（`!comp` 两个方向）不是 `==`（否则条 19 反例打脸）；`equal_range` 一箭双雕（位置 + 个数 = `distance`）。示例 36.16 演示排序 vector 上的 equal_range。

**条 46 考虑用函数对象而不是函数作为算法参数 ✅**。函数指针是运行期间接跳转，编译器不敢内联；函数对象（lambda 闭包）的 `operator()` 内联展开后整个排序循环可做上下文优化——这是 `std::sort` 碾压 `qsort`（实测快 670%）的根因。今天这条自动满足：**写 lambda 就是在写函数对象**；只剩"别把 lambda 存进 `std::function` 再传给算法"（多一层擦除，能 `auto` 就 `auto`）这一条要注意。

**条 47 避免产生直写型代码 ✅**。一条语句十层嵌套配接器——写时酣畅，读时天书。lambda 与 ranges 消灭了 bind2nd 时代的天书，但**新的天书制造机是无限套娃的 views 管道**。原则不变：代码被读的次数远多于被写；按"读者能不能还原你的思路"来断句，复杂表达式拆成带注释的命名中间量。

**条 48 总是 #include 正确的头文件 ✅**。标准不保证标准头互相包含，"在这个平台编过"不等于"用对了头"。地图：容器在同名头（`<set>` 装 set+multiset，`<map>` 同理）；**accumulate/inner_product/adjacent_difference/partial_sum 在 `<numeric>`**（本教程实测过的坑）；迭代器适配器在 `<iterator>`；`less`/仿函数在 `<functional>`。26 章的模块把 `#include` 换成 `import`，"用对头"的要求一点没变。

**条 49 学会解读 STL 相关的编译器诊断 ✅**。三板斧翻译法：`basic_string<char, char_traits<char>, allocator<char>>` → 就是 string；`_Tree`/`_Rb_tree` → 就是 map/set 的内部实现模板；把一长串模板实参替换回你的 typedef 名，错误就露馅了（原书的案例：const 成员函数里 map 变 const map，iterator 拿不到——换成 const_iterator 即解）。现代改善：概念（21 章）让报错从"3000 字符模板天书"变成"不满足 xxx_constraint"；`static_assert` 可以把类型期望提前到编译期明说。

**条 50 熟悉 STL 相关网站 ⚰️（名单换血）**。SGI STL 与 STLport 已是数字遗迹（它们的遗产：调试迭代器思想、`hash_*`→`unordered_*`）；Boost 依然活跃（`shared_ptr`、`boost::container` 出过不少后来的标准件）。今天的正典：**cppreference.com**（人手一册）、Compiler Explorer（在线多编译器验证条 49 的诊断）、WG21 papers 追新特性。原书末尾介绍的 `select1st/select2nd`（取 pair 第一/第二成员）也有了标准替身——ranges 投影：`ranges::sort(v, {}, &Pair::second)`。

## 36.9 50 条速查总表

| 条 | 精要 | 裁决 |
|---|---|---|
| 1 | 慎重选容器：连续内存 vs 节点 | ✅ |
| 2 | 别写容器无关代码；typedef/类封装替代 | ✅ |
| 3 | 容器存拷贝：防切片、拷贝要廉价 | ✅ |
| 4 | empty() 代替 size()==0 | ⚰️ size 已恒 O(1) |
| 5 | 区间成员函数（assign/insert/erase）优先 | ✅ |
| 6 | 最烦人的解析：() 会声明函数，用 {} | ✅ |
| 7 | new 指针容器记得 delete | 🔁 unique_ptr 容器 |
| 8 | 禁止 auto_ptr 容器 | ⚰️ C++17 已删除 |
| 9 | 按容器选删除方式 | 🔁 erase_if 统一 |
| 10 | 了解 allocator 的限制 | ⚰️ → pmr 是新路 |
| 11 | 自定义 allocator 的合理用法 | 🔁 C++17 pmr |
| 12 | 线程安全：多读/异容器写之外自己锁 | ✅ |
| 13 | vector/string 优于 new[] | ✅ |
| 14 | reserve 防反复扩容 | ✅ |
| 15 | string 实现多样性 | ⚰️ COW 已死，SSO 一统 |
| 16 | data()/c_str() 传 C API | ✅ |
| 17 | swap 技巧收缩容量 | 🔁 shrink_to_fit |
| 18 | 避免 vector\<bool\>（代理容器） | ✅ |
| 19 | 等价（容器排序）≠ 相等（operator==） | ✅ |
| 20 | 指针关联容器给解引用比较器 | ✅ |
| 21 | 比较器等值必须返回 false（严格弱序） | ✅ |
| 22 | set/map 键只读；改键走 extract | ✅ C++17 节点句柄 |
| 23 | 排序 vector 替代关联容器 | 🔁 C++23 flat_map |
| 24 | 添加用 insert、更新用 operator[] | 🔁 try_emplace/insert_or_assign |
| 25 | 熟悉哈希容器 | ⚰️ C++11 unordered_* |
| 26 | iterator 优先于 const_iterator | ⚰️ 建议已反转 |
| 27 | distance/advance 转换 const_iterator | ⚰️ 已无必要 |
| 28 | reverse_iterator：插用 base、删偏一格 | ✅ |
| 29 | 逐字符输入用 istreambuf_iterator | ✅ |
| 30 | 目标区间要够大（或用插入迭代器） | ✅ |
| 31 | 排序选型：partition/nth/partial/sort | ✅ |
| 32 | remove 不删除，之后要 erase | ✅ |
| 33 | 指针容器慎用 remove 类算法 | 🔁 智能指针容器 |
| 34 | 记住哪些算法要排序区间 | ✅ |
| 35 | 忽略大小写：mismatch/lexicographical | ✅ |
| 36 | 手写 copy_if 的正确实现 | ⚰️ C++11 已收录 |
| 37 | 区间统计用 accumulate/for_each | ✅ |
| 38 | 函数子按值传递：小巧、单态 | ✅ |
| 39 | 判别式必须是纯函数 | ✅ |
| 40 | 函数子要可配接 | ⚰️ C++17/20 已删除 |
| 41 | 理解 ptr_fun/mem_fun | ⚰️ C++17 已删除 |
| 42 | less\<T\> ≡ operator\< | ✅ |
| 43 | 算法调用优先于手写循环 | ✅ |
| 44 | 同名时成员函数优先于算法 | ✅ |
| 45 | 查找算法选型表 | ✅ |
| 46 | 函数对象（lambda）优于函数指针 | ✅ |
| 47 | 避免直写型代码 | ✅ |
| 48 | 总是包含正确的头文件 | ✅ |
| 49 | 会翻译 STL 编译器诊断 | ✅ |
| 50 | 熟悉 STL 资源网站 | ⚰️ 名单换血：cppreference |

一句话收束：**50 条里大约七成原样成立**，它们共同织成一张"复杂度 + 失效规则 + 语义一致性"的网——这正是 STL 设计哲学（容器-迭代器-算法分工）自带的、不会随版本过期的那部分。剩下三成里，一半被标准演进**兑现**（unordered、flat_map、try_emplace、erase_if），一半被**扫进历史**（auto_ptr、配接器、COW）——淘汰它们的正是前七成教会你的判断力。

## 36.10 坑位清单

1. **remove/unique 不删元素**：size 不变、返回"新逻辑尾"、尾段值未指定——必须 erase 收尾或用 `std::erase_if`；打印 remove 后的尾段是靠不住的。
2. **同一容器两种"找到"**：忽略大小写 set 里成员 find（等价）命中、std::find（相等）落空——查关联容器只用成员函数/contains。
3. **`less_equal` 当比较器**：等值返回 true 违反严格弱序——set 出现重复、算法 UB。上线前体检 `comp(x,x) == false`。
4. **`map::operator[]` 添加走"默认构造+赋值"两步**，且要求值可默认构造；添加/更新各用其正名 `try_emplace` / `insert_or_assign`（撞键时前者保证实参不被搬空）。
5. **reverse_iterator 删除偏一格**：删 ri 所指要用 `std::next(ri).base()`，直接 `ri.base()` 删到的是隔壁；插入才用 base 本尊。
6. **vector\<bool\> 不是 bool 容器**：`operator[]` 是代理对象、不连续、`&v[0]` 编不过——真 bool 用 `deque<bool>`/`vector<char>`，定长用 `bitset`。
7. **`tolower`/`toupper` 前先转 `unsigned char`**：负值 char 直接喂是 UB；依赖全局 locale，非 ASCII 场景要走 `std::locale`。
8. **`accumulate` 的折叠函数不许有副作用**（标准原文级禁令），要带状态用 for_each 的返回 functor；初始值类型劫持累加类型（0.0 不是 0）。
9. **改 set/map 的键**：直接改破坏有序性（C++11 起 set 迭代器是 const 的，编不过）；正道是 `extract` 拔节点改 `key()` 再插回。
10. **排序区间算法喂了未排序区间**：binary_search/equal_range/set_*/merge 不报错、直接算错；且比较函数要与排序时用的同一个。
11. **`try_emplace`/`insert_or_assign` 与 `operator[]` 的语义差**：[] 是"没有就默认构造"（改写已有值+可能插默认值），两者是"只添加"与"添加或覆盖"——用词选错，行为差一截。
12. **const int 局部量在 lambda 里可免捕获**：带常量初值的 const 整型变量不需要捕获就能用（clang 的 `-Wunused-lambda-capture` 会点你名）；要演示捕获语义就用非 const。
