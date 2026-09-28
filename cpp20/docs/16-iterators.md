# 16 · 迭代器深入：类目、适配器与辅助函数

> 对应示例：`examples/16_iterators/`

## 16.1 迭代器是什么：容器与算法之间的胶水

第 14 章把迭代器当"指到容器某位置的通用把手"用过；本章把它当正主讲透。迭代器是**指针的泛化**：`*it` 取当前位置元素、`++it` 前进、`it != end()` 判终——range-for 只是把它隐式化了（编译器替你写 `for (auto it = c.begin(); it != c.end(); ++it)`）。

STL 的架构就压在它身上：**容器不认识算法，算法不认识容器，迭代器是中间的通用货币**。`std::sort` 能排 vector 也能排 deque，靠的是两边都只承诺"迭代器"这个抽象。代价也像指针：**不检查越界**——`begin() + 2` 越过 `end()` 之后再解引用是 UB，不是异常。

## 16.2 五大类目：算法的"入场券"

迭代器按能力分级，**算法按它需要的最低类目收票**：

| 类目 | 独有能力 | 代表容器 |
|---|---|---|
| 输入 / 输出 | 单遍读 / 单遍写 | 流迭代器（16.6） |
| 前向（forward） | 多遍 `++` | forward_list、unordered_* |
| 双向（bidirectional） | `--it` 后退 | list、map、set |
| 随机访问（random access） | `it + n`、`it[n]`、`it1 < it2` | vector、deque |
| 连续（contiguous，C++20） | 元素物理连续（span 的前提） | vector、array、string |

类目是**层层包含**的：双向包含前向的全部能力，以此类推。实际后果立刻有一个——**`std::sort` 只收随机访问迭代器**，所以 `std::sort(lst.begin(), lst.end())` 对 `list` 直接编译错（不是运行错），list 得用自己的成员函数 `lst.sort()`。这不是缺陷是设计：list 的链式存储跳着访问是 O(n)，快速排序的划分模式根本不划算。

C++20 起类目有了**概念**（第 21 章）版的名字，可以在编译期检查：

```cpp
static_assert(std::random_access_iterator<std::vector<int>::iterator>);   // 通过
static_assert(std::bidirectional_iterator<std::list<int>::iterator>);     // 通过
static_assert(std::contiguous_iterator<std::map<int,int>::iterator>);     // 编译错：map 只有双向
```

## 16.3 辅助函数：next / prev / distance / advance

迭代器类型名又长又难写（`std::map<std::string, int>::const_reverse_iterator`），**一律 `auto`**。配四个自由函数（`<iterator>`）：

| 函数 | 作用 | 类目要求 |
|---|---|---|
| `std::begin(c)` / `end` | 取容器首/尾后迭代器（数组也吃） | — |
| `std::rbegin(c)` / `rend` | 反向首/尾（16.4） | 双向 |
| `std::next(it, n=1)` | 返回前进 n 格的**副本** | 前向（n 负要双向） |
| `std::prev(it, n=1)` | 返回后退 n 格的副本 | 双向 |
| `std::distance(first, last)` | 两位置间元素个数 | 前向（随机访问是 O(1)，前向是 O(n)！） |
| `std::advance(it, n)` | 原地前进/后退 n 格 | 双向（n 可负） |

`next` 返回副本、`advance` 修改原值——这是两套风格。`distance` 在前向迭代器上是**走着数**的，list 上调它的成本要心里有数。

## 16.4 反向迭代器：rbegin / rend

`rbegin()` 指向**最后一个元素**、`rend()` 指向首元素的前一格——正好是 begin/end 的镜像：

```cpp
for (auto rit = v.rbegin(); rit != v.rend(); ++rit)   // 9 8 7 ... 1
    std::print("{} ", *rit);
```

`++` 在反向迭代器上是"后退"，其余用法照旧。C++20 后更常写 `std::views::reverse`（第 19 章），但手写反向循环仍是读旧代码的必备。

## 16.5 插入迭代器：把"写入"变成"插入"

