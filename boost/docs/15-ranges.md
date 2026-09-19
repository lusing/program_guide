# 15 · 范围与迭代器：ranges 二十年的长跑

> 对应示例：`examples/15_ranges/`（5 个例程）

这一章是全教程时间跨度最大的一条线：**Boost.Range（2003）→ C++20 `std::ranges`（2020）**，同一作者（Eric Niebler）从写库到写语言标准走了 17 年。中途它还孵化了迭代器设施（Boost.Iterator）和接口骨架（STLInterfaces）两员副将，外加一个至今没进 std 的性能特供（Boost.Sort）。

## 15.1 Boost.Range：`v | filter | transform` 的原型

2003 年它先解决"算法要 begin/end 太啰嗦"，2010 年 range_ex（adaptors）加入管道语法——这两件事 std 到 C++20 才有：

```cpp
boost::range::sort(v);                          // 容器直接传
auto evens = v | ba::filtered(even) | ba::transformed(x10);   // 管道原型
auto first3 = v | ba::sliced(0, 3);
```

运行输出（`range.cpp`）：

```text
排序: 1 1 2 3 4 5 6 9
过滤+变换: 20 40 60
前 3 个: 1 1 2
std 降序: 9 6 5
```

**毕业档案**：`std::ranges` + `std::views`（C++20，**直系**——作者亲自操刀标准化）。boost 版残留价值：C++17 及以下项目要管道语法时用它（`std::views` 的前身体验），但注意 boost 适配器是**立即求值的视图对象**，std views 是惰性的——混用直觉会翻车。**2026 新代码用 std。**

## 15.2 Boost.Iterator：迭代器适配军火库（2001）

```cpp
boost::make_transform_iterator(v.begin(), square);      // 变换
boost::make_filter_iterator(is_odd, v.begin(), v.end());// 过滤
boost::counting_iterator<int>(1);                        // 计数（无存储）
```

运行输出（`iterator.cpp`）：

```text
1 4 9 16 25
1 3 5
1..10 求和 = 55
尾元素 = 5
```

**毕业档案**：大部分场景被 C++20 `views::transform`/`iota`/`filter` 覆盖；`counting_iterator` → `std::views::iota`，`reverse_iterator` 早就是 std 的。boost 版残留：**zip_iterator**（多序列并行走，std 的 `views::zip` 是 C++23）、**permutation_iterator**、给老代码库用的 `iterator_facade`。

## 15.3 Boost.STLInterfaces：迭代器的"填空题模板"（2019）

写一个合规迭代器要实现十几个操作（`+`、`-`、`[]`、全套比较）——STLInterfaces 让你只写 4 个核心操作，其余全部由基类推导：

```cpp
struct ptr_iter : stli::iterator_interface<
#if !BOOST_STL_INTERFACES_USE_DEDUCED_THIS
                      ptr_iter,               // C++20 deduced-this 可用时连这行都省
#endif
                      std::random_access_iterator_tag, int> {
    int& operator*() const;
    ptr_iter& operator+=(std::ptrdiff_t);
    friend std::ptrdiff_t operator-(ptr_iter, ptr_iter);
};
// it[2]、it+3、it1-it2、全套比较——基类送的
```

运行输出（`stl_interfaces.cpp`）：

```text
*it = 10 it[2] = 30 *(it+3) = 40
++it 后 = 20 到末尾距离 = 3
满足 std::random_access_iterator 概念
view: empty=0 front=10
view 求和 = 10
```

例程里 `static_assert(std::random_access_iterator<ptr_iter>)` 实证了补全后的迭代器真正满足 C++20 概念。**std 无对应**——⭐ 自定义容器/视图的作者工具，`view_interface` 同款用法给视图补 `size/empty/front`。

## 15.4 Boost.ConceptCheck：concepts 的库级先驱（2000）

```cpp
BOOST_CONCEPT_ASSERT((boost::InputIterator<Iter>));   // 2000 年的"约束声明"
template <typename Iter> requires std::input_iterator<Iter>   // 2020 年的语言级
```

运行输出（`concept_check.cpp`）：

```text
vector 求和 = 15
list 求和 = 4
C++20 requires: 15
```

它做到的是"错误信息里出现概念名而不是模板天书"的一半；C++20 concepts 做到了全部（声明点检查、约束参与重载决议）。**已完全毕业**，它的历史意义：为委员会验证了"概念检查对泛型库作者多重要"——concepts 是 C++20 最大的语言特性之一，起点在这个 2000 年的库。

## 15.5 Boost.Sort：std::sort 之外的性能特供（2014）

```cpp
boost::sort::spreadsort::integer_sort(keys.begin(), keys.end());   // 整键 O(n·k/log n)
boost::sort::spreadsort::float_sort(fs.begin(), fs.end());         // 浮点位模式基数排
boost::sort::spreadsort::string_sort(words.begin(), words.end());
boost::sort::pdqsort(ints.begin(), ints.end());                     // 现代快排
// 结构体按键：给"位移钩子" + 兜底 operator<
```

运行输出（`sort.cpp`）：

```text
integer_sort: 3 7 42 128 1990 999999
float_sort: 0.5 1.25 2.75 3.5
string_sort: apple banana fig pear
按 key: 10a 20b 30c 50e
pdqsort: 1 3 5 7 9
```

**std 无对应**（`std::sort` 的 `O(n log n)` 是上限承诺，没有基数家族）。⭐ **大数组整键/浮点排序的实测快路**：千万级 uint32 排序 spreadsort 常态快 std::sort 2-5 倍。`block_indirect_sort` 还有并行版（配 TBB/线程池）。

> 实测坑：结构体走 `integer_sort` 除了位移钩子还要给类型兜底 `operator<`（基排在小区间内退回比较排序）。

---

下一章：[16 · 协程时代](16-coroutines.md)——context/coroutine/coroutine2/cobalt/fiber。