`std::copy` 的第三个参数是**目标起始迭代器**——目标容器必须先有足够空间，写越界是 UB。插入迭代器把这个约束整个掀掉：它把"往这写一个元素"翻译成"往容器里**插入**一个元素"，空间自动生长：

| 适配器 | 内部调用 | 适用容器 |
|---|---|---|
| `std::back_inserter(c)` | `c.push_back(v)` | vector、deque、list、string |
| `std::front_inserter(c)` | `c.push_front(v)` | deque、list、forward_list |
| `std::inserter(c, pos)` | `c.insert(pos, v)` | 全部（含 map/set） |

```cpp
std::vector<int> src{3, 1, 4, 1, 5};
std::vector<int> dst;                          // 不用预分配！
std::copy(src.begin(), src.end(), std::back_inserter(dst));

std::set<int> uniq;                            // inserter + set = 拷贝即有序去重
std::copy(src.begin(), src.end(), std::inserter(uniq, uniq.end()));
```

`back_inserter` 是三大金刚里出场率最高的——从此 `copy`/`transform` 的目标都不用预先量尺寸。`front_inserter` 注意产出顺序是**倒的**（每个都插到最前面）。

## 16.6 流迭代器：把流当容器用

`istream_iterator<T>` 把输入流变成"元素源"（输入迭代器），`ostream_iterator<T>` 把输出流变成"元素汇"：

```cpp
std::istringstream input{"10 20 30 40"};        // 键盘替身（真实场景是 std::cin）
std::istream_iterator<int> read{input}, eof{};  // eof 是"流末"哨兵
std::vector<int> nums{read, eof};               // 迭代器对 = 区间：直接构造容器！

std::copy(nums.begin(), nums.end(),
          std::ostream_iterator<int>{std::cout, " "});   // 逐个输出，后缀分隔
```

`vector` 用"迭代器对"当区间直接构造——这是 istream_iterator 最漂亮的用法。`ostream_iterator` 的第二参数是**后缀**分隔符：每个元素后面都跟一份，包括最后一个。它俩合体就是"从流解析 → 处理 → 写回流"的流水线骨架（真实输入流的完整讨论在第 32 章）。

## 16.7 move_iterator：把"读"变成"搬"（C++11）

`make_move_iterator(it)` 包装后，解引用返回**右值引用**——区间算法从"拷贝源"变成"搬空源"（移动语义见第 22 章）：

```cpp
std::vector<std::string> words{"alpha", "beta", "gamma"};
auto mb = std::make_move_iterator(words.begin());
auto me = std::make_move_iterator(words.end());
std::vector<std::string> taken{mb, me};         // 字符串被搬走而非拷贝
// 此后 words 里的字符串处于"有效但未指定"状态（通常为空）
```

这是"容器间转移内容"的标准姿势，与 `std::move` 整体搬容器（连内存带壳）互补：**要容器本身用 move，要逐元素搬运配 move_iterator**。

## 16.8 坑位清单

1. **迭代器失效是 UB 不是异常**：vector 扩容（push_back 触发）后**全部旧迭代器作废**；erase 返回下一个有效迭代器，循环里删元素要用它接住（第 14 章）。
2. **类目不够硬喂算法**：`std::sort` 排 list 编译不过（报错长得像天书，关键词 `random_access_iterator`）——list 用成员 `sort()`，关联容器天生有序不用排。
3. **`distance` 在 list 上是 O(n)**：走着数的。循环里反复 distance 前向/双向区间的写法，复杂度是 O(n²) 起步。
4. **越界迭代器解引用**：`*(v.end())`、`begin() + 10` 越界——和指针越界同罪，UB；release 版不报，调试版（MSVC 的 `_ITERATOR_DEBUG_LEVEL`）才可能抓。
5. **range-for 里改容器结构**：插入/删除会让隐式持有的 begin/end 失效——range-for 循环体内只能改**元素值**，不能动容器结构。
6. **ostream_iterator 的分隔符是后缀**：输出是 `1, 2, 3, `（尾巴也带）——要"前缀风格"自己拼或用 format/join 视图（第 19 章）。
